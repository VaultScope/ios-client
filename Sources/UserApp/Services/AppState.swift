import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    // MARK: - Repositories
    public let authRepo: AuthRepository
    public let servicesRepo: ServicesRepository
    public let billingRepo: BillingRepository
    public let catalogRepo: CatalogRepository
    public let ticketsRepo: TicketsRepository
    public let profileRepo: ProfileRepository
    public let activityRepo: ActivityRepository

    // MARK: - Telemetry Engine
    public let telemetry: TelemetryEngine

    // MARK: - Published Domain State
    @Published public var isAuthenticated: Bool = false
    @Published public var customer: Customer {
        didSet { SessionStorage.shared.saveCustomer(customer) }
    }
    @Published public var services: [ServiceInstance] = [] {
        didSet { telemetry.update(runningServices: services.filter { $0.status == .running }) }
    }
    @Published public var products: [Product] = []
    @Published public var invoices: [Invoice] = []
    @Published public var tickets: [Ticket] = []
    @Published public var activities: [ActivityItem] = []
    @Published public var billingInfo: BillingInfo? = nil
    @Published public var storefrontOptions: StorefrontOptions? = nil
    @Published public var billingEmails: [CustomerBillingEmail] = []

    // MARK: - Telemetry Forwarding
    public var cpuHistory: [Double] { telemetry.cpuHistory }
    public var networkHistory: [Double] { telemetry.networkHistory }
    public var currentNetworkMbps: Double { telemetry.currentNetworkMbps }

    // MARK: - Web Dashboard Metrics & Categorization
    public var activeServices: [ServiceInstance] {
        services.filter { $0.status != .terminated }
    }

    public var isAllOperational: Bool {
        activeServices.isEmpty || activeServices.allSatisfy { $0.status == .running }
    }

    public var monthlyNetSpend: Double {
        activeServices.reduce(0.0) { $0 + $1.price }
    }

    public var monthlyGrossSpend: Double {
        monthlyNetSpend * 1.19
    }

    public var openTicketsCount: Int {
        tickets.filter { $0.status != .closed }.count
    }

    public var waitingCustomerTicketsCount: Int {
        tickets.filter { $0.status == .waitingCustomer }.count
    }

    public var vpsServices: [ServiceInstance] {
        activeServices.filter { !$0.isSftp && ($0.category.lowercased() == "vps" || $0.category.isEmpty) }
    }

    public var dedicatedServices: [ServiceInstance] {
        activeServices.filter {
            let c = $0.category.lowercased()
            return c == "ds" || c == "dedicated"
        }
    }

    public var odpServices: [ServiceInstance] {
        activeServices.filter {
            let c = $0.category.lowercased()
            return c == "odp" || c == "ocd"
        }
    }

    public var sftpServices: [ServiceInstance] {
        activeServices.filter { $0.isSftp }
    }

    // MARK: - API & Session State
    @Published public var savedApiToken: String = ""
    @Published public var apiBaseURL: String = "https://api.vaultscope.de" {
        didSet {
            SessionStorage.shared.saveBaseURL(apiBaseURL)
            if let url = URL(string: apiBaseURL) {
                Task { await NetworkClient.shared.setBaseURL(url) }
            }
        }
    }
    @Published public var isBackendOnline: Bool = false
    @Published public var isRefreshing: Bool = false
    @Published public var successBannerMessage: String? = nil

    // MARK: - Security & Biometrics
    @Published public var isBiometricsEnabled: Bool {
        didSet { BiometricManager.shared.isBiometricsEnabled = isBiometricsEnabled }
    }
    @Published public var isAppLocked: Bool = false
    public var biometryType: BiometryType { BiometricManager.shared.biometryType }

    // MARK: - Network Connectivity
    public var isConnected: Bool { NetworkMonitor.shared.isConnected }
    public var connectionType: ConnectionType { NetworkMonitor.shared.connectionType }

    private var cancellables = Set<AnyCancellable>()

    public init(networkClient: NetworkClient = .shared) {
        self.authRepo = AuthRepository(client: networkClient)
        self.servicesRepo = ServicesRepository(client: networkClient)
        self.billingRepo = BillingRepository(client: networkClient)
        self.catalogRepo = CatalogRepository(client: networkClient)
        self.ticketsRepo = TicketsRepository(client: networkClient)
        self.profileRepo = ProfileRepository(client: networkClient)
        self.activityRepo = ActivityRepository(client: networkClient)

        let engine = TelemetryEngine()
        self.telemetry = engine

        // Restore saved session & security state
        let storage = SessionStorage.shared
        self.customer = storage.loadCustomer() ?? Customer(name: "", email: "")
        self.savedApiToken = storage.loadToken() ?? ""
        self.apiBaseURL = storage.loadBaseURL()
        self.isAuthenticated = storage.isAuthenticated()
        self.isBiometricsEnabled = BiometricManager.shared.isBiometricsEnabled

        // Lock app on cold launch if biometrics is active and session is present
        if self.isBiometricsEnabled && self.isAuthenticated {
            self.isAppLocked = true
        }

        if let url = URL(string: self.apiBaseURL) {
            Task {
                await networkClient.setBaseURL(url)
                if !self.savedApiToken.isEmpty {
                    await networkClient.setToken(self.savedApiToken)
                }
            }
        }

        // Subscribe to telemetry changes to trigger UI updates
        engine.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        // Subscribe to network connectivity changes
        NetworkMonitor.shared.$isConnected
            .dropFirst()
            .sink { [weak self] connected in
                guard let self = self else { return }
                self.objectWillChange.send()
                if connected {
                    Task {
                        _ = await self.testConnection()
                        if self.isAuthenticated {
                            await self.refresh()
                        }
                    }
                }
            }
            .store(in: &cancellables)

        // Listen for unauthorized session broadcast (401 expiration)
        NotificationCenter.default.addObserver(
            forName: .vaultScopeUnauthorizedSession,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.handleUnauthorizedSession()
            }
        }

        // Initial sync
        Task { [weak self] in
            guard let self = self else { return }
            if self.isAuthenticated {
                await self.refresh()
            } else {
                await self.fetchPublicCatalog()
            }
        }
    }

    // MARK: - Biometric App Lock & Session Expiry
    public func authenticateBiometrics() async {
        guard isBiometricsEnabled else {
            isAppLocked = false
            return
        }
        let result = await BiometricManager.shared.authenticate(reason: "Unlock VaultScope to access cloud infrastructure.")
        if result.success {
            self.isAppLocked = false
            triggerHaptic(.success)
        } else if let err = result.error {
            showNotification(err)
            triggerHaptic(.error)
        }
    }

    public func lockApp() {
        if isBiometricsEnabled && isAuthenticated {
            isAppLocked = true
        }
    }

    public func handleUnauthorizedSession() async {
        if isAuthenticated {
            logout()
            showNotification("Your session has expired. Please sign in again.")
            triggerHaptic(.warning)
        }
    }

    // MARK: - Haptic Feedback
    public enum HapticType {
        case success
        case warning
        case error
        case impact
        case selection
    }

    public func triggerHaptic(_ type: HapticType) {
        switch type {
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .impact:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }

    // MARK: - Notification Banner
    public func showNotification(_ message: String) {
        self.successBannerMessage = message
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if self.successBannerMessage == message {
                self.successBannerMessage = nil
            }
        }
    }

    // MARK: - Synchronization
    public func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        guard let url = URL(string: apiBaseURL) else { return }
        await NetworkClient.shared.setBaseURL(url)
        if !savedApiToken.isEmpty {
            await NetworkClient.shared.setToken(savedApiToken)
        }

        let online = await NetworkClient.shared.checkHealth()
        self.isBackendOnline = online

        // 1. Fetch public catalog & options
        if let liveCatalog = try? await catalogRepo.fetchProducts() {
            self.products = liveCatalog
        }
        if let opts = try? await catalogRepo.fetchOptions() {
            self.storefrontOptions = opts
        }

        guard online, !savedApiToken.isEmpty else { return }

        // 2. Authenticated Profile
        if let liveCustomer = try? await profileRepo.fetchProfile() {
            self.customer = liveCustomer
        }

        // 3. Services
        if let liveServices = try? await servicesRepo.fetchServices() {
            self.services = liveServices
        }

        // 4. Invoices & Billing
        if let liveInvoices = try? await billingRepo.fetchInvoices() {
            self.invoices = liveInvoices
        }
        if let bInfo = try? await billingRepo.fetchBillingInfo() {
            self.billingInfo = bInfo
        }

        // 5. Tickets
        if let liveTickets = try? await ticketsRepo.fetchTickets() {
            self.tickets = liveTickets
        }

        // 6. Activities
        if let liveActivities = try? await activityRepo.fetchActivities() {
            self.activities = liveActivities
        }

        // 7. Billing Emails
        if let emails = try? await profileRepo.fetchBillingEmails() {
            self.billingEmails = emails
        }
    }

    public func fetchPublicCatalog() async {
        guard let url = URL(string: apiBaseURL) else { return }
        await NetworkClient.shared.setBaseURL(url)
        let online = await NetworkClient.shared.checkHealth()
        self.isBackendOnline = online
        if let catalog = try? await catalogRepo.fetchProducts() {
            self.products = catalog
        }
        if let opts = try? await catalogRepo.fetchOptions() {
            self.storefrontOptions = opts
        }
    }

    // MARK: - Infrastructure Operations
    public func startServer(serviceId: UUID) {
        Task {
            showNotification("Sending start command...")
            try? await servicesRepo.start(id: serviceId)
            await self.refresh()
            showNotification("Server starting up.")
        }
    }

    public func stopServer(serviceId: UUID) {
        Task {
            showNotification("Sending poweroff command...")
            try? await servicesRepo.stop(id: serviceId)
            await self.refresh()
            showNotification("Server shutdown initiated.")
        }
    }

    public func rebootServer(serviceId: UUID) {
        Task {
            showNotification("Sending reboot signal...")
            try? await servicesRepo.restart(id: serviceId)
            await self.refresh()
            showNotification("Reboot signal dispatched.")
        }
    }

    public func restartServer(serviceId: UUID) {
        rebootServer(serviceId: serviceId)
    }

    public func reinstallServer(serviceId: UUID, osImage: String) {
        Task {
            showNotification("Initiating OS reinstall...")
            do {
                try await servicesRepo.reinstall(id: serviceId, os: osImage)
                await self.refresh()
                showNotification("OS reinstall initiated with \(osImage).")
            } catch {
                showNotification("Reinstall failed: \(error.localizedDescription)")
            }
        }
    }

    public func cancelService(serviceId: UUID, mode: String = "period_end", reason: String? = nil, feedback: String? = nil) {
        Task {
            showNotification("Submitting cancellation request...")
            do {
                try await servicesRepo.cancel(id: serviceId, mode: mode, reason: reason, feedback: feedback)
                await self.refresh()
                showNotification(mode == "immediate" ? "Service terminated immediately." : "Scheduled for cancellation at end of billing cycle.")
            } catch {
                showNotification("Cancellation failed: \(error.localizedDescription)")
            }
        }
    }

    public func uncancelService(serviceId: UUID) {
        Task {
            showNotification("Restoring service...")
            do {
                try await servicesRepo.uncancel(id: serviceId)
                await self.refresh()
                showNotification("Cancellation revoked. Service restored.")
            } catch {
                showNotification("Failed to revoke: \(error.localizedDescription)")
            }
        }
    }

    public func getConsole(serviceId: UUID) async -> String? {
        return try? await servicesRepo.console(id: serviceId)
    }

    public func deleteServer(serviceId: UUID) {
        Task {
            showNotification("Terminating service...")
            try? await servicesRepo.delete(id: serviceId)
            await self.refresh()
            showNotification("Service terminated.")
        }
    }

    public func deployProduct(product: Product, hostname: String) {
        Task {
            showNotification("Submitting cloud order...")
            do {
                _ = try await catalogRepo.placeOrder(
                    productId: product.id,
                    hostname: hostname.isEmpty ? nil : hostname
                )
                await self.refresh()
                showNotification("Order placed successfully! Provisioning...")
            } catch {
                showNotification("Order failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Invoices
    public func payInvoice(invoiceId: UUID) {
        Task {
            showNotification("Processing payment...")
            do {
                try await billingRepo.payInvoice(id: invoiceId)
                await self.refresh()
                showNotification("Invoice paid successfully.")
            } catch {
                showNotification("Payment failed: \(error.localizedDescription)")
            }
        }
    }

    public func downloadInvoicePdf(invoiceId: UUID) async throws -> Data {
        return try await billingRepo.downloadInvoicePdf(id: invoiceId)
    }

    // MARK: - Support
    public func createTicket(
        subject: String,
        category: String,
        priority: TicketPriority,
        relatedServiceId: UUID?,
        initialMessage: String
    ) {
        Task {
            showNotification("Creating support ticket...")
            do {
                try await ticketsRepo.createTicket(
                    subject: subject,
                    content: initialMessage,
                    category: category,
                    priority: priority.rawValue,
                    relatedServiceId: relatedServiceId
                )
                await self.refresh()
                showNotification("Support ticket opened.")
            } catch {
                showNotification("Ticket error: \(error.localizedDescription)")
            }
        }
    }

    public func replyToTicket(ticketId: UUID, messageText: String) {
        Task {
            showNotification("Posting reply...")
            do {
                try await ticketsRepo.replyTicket(id: ticketId, content: messageText)
                if let updated = try? await ticketsRepo.fetchTicketDetail(id: ticketId) {
                    if let idx = self.tickets.firstIndex(where: { $0.id == ticketId }) {
                        self.tickets[idx] = updated
                    }
                } else {
                    await self.refresh()
                }
                showNotification("Reply posted.")
            } catch {
                showNotification("Reply error: \(error.localizedDescription)")
            }
        }
    }

    public func refreshTicketDetail(ticketId: UUID) async {
        if let updated = try? await ticketsRepo.fetchTicketDetail(id: ticketId) {
            if let idx = self.tickets.firstIndex(where: { $0.id == ticketId }) {
                self.tickets[idx] = updated
            }
        }
    }

    // MARK: - Profile & Compliance
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
        try await profileRepo.updateProfile(
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
        await self.refresh()
        showNotification("Profile updated successfully.")
    }

    public func verifyVat(vatId: String) async -> (valid: Bool, message: String) {
        do {
            let res = try await profileRepo.verifyVat(vatId: vatId)
            await self.refresh()
            return (res.valid, res.message)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    public func setupMfa() async throws -> MfaSetupResponse {
        return try await profileRepo.setupMfa()
    }

    public func enableMfa(code: String) async throws -> String {
        let msg = try await profileRepo.enableMfa(code: code)
        await self.refresh()
        showNotification("2FA successfully enabled.")
        return msg
    }

    public func disableMfa(code: String? = nil, password: String? = nil) async throws -> String {
        let msg = try await profileRepo.disableMfa(code: code, password: password)
        await self.refresh()
        showNotification("2FA disabled.")
        return msg
    }

    public func addBillingEmail(email: String) async throws {
        let newEmail = try await profileRepo.addBillingEmail(email: email)
        self.billingEmails.append(newEmail)
        showNotification("Billing recipient added. Verification email dispatched.")
    }

    public func deleteBillingEmail(id: UUID) async throws {
        try await profileRepo.deleteBillingEmail(id: id)
        self.billingEmails.removeAll(where: { $0.id == id })
        showNotification("Billing recipient removed.")
    }

    public func resendBillingEmailVerification(id: UUID) async throws -> String {
        return try await profileRepo.resendBillingEmail(id: id)
    }

    public func resendAccountVerification() async {
        guard !customer.email.isEmpty else { return }
        do {
            let msg = try await authRepo.resendVerification(email: customer.email)
            showNotification(msg)
        } catch {
            showNotification("Resend failed: \(error.localizedDescription)")
        }
    }

    public func deleteAccount() async throws {
        try await profileRepo.deleteAccount()
        logout()
    }

    // MARK: - Connection & Tokens
    public func testConnection() async -> Bool {
        if let url = URL(string: apiBaseURL) {
            await NetworkClient.shared.setBaseURL(url)
            if !savedApiToken.isEmpty {
                await NetworkClient.shared.setToken(savedApiToken)
            }
            let result = await NetworkClient.shared.checkHealth()
            self.isBackendOnline = result
            if result {
                await self.refresh()
            }
            return result
        }
        return false
    }

    public func generateApiToken() -> String {
        let prefix = "vs_pat_"
        let randomChars = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        let token = "\(prefix)\(randomChars)"
        self.savedApiToken = token
        SessionStorage.shared.saveToken(token)
        showNotification("New API token generated & saved.")
        return token
    }

    // MARK: - Authentication
    public func login(email: String, password: String, totpCode: String? = nil) async throws {
        if let url = URL(string: apiBaseURL) {
            await NetworkClient.shared.setBaseURL(url)
        }

        let (token, loggedCustomer) = try await authRepo.login(email: email, password: password, totpCode: totpCode)
        self.savedApiToken = token
        self.customer = loggedCustomer
        self.isAuthenticated = true
        SessionStorage.shared.saveToken(token)
        SessionStorage.shared.saveCustomer(loggedCustomer)

        await refresh()
        showNotification("Welcome back, \(loggedCustomer.name.isEmpty ? loggedCustomer.email : loggedCustomer.name)!")
    }

    public func register(
        username: String,
        name: String,
        email: String,
        password: String,
        company: String = "",
        address: String = "VaultScope Cloud",
        city: String = "Berlin",
        country: String = "Germany",
        vatId: String = ""
    ) async throws -> String {
        if let url = URL(string: apiBaseURL) {
            await NetworkClient.shared.setBaseURL(url)
        }

        let (tokenOpt, customerOpt, message) = try await authRepo.register(
            username: username,
            name: name,
            email: email,
            password: password,
            company: company,
            address: address,
            city: city,
            country: country,
            vatId: vatId
        )

        if let token = tokenOpt, let cust = customerOpt {
            self.savedApiToken = token
            self.customer = cust
            self.isAuthenticated = true
            SessionStorage.shared.saveToken(token)
            SessionStorage.shared.saveCustomer(cust)
            await refresh()
            showNotification("Welcome to VaultScope, \(cust.name)!")
        }

        return message
    }

    public func logout() {
        Task {
            await authRepo.logout()
        }
        self.isAuthenticated = false
        SessionStorage.shared.clearToken()
        SessionStorage.shared.clearCustomer()
        self.savedApiToken = ""
        self.services = []
        self.invoices = []
        self.tickets = []
        self.activities = []
        self.customer = Customer(name: "", email: "")
        showNotification("Signed out.")
    }
}
