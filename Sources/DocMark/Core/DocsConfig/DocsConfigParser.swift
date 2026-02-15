import Foundation
import Yams

struct DocsConfigParser {
    static func parse(at projectURL: URL) -> DocsConfig? {
        let decoder = YAMLDecoder()
        let configFiles = [".docsconfig.yaml", ".docsconfig.yml"]

        for file in configFiles {
            let configURL = projectURL.appendingPathComponent(file)
            guard let raw = readFileIfAvailable(at: configURL) else {
                continue
            }

            if let config = try? decoder.decode(DocsConfig.self, from: raw) {
                return config
            }
        }

        return nil
    }

    static func validate(_ config: DocsConfig, projectURL: URL) -> [String] {
        let fileManager = FileManager.default
        var errors: [String] = []

        let rootURL = resolvePath(config.documentation.root, base: projectURL)

        var isDirectory = ObjCBool(false)
        if !fileManager.fileExists(atPath: rootURL.path, isDirectory: &isDirectory) {
            errors.append("Documentation root path does not exist: \(config.documentation.root)")
            return errors
        }

        if !isDirectory.boolValue {
            errors.append("Documentation root path is not a directory: \(rootURL.path)")
            return errors
        }

        for rootFile in config.documentation.rootFiles {
            guard validateSectionLikePath(rootFile.path) else {
                if rootFile.required {
                    errors.append("Root file path contains unsupported segment: \(rootFile.path)")
                }
                continue
            }

            if rootFile.path.isEmpty {
                if rootFile.required {
                    errors.append("Required root file has an empty path.")
                }
                continue
            }

            let absoluteURL = rootURL.appendingPathComponent(rootFile.path)
            var isFile = ObjCBool(false)
            if !fileManager.fileExists(atPath: absoluteURL.path, isDirectory: &isFile) {
                if rootFile.required {
                    errors.append("Required root file not found: \(absoluteURL.path)")
                }
                continue
            }

            if isFile.boolValue {
                continue
            }

            errors.append("Root file path is not a file: \(absoluteURL.path)")
        }

        for section in config.documentation.sections {
            guard let path = section.path else {
                if let sectionId = section.id {
                    errors.append("Section '\(sectionId)' is missing path.")
                } else {
                    errors.append("Section is missing path.")
                }
                continue
            }

            guard validateSectionLikePath(path) else {
                errors.append("Invalid section path: \(path)")
                continue
            }

            if path.isEmpty {
                if let sectionId = section.id {
                    errors.append("Section '\(sectionId)' has an empty path.")
                } else {
                    errors.append("Section has an empty path.")
                }
                continue
            }

            let absoluteURL = rootURL.appendingPathComponent(path)
            var sectionIsDir = ObjCBool(false)
            if !fileManager.fileExists(atPath: absoluteURL.path, isDirectory: &sectionIsDir) {
                if let sectionId = section.id {
                    errors.append("Section path does not exist for '\(sectionId)': \(absoluteURL.path)")
                } else {
                    errors.append("Section path does not exist: \(absoluteURL.path)")
                }
                continue
            }

            if !sectionIsDir.boolValue {
                if let sectionId = section.id {
                    errors.append("Section path is not a directory for '\(sectionId)': \(absoluteURL.path)")
                } else {
                    errors.append("Section path is not a directory: \(absoluteURL.path)")
                }
            }

            if let frontmatterSchema = section.frontmatterSchema {
                if !frontmatterSchema.isEmpty,
                   config.frontmatterSchemas[frontmatterSchema] == nil {
                    if let sectionId = section.id {
                        errors.append("Section '\(sectionId)' uses undefined frontmatter schema '\(frontmatterSchema)'.")
                    } else {
                        errors.append("Section uses undefined frontmatter schema '\(frontmatterSchema)'.")
                    }
                }
            }
        }

        return errors
    }

    private static func readFileIfAvailable(at fileURL: URL) -> String? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        return try? String(contentsOf: fileURL, encoding: .utf8)
    }

    private static func resolvePath(_ relative: String, base: URL) -> URL {
        guard !relative.isEmpty else {
            return base
        }

        if relative.hasPrefix("/") {
            return URL(fileURLWithPath: relative)
        }

        return base.appendingPathComponent(relative)
    }

    private static func validateSectionLikePath(_ value: String) -> Bool {
        let path = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if path.contains("..") {
            return false
        }
        if path.hasPrefix("~") {
            return false
        }
        if path.hasPrefix("/") {
            return false
        }
        return true
    }
}
