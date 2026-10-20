import Foundation

public enum Endpoint: Sendable {
    // Health & CSRF
    case health
    case csrf

    // Authentication
    case login(email: String, password: String, totpCode: String?)
    case register(username: String, name: String, email: String, password: String, company: String?, address: String, postalCode: String?, city: String, country: String, phone: String?, vatId: String?)
    case verifyEmail(token: String)
    case resendVerification(email: String)

    // Infrastructure / Services
    case services
    case serviceDetail(id: UUID)
    case startService(id: UUID)
    case stopService(id: UUID)
    case restartService(id: UUID)
    case reinstallService(id: UUID, os: String)
    case cancelService(id: UUID, mode: String, reason: String?, feedback: String?)
    case uncancelService(id: UUID)
    case console(id: UUID)
    case ipmi(id: UUID, clientIp: String?)
    case deleteService(id: UUID)

    // Orders & Catalog
    case catalog
    case options
    case placeOrder(productId: UUID, hostname: String?, partnerSlug: String?)
    case createPaymentIntent(productId: UUID)

    // Billing & Invoices
    case invoices
    case invoicePdf(id: UUID)
    case payInvoice(id: UUID)
    case billing

    // Profile & Account
    case profile
    case updateProfile(name: String?, username: String?, phone: String?, company: String?, address: String?, postalCode: String?, city: String?, country: String?, vatId: String?)
    case deleteAccount
    case verifyVat(vatId: String)
    case setupMfa
    case enableMfa(code: String)
    case disableMfa(code: String?, password: String?)
    case billingEmails
    case addBillingEmail(email: String)
    case deleteBillingEmail(id: UUID)
    case resendBillingEmail(id: UUID)

    // Support
    case tickets
    case ticketDetail(id: UUID)
    case createTicket(subject: String, content: String, category: String, priority: String, relatedServiceId: UUID?)
    case replyTicket(id: UUID, content: String)

    // Activity
    case activity

    public var path: String {
        switch self {
        case .health:
            return "/api/health"
        case .csrf:
            return "/api/csrf"
        case .login:
            return "/api/auth/login"
        case .register:
            return "/api/auth/register"
        case .verifyEmail:
            return "/api/auth/verify-email"
        case .resendVerification:
            return "/api/auth/resend-verification"

        case .services:
            return "/api/storefront/services"
        case .serviceDetail(let id):
            return "/api/storefront/services/\(id.uuidString.lowercased())"
        case .startService(let id):
            return "/api/storefront/services/\(id.uuidString.lowercased())/start"
        case .stopService(let id):
            return "/api/storefront/services/\(id.uuidString.lowercased())/stop"
        case .restartService(let id):
            return "/api/storefront/services/\(id.uuidString.lowercased())/restart"
        case .reinstallService(let id, _):
            return "/api/storefront/services/\(id.uuidString.lowercased())/reinstall"
        case .cancelService(let id, _, _, _):
            return "/api/storefront/services/\(id.uuidString.lowercased())/cancel"
        case .uncancelService(let id):
            return "/api/storefront/services/\(id.uuidString.lowercased())/uncancel"
        case .console(let id):
            return "/api/storefront/services/\(id.uuidString.lowercased())/console"
        case .ipmi(let id, _):
            return "/api/storefront/services/\(id.uuidString.lowercased())/ipmi"
        case .deleteService(let id):
            return "/api/storefront/services/\(id.uuidString.lowercased())"

        case .catalog:
            return "/api/storefront/catalog"
        case .options:
            return "/api/storefront/options"
        case .placeOrder:
            return "/api/storefront/orders"
        case .createPaymentIntent:
            return "/api/storefront/orders/create-payment-intent"

        case .invoices:
            return "/api/storefront/invoices"
        case .invoicePdf(let id):
            return "/api/storefront/invoices/\(id.uuidString.lowercased())/pdf"
        case .payInvoice(let id):
            return "/api/storefront/invoices/\(id.uuidString.lowercased())/pay"
        case .billing:
            return "/api/storefront/billing"

        case .profile:
            return "/api/storefront/profile"
        case .updateProfile:
            return "/api/storefront/profile"
        case .deleteAccount:
            return "/api/storefront/profile"
        case .verifyVat:
            return "/api/storefront/profile/verify-vat"
        case .setupMfa:
            return "/api/storefront/profile/mfa/setup"
        case .enableMfa:
            return "/api/storefront/profile/mfa/enable"
        case .disableMfa:
            return "/api/storefront/profile/mfa/disable"
        case .billingEmails:
            return "/api/storefront/profile/billing-emails"
        case .addBillingEmail:
            return "/api/storefront/profile/billing-emails"
        case .deleteBillingEmail(let id):
            return "/api/storefront/profile/billing-emails/\(id.uuidString.lowercased())"
        case .resendBillingEmail(let id):
            return "/api/storefront/profile/billing-emails/\(id.uuidString.lowercased())/resend"

        case .tickets:
            return "/api/storefront/tickets"
        case .ticketDetail(let id):
            return "/api/storefront/tickets/\(id.uuidString.lowercased())"
        case .createTicket:
            return "/api/storefront/tickets"
        case .replyTicket(let id, _):
            return "/api/storefront/tickets/\(id.uuidString.lowercased())/messages"

        case .activity:
            return "/api/storefront/activity"
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .health, .csrf, .services, .serviceDetail, .catalog, .options,
             .invoices, .invoicePdf, .billing, .profile, .billingEmails,
             .tickets, .ticketDetail, .activity:
            return .get

        case .login, .register, .verifyEmail, .resendVerification,
             .startService, .stopService, .restartService, .reinstallService,
             .cancelService, .uncancelService, .console, .ipmi,
             .placeOrder, .createPaymentIntent, .payInvoice,
             .verifyVat, .setupMfa, .enableMfa, .disableMfa,
             .addBillingEmail, .resendBillingEmail,
             .createTicket, .replyTicket:
            return .post

        case .updateProfile:
            return .put

        case .deleteService, .deleteAccount, .deleteBillingEmail:
            return .delete
        }
    }

