import Foundation

public struct OsImage: Identifiable, Codable, Sendable, Hashable {
    public var id: String
    public var name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct SshKeyOption: Identifiable, Codable, Sendable, Hashable {
    public var id: String
    public var name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct StorefrontOptions: Codable, Sendable {
    public var osImages: [OsImage]
    public var sshKeys: [SshKeyOption]

    enum CodingKeys: String, CodingKey {
        case osImages = "os_images"
        case osImagesCamel = "osImages"
        case sshKeys = "ssh_keys"
        case sshKeysCamel = "sshKeys"
    }

    public init(osImages: [OsImage] = [], sshKeys: [SshKeyOption] = []) {
        self.osImages = osImages
        self.sshKeys = sshKeys
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let list = try? container.decode([OsImage].self, forKey: .osImages) {
            self.osImages = list
        } else if let list = try? container.decode([OsImage].self, forKey: .osImagesCamel) {
            self.osImages = list
        } else {
            self.osImages = []
        }

        if let keys = try? container.decode([SshKeyOption].self, forKey: .sshKeys) {
            self.sshKeys = keys
        } else if let keys = try? container.decode([SshKeyOption].self, forKey: .sshKeysCamel) {
            self.sshKeys = keys
        } else {
            self.sshKeys = []
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(osImages, forKey: .osImages)
        try container.encode(sshKeys, forKey: .sshKeys)
    }
}
