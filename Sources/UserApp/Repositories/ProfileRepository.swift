import Foundation

public actor ProfileRepository {
    private let client: NetworkClient

    public init(client: NetworkClient = .shared) {
        self.client = client
    }

    public func fetchProfile() async throws -> Customer {
        return try await client.request(Endpoint.profile)
    }

    public func updateProfile(
        name: String? = nil,
        username: String? = nil,
        phone: String? = nil,
        company: String? = nil,
        address: String? = nil,
        postalCode: String? = nil,
        city: String? = nil,
        country: String? = nil,
        vatId: String? = nil
    ) async throws {
        let endpoint = Endpoint.updateProfile(
            name: name,
            username: username,
            phone: phone,
            company: company,
            address: address,
            postalCode: postalCode,
            city: city,
            country: country,
            vatId: vatId
        )
        try await client.requestVoid(endpoint)
    }

    public func verifyVat(vatId: String) async throws -> (valid: Bool, message: String, companyName: String?) {
        let resp: VatVerificationResponse = try await client.request(Endpoint.verifyVat(vatId: vatId))
        let valid = resp.valid ?? false
        let msg = resp.message ?? (valid ? "VAT ID verified successfully via EU VIES." : "VAT ID invalid.")
        return (valid, msg, resp.company_name)
    }

    public func setupMfa() async throws -> MfaSetupResponse {
        return try await client.request(Endpoint.setupMfa)
    }

    public func enableMfa(code: String) async throws -> String {
        let resp: APIActionResponse = try await client.request(Endpoint.enableMfa(code: code))
        return resp.message ?? "Two-factor authentication successfully enabled."
    }

    public func disableMfa(code: String? = nil, password: String? = nil) async throws -> String {
        let resp: APIActionResponse = try await client.request(Endpoint.disableMfa(code: code, password: password))
        return resp.message ?? "Two-factor authentication disabled."
    }

    public func fetchBillingEmails() async throws -> [CustomerBillingEmail] {
        do {
            return try await client.request(Endpoint.billingEmails)
        } catch {
            return []
        }
    }

    public func addBillingEmail(email: String) async throws -> CustomerBillingEmail {
        return try await client.request(Endpoint.addBillingEmail(email: email))
    }

    public func deleteBillingEmail(id: UUID) async throws {
        try await client.requestVoid(Endpoint.deleteBillingEmail(id: id))
    }

    public func resendBillingEmail(id: UUID) async throws -> String {
        let resp: APIActionResponse = try await client.request(Endpoint.resendBillingEmail(id: id))
        return resp.message ?? "Verification email resent."
    }

    public func deleteAccount() async throws {
        try await client.requestVoid(Endpoint.deleteAccount)
    }
}
