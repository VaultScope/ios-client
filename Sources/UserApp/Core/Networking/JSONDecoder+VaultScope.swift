import Foundation

public struct VaultDateFormatter: @unchecked Sendable {
    public static let shared = VaultDateFormatter()

    private let isoFractional: ISO8601DateFormatter
    private let isoStandard: ISO8601DateFormatter
    private let posixFormatter: DateFormatter
    private let dateOnlyFormatter: DateFormatter

    public init() {
        let frac = ISO8601DateFormatter()
        frac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.isoFractional = frac

        let std = ISO8601DateFormatter()
        std.formatOptions = [.withInternetDateTime]
        self.isoStandard = std

        let posix = DateFormatter()
        posix.locale = Locale(identifier: "en_US_POSIX")
        posix.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"
        self.posixFormatter = posix

        let dateOnly = DateFormatter()
        dateOnly.locale = Locale(identifier: "en_US_POSIX")
        dateOnly.dateFormat = "yyyy-MM-dd"
        self.dateOnlyFormatter = dateOnly
    }

    public func date(from string: String) -> Date? {
        if let d = isoFractional.date(from: string) { return d }
        if let d = isoStandard.date(from: string) { return d }
        if let d = posixFormatter.date(from: string) { return d }
        if let d = dateOnlyFormatter.date(from: string) { return d }
        return nil
    }

    public func string(from date: Date) -> String {
        return isoStandard.string(from: date)
    }
}

extension JSONDecoder {
    public static var vaultScope: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            if let date = VaultDateFormatter.shared.date(from: str) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string \(str)"
            )
        }
        return decoder
    }
}

extension JSONEncoder {
    public static var vaultScope: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
