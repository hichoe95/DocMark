import Foundation

struct DocsConfig: Codable {
    let version: String?
    let project: DocsProjectConfig
    let documentation: DocsDocumentation
    let frontmatterSchemas: [String: DocsFrontmatterSchema]
    let templates: [String: DocsTemplate]
    let aiIntegration: [String: [String: DocsConfigValue]]

    init(
        version: String? = nil,
        project: DocsProjectConfig = .init(),
        documentation: DocsDocumentation = .init(),
        frontmatterSchemas: [String: DocsFrontmatterSchema] = [:],
        templates: [String: DocsTemplate] = [:],
        aiIntegration: [String: [String: DocsConfigValue]] = [:]
    ) {
        self.version = version
        self.project = project
        self.documentation = documentation
        self.frontmatterSchemas = frontmatterSchemas
        self.templates = templates
        self.aiIntegration = aiIntegration
    }

    enum CodingKeys: String, CodingKey {
        case version
        case project
        case documentation
        case frontmatterSchemas = "frontmatter_schemas"
        case templates
        case aiIntegration = "ai_integration"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIfPresent(String.self, forKey: .version)
        project = (try container.decodeIfPresent(DocsProjectConfig.self, forKey: .project)) ?? DocsProjectConfig()
        documentation = (try container.decodeIfPresent(DocsDocumentation.self, forKey: .documentation)) ?? DocsDocumentation()
        frontmatterSchemas = (try container.decodeIfPresent([String: DocsFrontmatterSchema].self, forKey: .frontmatterSchemas)) ?? [:]
        templates = (try container.decodeIfPresent([String: DocsTemplate].self, forKey: .templates)) ?? [:]
        aiIntegration = (try container.decodeIfPresent([String: [String: DocsConfigValue]].self, forKey: .aiIntegration)) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encode(project, forKey: .project)
        try container.encode(documentation, forKey: .documentation)
        try container.encode(frontmatterSchemas, forKey: .frontmatterSchemas)
        try container.encode(templates, forKey: .templates)
        try container.encode(aiIntegration, forKey: .aiIntegration)
    }
}

struct DocsProjectConfig: Codable {
    let name: String?
    let description: String?
    let version: String?
    let repository: String?

    init(name: String? = nil, description: String? = nil, version: String? = nil, repository: String? = nil) {
        self.name = name
        self.description = description
        self.version = version
        self.repository = repository
    }
}

struct DocsDocumentation: Codable {
    let root: String
    let rootFiles: [DocsRootFile]
    let sections: [DocsSection]

    init(root: String = ".", rootFiles: [DocsRootFile] = [], sections: [DocsSection] = []) {
        self.root = root
        self.rootFiles = rootFiles
        self.sections = sections
    }

    enum CodingKeys: String, CodingKey {
        case root
        case rootFiles = "root_files"
        case sections
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        root = try container.decodeIfPresent(String.self, forKey: .root) ?? "."
        rootFiles = (try container.decodeIfPresent([DocsRootFile].self, forKey: .rootFiles)) ?? []
        sections = (try container.decodeIfPresent([DocsSection].self, forKey: .sections)) ?? []
    }
}

struct DocsRootFile: Codable {
    let path: String
    let title: String
    let required: Bool

    init(path: String = "", title: String = "", required: Bool = false) {
        self.path = path
        self.title = title
        self.required = required
    }

    enum CodingKeys: String, CodingKey {
        case path
        case title
        case required
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        path = try container.decodeIfPresent(String.self, forKey: .path) ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        required = (try container.decodeIfPresent(Bool.self, forKey: .required)) ?? false
    }
}

struct DocsSection: Codable {
    let id: String?
    let title: String?
    let path: String?
    let pattern: String?
    let frontmatterSchema: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case path
        case pattern
        case frontmatterSchema = "frontmatter_schema"
    }
}

struct DocsFrontmatterSchema: Codable {
    let required: [String]
    let optional: [String]
    let enumValues: [String: [String]]

    init(required: [String] = [], optional: [String] = [], enumValues: [String: [String]] = [:]) {
        self.required = required
        self.optional = optional
        self.enumValues = enumValues
    }

    func allEnumValues() -> [String: [String]] {
        enumValues
    }

    private enum CodingKeys: String, CodingKey {
        case required
        case optional
    }

    init(from decoder: Decoder) throws {
        let knownContainer = try decoder.container(keyedBy: CodingKeys.self)
        required = (try knownContainer.decodeIfPresent([String].self, forKey: .required)) ?? []
        optional = (try knownContainer.decodeIfPresent([String].self, forKey: .optional)) ?? []

        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        var values: [String: [String]] = [:]
        for key in container.allKeys {
            guard key.stringValue != "required", key.stringValue != "optional" else {
                continue
            }
            if key.stringValue.hasSuffix("_values") {
                let list = try container.decodeIfPresent([String].self, forKey: key)
                values[key.stringValue] = list ?? []
            }
        }
        enumValues = values
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        try container.encode(required, forKey: DynamicCodingKeys(stringValue: "required")!)
        try container.encode(optional, forKey: DynamicCodingKeys(stringValue: "optional")!)
        for (key, value) in enumValues {
            try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
        }
    }

    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?

        init?(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }

        init?(intValue: Int) {
            return nil
        }
    }
}

struct DocsTemplate: Codable {
    let path: String
    let description: String

    init(path: String = "", description: String = "") {
        self.path = path
        self.description = description
    }
}

indirect enum DocsConfigValue: Codable, Equatable {
    case string(String)
    case bool(Bool)
    case integer(Int)
    case double(Double)
    case array([DocsConfigValue])
    case object([String: DocsConfigValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
            return
        }

        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
            return
        }

        if let intValue = try? container.decode(Int.self) {
            self = .integer(intValue)
            return
        }

        if let doubleValue = try? container.decode(Double.self) {
            self = .double(doubleValue)
            return
        }

        if let arrayValue = try? container.decode([DocsConfigValue].self) {
            self = .array(arrayValue)
            return
        }

        if let objectValue = try? container.decode([String: DocsConfigValue].self) {
            self = .object(objectValue)
            return
        }

        if container.decodeNil() {
            self = .null
            return
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported DocsConfigValue type")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .integer(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}