    public var isMutating: Bool {
        switch method {
        case .post, .put, .delete, .patch:
            return true
        case .get:
            return false
        }
    }

    public var bodyData: Data? {
        switch self {
        case .login(let email, let password, let totpCode):
            var dict: [String: Any] = [
                "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
                "password": password,
                "audience": "storefront"
            ]
            if let code = totpCode, !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                dict["totp_code"] = code.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return try? JSONSerialization.data(withJSONObject: dict)

        case .register(let username, let name, let email, let password, let company, let address, let postalCode, let city, let country, let phone, let vatId):
            var dict: [String: Any] = [
                "username": username.trimmingCharacters(in: .whitespacesAndNewlines),
                "name": name.trimmingCharacters(in: .whitespacesAndNewlines),
                "email": email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
                "password": password,
                "address": address.trimmingCharacters(in: .whitespacesAndNewlines),
                "city": city.trimmingCharacters(in: .whitespacesAndNewlines),
                "country": country.trimmingCharacters(in: .whitespacesAndNewlines)
            ]
            if let c = company, !c.isEmpty { dict["company"] = c }
            if let p = postalCode, !p.isEmpty { dict["postal_code"] = p }
            if let ph = phone, !ph.isEmpty { dict["phone"] = ph }
            if let v = vatId, !v.isEmpty { dict["vat_id"] = v }
            return try? JSONSerialization.data(withJSONObject: dict)

        case .verifyEmail(let token):
            return try? JSONSerialization.data(withJSONObject: ["token": token])

        case .resendVerification(let email):
            return try? JSONSerialization.data(withJSONObject: ["email": email])

        case .reinstallService(_, let os):
            return try? JSONSerialization.data(withJSONObject: ["os": os])

        case .cancelService(_, let mode, let reason, let feedback):
            var dict: [String: Any] = ["mode": mode]
            if let r = reason, !r.isEmpty { dict["reason"] = r }
            if let f = feedback, !f.isEmpty { dict["feedback"] = f }
            return try? JSONSerialization.data(withJSONObject: dict)

        case .ipmi(_, let clientIp):
            var dict: [String: Any] = [:]
            if let ip = clientIp { dict["client_ip"] = ip }
            return try? JSONSerialization.data(withJSONObject: dict)

        case .placeOrder(let productId, let hostname, let partnerSlug):
            var dict: [String: Any] = ["product_id": productId.uuidString.lowercased()]
            if let h = hostname, !h.isEmpty { dict["hostname"] = h }
            if let slug = partnerSlug, !slug.isEmpty { dict["partner_slug"] = slug }
            return try? JSONSerialization.data(withJSONObject: dict)

        case .createPaymentIntent(let productId):
            return try? JSONSerialization.data(withJSONObject: ["product_id": productId.uuidString.lowercased()])

        case .updateProfile(let name, let username, let phone, let company, let address, let postalCode, let city, let country, let vatId):
            var dict: [String: Any] = [:]
            if let n = name { dict["name"] = n }
            if let u = username { dict["username"] = u }
            if let p = phone { dict["phone"] = p }
            if let c = company { dict["company"] = c }
            if let a = address { dict["address"] = a }
            if let pc = postalCode { dict["postal_code"] = pc }
            if let ct = city { dict["city"] = ct }
            if let co = country { dict["country"] = co }
            if let v = vatId { dict["vat_id"] = v }
            return try? JSONSerialization.data(withJSONObject: dict)

        case .verifyVat(let vatId):
            return try? JSONSerialization.data(withJSONObject: ["vat_id": vatId])

        case .enableMfa(let code):
            return try? JSONSerialization.data(withJSONObject: ["code": code.trimmingCharacters(in: .whitespacesAndNewlines)])

        case .disableMfa(let code, let password):
            var dict: [String: Any] = [:]
            if let c = code, !c.isEmpty { dict["code"] = c }
            if let p = password, !p.isEmpty { dict["password"] = p }
            return try? JSONSerialization.data(withJSONObject: dict)

        case .addBillingEmail(let email):
            return try? JSONSerialization.data(withJSONObject: ["email": email.trimmingCharacters(in: .whitespacesAndNewlines)])

        case .createTicket(let subject, let content, let category, let priority, let relatedServiceId):
            var dict: [String: Any] = [
                "subject": subject,
                "content": content,
                "category": category,
                "priority": priority
            ]
            if let sid = relatedServiceId {
                dict["related_service_id"] = sid.uuidString.lowercased()
            }
            return try? JSONSerialization.data(withJSONObject: dict)

        case .replyTicket(_, let content):
            return try? JSONSerialization.data(withJSONObject: ["content": content])

        default:
            return nil
        }
    }
}
