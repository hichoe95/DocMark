import SwiftUI
import AppKit

// MARK: - App Delegate (ensures proper activation when launched from CLI)

final class DocMarkAppDelegate: NSObject, NSApplicationDelegate {
    private var hasPositionedWindow = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.positionWindowOnVisibleScreen()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func positionWindowOnVisibleScreen() {
        guard !hasPositionedWindow else { return }
        hasPositionedWindow = true

        guard let window = NSApp.windows.first(where: { $0.canBecomeKey }) else { return }

        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct DocMarkApp: App {
    @NSApplicationDelegateAdaptor(DocMarkAppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState()
    @State private var showOnboarding = OnboardingView.shouldShow()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    if CommandLine.arguments.count > 1 {
                        let raw = CommandLine.arguments[1]
                        let expanded = NSString(string: raw).expandingTildeInPath
                        let url = URL(fileURLWithPath: expanded)
                        if FileManager.default.fileExists(atPath: url.path) {
                            appState.openProject(at: url)
                        }
                    } else if !showOnboarding {
                        appState.restoreLastProject()
                    }
                }
                .sheet(isPresented: $showOnboarding) {
                    OnboardingView(onOpenFolder: {
                        showOnboarding = false
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        panel.allowsMultipleSelection = false
                        panel.message = "Select a project folder containing markdown files"
                        if panel.runModal() == .OK, let url = panel.url {
                            appState.openProject(at: url)
                        }
                    })
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            SidebarCommands()
            DocMarkCommands(appState: appState)
            ToolsCommands(appState: appState)
        }
    }
}

struct ToolsCommands: Commands {
    @ObservedObject var appState: AppState

    var body: some Commands {
        CommandMenu("Tools") {
            Button("Install Skill to Project") {
                installSkillToProject()
            }
            .keyboardShortcut("i", modifiers: .command)
            .disabled(appState.selectedProject == nil)

            Divider()

            Menu("Install Skill Globally") {
                Button("Claude Code") {
                    installGlobalClaudeCodeSkill()
                }
                Button("OpenCode") {
                    installGlobalOpenCodeSkill()
                }
            }
        }
    }

    // MARK: - Project-Level Install

    private func installSkillToProject() {
        guard let project = appState.selectedProject else { return }

        let destFile = URL(fileURLWithPath: project.path)
            .appendingPathComponent(".claude/skills/docmark/SKILL.md")

        if appState.isSkillInstalledInProject {
            showAlert(title: "Already Installed", message: "Skill is already installed at:\n\(destFile.path)")
            return
        }

        appState.installSkillToProject()

        if appState.isSkillInstalledInProject {
            showAlert(
                title: "Skill Installed",
                message: "Installed to:\n\(destFile.path)\n\nBoth Claude Code and OpenCode will automatically use this skill in this project."
            )
        } else {
            showAlert(title: "Installation Failed", message: "Could not install skill. Check folder permissions.")
        }
    }

    // MARK: - Global Install

    private func installGlobalClaudeCodeSkill() {
        let destDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/skills/docmark")
        let destFile = destDir.appendingPathComponent("SKILL.md")

        if FileManager.default.fileExists(atPath: destFile.path) {
            showAlert(title: "Already Installed", message: "Claude Code skill is already installed at:\n\(destFile.path)")
            return
        }

        do {
            try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
            try AppState.loadSkillContent(forResource: "SKILL", withExtension: "md", fallback: SkillContent.claudeCode)
                .write(to: destFile, atomically: true, encoding: .utf8)

            showAlert(
                title: "Claude Code Skill Installed",
                message: "Installed to:\n\(destFile.path)\n\nClaude Code will automatically use this skill in all projects."
            )
        } catch {
            showAlert(title: "Installation Failed", message: "Could not install skill: \(error.localizedDescription)")
        }
    }

    private func installGlobalOpenCodeSkill() {
        let destDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".opencode/skills/docmark")
        let destFile = destDir.appendingPathComponent("skill.yaml")

        if FileManager.default.fileExists(atPath: destFile.path) {
            showAlert(title: "Already Installed", message: "OpenCode skill is already installed at:\n\(destFile.path)")
            return
        }

        do {
            try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
            try AppState.loadSkillContent(forResource: "skill", withExtension: "yaml", fallback: SkillContent.openCode)
                .write(to: destFile, atomically: true, encoding: .utf8)

            showAlert(
                title: "OpenCode Skill Installed",
                message: "Installed to:\n\(destFile.path)\n\nOpenCode will activate this skill when it detects .docsconfig.yaml."
            )
        } catch {
            showAlert(title: "Installation Failed", message: "Could not install skill: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

enum SkillContent {
    static let claudeCode = """
    ---
    name: docmark
    description: Follow DocMark documentation standards when creating or editing project documentation. Activates when the user asks to document, update docs, add changelog entries, create any documentation, set up documentation standards, or when .docsconfig.yaml is present.
    ---

    # DocMark Documentation Standard

    This skill provides base rules for consistent project documentation. It is designed to be customized per-project — the agent interviews the user about their project and updates this skill with the right document types, templates, and conventions.

    ## Base Rules

    1. Check for `.docsconfig.yaml` in the project root first — it overrides defaults
    2. Core documents: README.md, CHANGELOG.md (Keep a Changelog format), CONTRIBUTING.md (if needed)
    3. All docs use YAML frontmatter with at least `title` and `date`
    4. Use kebab-case filenames, never modify released changelog versions

    ## Customizing This Skill

    When the user asks to set up docs or requests a document type not covered above, interview them about their project (type, team size, needed doc types) and update this SKILL.md with project-specific document types, templates, and conventions. Reference templates are in the project's `templates/` directory.
    """

    static let openCode = """
    name: docmark
    description: "Helps OpenCode follow DocMark documentation standards"
    version: "1.0.0"

    activation:
      files:
        - ".docsconfig.yaml"
        - "README.md"
      keywords:
        - "document"
        - "docs"
        - "changelog"
        - "adr"

    instructions: |
      You are working with a project that uses DocMark documentation standards.
      1. Always check for `.docsconfig.yaml` in the project root
      2. Follow the configured directory structure for different document types
      3. Use appropriate frontmatter for each document type
      4. Place files in the correct locations based on the configuration
    """
}

struct DocMarkCommands: Commands {
    @ObservedObject var appState: AppState

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open Folder...") {
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                panel.allowsMultipleSelection = false
                panel.message = "Select a project folder containing markdown files"
                if panel.runModal() == .OK, let url = panel.url {
                    appState.openProject(at: url)
                }
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        CommandMenu("Navigate") {
            Button("Previous Document") {
                appState.goToPreviousDocument()
            }
            .keyboardShortcut("[", modifiers: .command)
            .disabled(!appState.canGoToPrevious)

            Button("Next Document") {
                appState.goToNextDocument()
            }
            .keyboardShortcut("]", modifiers: .command)
            .disabled(!appState.canGoToNext)

            Divider()

            Button("Quick Open") {
                appState.toggleQuickOpen()
            }
            .keyboardShortcut("p", modifiers: .command)

            Button("Search") {
                appState.toggleSearch()
            }
            .keyboardShortcut("k", modifiers: .command)

            Divider()

            Button("Table of Contents") {
                appState.toggleTOC()
            }
            .keyboardShortcut("t", modifiers: .command)

            Button("Git Changes") {
                appState.toggleGitChanges()
            }
            .keyboardShortcut("g", modifiers: .command)

            Divider()

            Button("Project Library") {
                appState.showProjectLibrary()
            }
            .keyboardShortcut("l", modifiers: [.command, .shift])
        }
    }
}
