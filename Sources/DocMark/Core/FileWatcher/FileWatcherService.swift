import CoreServices
import Foundation

final class FileWatcherService: ObservableObject {
    @Published var lastChange: FileChange?
    @Published var needsFullRescan: Bool = false

    private var streamRef: FSEventStreamRef?
    private let eventLatency: TimeInterval = 0.5

    private let eventCallback: FSEventStreamCallback = { _, clientInfo, numEvents, eventPaths, eventFlags, _ in
        guard let clientInfo else { return }
        let watcher = Unmanaged<FileWatcherService>.fromOpaque(clientInfo).takeUnretainedValue()

        let paths = unsafeBitCast(eventPaths, to: NSArray.self)

        for index in 0..<numEvents {
            guard let path = paths[index] as? String else { return }

            let flags = eventFlags[index]
            if watcher.shouldTriggerFullRescan(for: flags) {
                DispatchQueue.main.async {
                    watcher.needsFullRescan = true
                }
                continue
            }

            guard watcher.isMarkdownFile(path), let changeType = watcher.changeType(for: flags) else {
                continue
            }

            DispatchQueue.main.async {
                watcher.lastChange = FileChange(path: path, type: changeType, timestamp: Date())
            }
        }
    }

    func startWatching(path: String) {
        stopWatching()

        let rootPath = URL(fileURLWithPath: path).path
        let pathsToWatch = [rootPath] as CFArray
        let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents) |
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes)

        needsFullRescan = false
        lastChange = nil

        var context = FSEventStreamContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            eventCallback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            eventLatency,
            flags
        ) else {
            return
        }

        streamRef = stream
        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)
    }

    func stopWatching() {
        guard let stream = streamRef else {
            return
        }

        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        streamRef = nil
        needsFullRescan = false
        lastChange = nil
    }

    deinit {
        if let stream = streamRef {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }

    private func shouldTriggerFullRescan(for flags: FSEventStreamEventFlags) -> Bool {
        let fullScanFlags = FSEventStreamEventFlags(kFSEventStreamEventFlagMustScanSubDirs |
            kFSEventStreamEventFlagUserDropped |
            kFSEventStreamEventFlagKernelDropped)
        return (flags & fullScanFlags) != 0
    }

    private func isMarkdownFile(_ path: String) -> Bool {
        (path as NSString).pathExtension.lowercased() == "md"
    }

    private func changeType(for flags: FSEventStreamEventFlags) -> FileChangeType? {
        if flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated) != 0 {
            return .created
        }

        if flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified) != 0 {
            return .modified
        }

        if flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved) != 0 {
            return .deleted
        }

        if flags & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed) != 0 {
            return .renamed
        }

        return nil
    }
}
