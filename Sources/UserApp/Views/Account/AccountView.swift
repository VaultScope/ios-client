import SwiftUI
import UIKit

public struct AccountView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    // Edit Profile Sheet
    @State private var showEditProfileSheet: Bool = false
    @State private var editName: String = ""
    @State private var editUsername: String = ""
    @State private var editPhone: String = ""
    @State private var editCompany: String = ""
    @State private var editAddress: String = ""
    @State private var editPostalCode: String = ""
    @State private var editCity: String = ""
    @State private var editCountry: String = "Germany"
    @State private var editVatId: String = ""
    @State private var isSavingProfile: Bool = false
    @State private var isVerifyingVat: Bool = false
    @State private var vatResultMsg: String? = nil

    // 2FA Management
    @State private var showMfaSetupSheet: Bool = false
    @State private var mfaSecret: String = ""
    @State private var mfaUrl: String = ""
    @State private var mfaCodeInput: String = ""
    @State private var isEnablingMfa: Bool = false
    @State private var mfaSetupError: String? = nil
    @State private var showDisableMfaAlert: Bool = false
    @State private var disableMfaPassword: String = ""
    @State private var showDisableMfaPrompt: Bool = false

    // Billing Emails
    @State private var showAddEmailSheet: Bool = false
    @State private var newBillingEmail: String = ""
    @State private var isAddingEmail: Bool = false
    @State private var addEmailError: String? = nil

    // Account Deletion
    @State private var showDeleteAccountAlert: Bool = false

    // Connection testing & Legal
    @State private var isTestingConnection: Bool = false
    @State private var connectionResult: String? = nil
    @State private var showLegalSheet: Bool = false
    @State private var legalSheetTitle: String = ""
    @State private var legalSheetContent: String = ""

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                // Email Verification Alert Banner
                if !appState.customer.emailVerified {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(VaultTheme.amber)
                                Text("Email Unverified")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(VaultTheme.amber)
                            }
                            Text("Your account email (\(appState.customer.email)) has not been verified yet. Check your inbox or request a new link.")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button {
                                Task {
                                    await appState.resendAccountVerification()
                                }
                            } label: {
                                Label("Resend Verification Email", systemImage: "envelope.badge")
                                    .font(.caption.weight(.semibold))
                            }
                            .buttonStyle(.bordered)
                            .tint(VaultTheme.amber)
                            .padding(.top, 2)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Section 1: Client Profile
                Section {
                    HStack {
                        Text("Full Name")
                        Spacer()
                        Text(appState.customer.name.isEmpty ? "Client" : appState.customer.name)
                            .foregroundColor(.secondary)
                    }

                    if !appState.customer.username.isEmpty {
                        HStack {
                            Text("Username")
                            Spacer()
                            Text("@\(appState.customer.username)")
                                .font(.subheadline.monospaced())
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("Email")
                        Spacer()
                        HStack(spacing: 4) {
                            Text(appState.customer.email)
                            if appState.customer.emailVerified {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(VaultTheme.emerald)
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.secondary)
                    }

                    if !appState.customer.phone.isEmpty {
                        HStack {
                            Text("Phone")
                            Spacer()
                            Text(appState.customer.phone)
                                .foregroundColor(.secondary)
                        }
                    }

                    if !appState.customer.company.isEmpty {
                        HStack {
                            Text("Company")
                            Spacer()
                            Text(appState.customer.company)
                                .foregroundColor(.secondary)
                        }
                    }

                    if !appState.customer.address.isEmpty {
                        HStack {
                            Text("Address")
                            Spacer()
                            let fullAddr = [appState.customer.address, appState.customer.postalCode, appState.customer.city]
                                .filter { !$0.isEmpty }
                                .joined(separator: ", ")
                            Text(fullAddr)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Text("Country / Region")
                        Spacer()
                        Text(appState.customer.country)
                            .foregroundColor(.secondary)
                    }

                    if !appState.customer.vatId.isEmpty {
                        HStack {
                            Text("VAT ID")
                            Spacer()
                            HStack(spacing: 4) {
                                Text(appState.customer.vatId)
                                    .font(.subheadline.monospaced())
                                if appState.customer.vatVerified {
                                    Text("EU VIES VERIFIED")
                                        .font(.system(size: 8, weight: .bold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(VaultTheme.emerald.opacity(0.2))
                                        .foregroundColor(VaultTheme.emerald)
                                        .cornerRadius(4)
                                }
                            }
                            .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        startEditProfile()
                    } label: {
                        Label("Edit Profile & Company Details", systemImage: "pencil")
                    }
                } header: {
                    Text("Client Profile")
                }

                // Section 2: Security & Authentication (2FA)
                Section("Security & Authentication") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Two-Factor Authentication (2FA)")
                                .font(.subheadline.weight(.medium))
                            Text(appState.customer.twoFactorEnabled ? "Time-based OTP token active" : "Protect your account with an authenticator app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        StatusPill(
                            title: appState.customer.twoFactorEnabled ? "ENABLED" : "DISABLED",
                            color: appState.customer.twoFactorEnabled ? VaultTheme.emerald : VaultTheme.textMuted
                        )
                    }

                    if appState.customer.twoFactorEnabled {
                        Button(role: .destructive) {
                            showDisableMfaPrompt = true
                        } label: {
                            Label("Disable Two-Factor Authentication", systemImage: "lock.open.fill")
                        }
                    } else {
                        Button {
                            initiateMfaSetup()
                        } label: {
                            Label("Enable Two-Factor Authentication", systemImage: "shield.lefthalf.filled")
                        }
                    }
                }

                // Section 2b: Device Security & Privacy
                Section {
                    Toggle(isOn: Binding(
                        get: { appState.isBiometricsEnabled },
                        set: { newValue in
                            if newValue {
                                Task {
                                    let res = await BiometricManager.shared.authenticate(reason: "Verify \(appState.biometryType.rawValue) to enable biometric lock.")
                                    if res.success {
                                        appState.isBiometricsEnabled = true
                                        appState.showNotification("\(appState.biometryType.rawValue) lock enabled.")
                                    } else {
                                        appState.isBiometricsEnabled = false
                                        if let err = res.error {
                                            appState.showNotification(err)
                                        }
                                    }
                                }
                            } else {
                                appState.isBiometricsEnabled = false
                                appState.showNotification("Biometric lock disabled.")
                            }
                        }
                    )) {
                        HStack(spacing: 12) {
                            Image(systemName: appState.biometryType.icon)
                                .foregroundColor(VaultTheme.accentBright)
                                .font(.title3)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Require \(appState.biometryType.rawValue)")
                                    .font(.subheadline.weight(.medium))
                                Text("Biometric authentication on launch and app resume")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "key.viewfinder")
                            .foregroundColor(VaultTheme.emerald)
                            .font(.title3)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Apple Keychain & Secure Enclave")
                                .font(.subheadline.weight(.medium))
                            Text("Session tokens isolated to hardware (kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(VaultTheme.emerald)
                            .font(.caption)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "eye.slash.fill")
                            .foregroundColor(VaultTheme.cyan)
                            .font(.title3)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Multitasking Privacy Shield")
                                .font(.subheadline.weight(.medium))
                            Text("Masks infrastructure and server IPs in iOS App Switcher")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(VaultTheme.cyan)
                            .font(.caption)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(VaultTheme.purple)
                            .font(.title3)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Strict Transport Security (HSTS)")
                                .font(.subheadline.weight(.medium))
                            Text("TLS 1.3 enforced across all API endpoints")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(VaultTheme.purple)
                            .font(.caption)
                    }
                } header: {
                    Text("Device Security & Privacy")
                } footer: {
                    Text("VaultScope leverages hardware-backed Secure Enclave keychains and enforces transport security for critical cloud infrastructure.")
                        .font(.caption)
                }

                // Section 2c: Realtime Ticket Notifications
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(VaultTheme.accentBright)
                            .font(.title3)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Realtime Ticket Engine")
                                .font(.subheadline.weight(.medium))
                            Text(appState.notificationEngine.isPollingActive ? "Active (SSE + 6s delta polling)" : "Idle")
                                .font(.caption2)
                                .foregroundColor(appState.notificationEngine.isPollingActive ? VaultTheme.emerald : VaultTheme.textMuted)
                        }
                        Spacer()
                        StatusPill(
                            title: appState.notificationEngine.isPollingActive ? "ACTIVE" : "STANDBY",
                            color: appState.notificationEngine.isPollingActive ? VaultTheme.emerald : VaultTheme.textMuted
                        )
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "app.badge.fill")
                            .foregroundColor(VaultTheme.cyan)
                            .font(.title3)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("System Notifications & Badges")
                                .font(.subheadline.weight(.medium))
                            Text(appState.notificationEngine.hasPermission ? "Authorized (.alert, .sound, .badge)" : "Permission required")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if !appState.notificationEngine.hasPermission {
                            Button("Allow") {
                                appState.notificationEngine.requestAuthorization()
                            }
                            .buttonStyle(.bordered)
                            .tint(VaultTheme.accentBright)
                            .font(.caption.weight(.semibold))
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(VaultTheme.emerald)
                                .font(.caption)
                        }
                    }

                    // Interactive Notification Simulation / Diagnostics
                    Button {
                        let sampleTicketId = appState.tickets.first?.id ?? UUID()
                        let sampleTicketNum = appState.tickets.first?.ticketNumber ?? "TKT-1042"
                        let sample = TicketToastItem(
                            ticketId: sampleTicketId,
                            ticketNumber: sampleTicketNum,
                            title: "Support Reply: \(sampleTicketNum)",
                            message: "VaultScope Engineer: \"Your server network bandwidth has been upgraded to 10 Gbps.\"",
                            notificationType: .newStaffMessage,
                            status: .inProgress,
                            authorName: "VaultScope Engineer"
                        )
                        appState.notificationEngine.deliverNotification(sample)
                    } label: {
                        Label("Test Staff Reply Notification", systemImage: "bubble.left.and.bubble.right.fill")
                    }

                    Button {
                        let sampleTicketId = appState.tickets.first?.id ?? UUID()
                        let sampleTicketNum = appState.tickets.first?.ticketNumber ?? "TKT-1042"
                        let sample = TicketToastItem(
                            ticketId: sampleTicketId,
                            ticketNumber: sampleTicketNum,
                            title: "Ticket Status: WAITING ON YOU",
                            message: "\"Dedicated Server Migration\" requires your SSH confirmation.",
                            notificationType: .statusChanged,
                            status: .waitingCustomer
                        )
                        appState.notificationEngine.deliverNotification(sample)
                    } label: {
                        Label("Test Status Change Notification", systemImage: "arrow.triangle.2.circlepath")
                    }
                } header: {
                    Text("Realtime Ticket Notifications")
                } footer: {
                    Text("VaultScope streams live ticket messages via Server-Sent Events (SSE) and polls background updates every 6 seconds to deliver native toast banners and system push alerts.")
                        .font(.caption)
                }

                // Section 3: Additional Billing Email Recipients (B2B)
                Section {
                    if appState.billingEmails.isEmpty {
                        Text("No secondary billing email addresses added. Invoices are dispatched to your primary email.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(appState.billingEmails) { bEmail in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(bEmail.email)
                                        .font(.subheadline)
                                    Text(bEmail.verified ? "Verified CC Recipient" : "Pending Verification")
                                        .font(.caption2)
                                        .foregroundColor(bEmail.verified ? VaultTheme.emerald : VaultTheme.amber)
                                }

                                Spacer()

                                if !bEmail.verified {
                                    Button {
                                        Task {
                                            do {
                                                let msg = try await appState.resendBillingEmailVerification(id: bEmail.id)
                                                appState.showNotification(msg)
                                            } catch {
                                                appState.showNotification("Failed: \(error.localizedDescription)")
                                            }
                                        }
                                    } label: {
                                        Text("Resend")
                                            .font(.caption.weight(.medium))
                                    }
                                    .buttonStyle(.bordered)
                                }

                                Button(role: .destructive) {
                                    Task {
                                        try? await appState.deleteBillingEmail(id: bEmail.id)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }

                    Button {
                        newBillingEmail = ""
                        addEmailError = nil
                        showAddEmailSheet = true
                    } label: {
                        Label("Add Billing CC Recipient", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Billing Email CC Recipients")
                } footer: {
                    Text("Automated PDF invoices and payment receipts will be copied to verified billing recipients.")
                }

                // Section 4: Personal Access Tokens
                Section("Personal Access Tokens") {
                    if !appState.savedApiToken.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Active Token")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Text(appState.savedApiToken)
                                    .font(.caption.monospaced())
                                    .lineLimit(1)
                                    .truncationMode(.middle)

                                Spacer()

                                Button {
                                    UIPasteboard.general.string = appState.savedApiToken
                                    appState.showNotification("API token copied to clipboard.")
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }

                    Button {
                        _ = appState.generateApiToken()
                    } label: {
                        Label(appState.savedApiToken.isEmpty ? "Generate API Token" : "Generate New Token", systemImage: "key.fill")
                    }
                }

                // Section 5: Backend API Target
                Section {
                    TextField("API Base URL", text: $appState.apiBaseURL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .font(.subheadline.monospaced())

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button("Live Production (api.vaultscope.de)") {
                                appState.apiBaseURL = "https://api.vaultscope.de"
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(VaultTheme.cyan)
                            .font(.caption2.weight(.medium))

                            Button("localhost:3000") {
                                appState.apiBaseURL = "http://localhost:3000"
                            }
                            .buttonStyle(.bordered)
                            .font(.caption2.monospaced())

                            Button("172.31.244.0:3000") {
                                appState.apiBaseURL = "http://172.31.244.0:3000"
                            }
                            .buttonStyle(.bordered)
                            .font(.caption2.monospaced())
                        }
                        .padding(.vertical, 2)
                    }

                    Button {
                        testConnection()
                    } label: {
                        if isTestingConnection {
                            HStack {
                                ProgressView()
                                Text("Testing Connection...")
                            }
                        } else {
                            Label("Test Connection", systemImage: "antenna.radiowaves.left.and.right")
                        }
                    }
                    .disabled(isTestingConnection)

                    if let res = connectionResult {
                        Text(res)
                            .font(.caption)
                            .foregroundColor(appState.isBackendOnline ? VaultTheme.emerald : VaultTheme.rose)
                    }
                } header: {
                    Text("Backend API Target")
                } footer: {
                    Text("VaultScope REST & GraphQL Gateway with Axum CSRF and Bearer token security.")
                        .font(.caption)
                }

                // Section 6: Cloud Synchronization
                Section("Cloud Synchronization") {
                    Button {
                        Task {
                            await appState.refresh()
                            appState.showNotification("Synchronized with VaultScope API.")
                        }
                    } label: {
                        Label("Force Sync with API", systemImage: "arrow.triangle.2.circlepath")
                    }
                }

                // Section 7: Legal & Compliance
                Section("Legal & Compliance") {
                    Button("Terms of Service") {
                        openLegal(
                            title: "Terms of Service",
                            content: "VaultScope Cloud Infrastructure Terms of Service.\n\nAll services are provided under German B2B SLA terms. Fair-use networking applies across 100G backbone connections."
                        )
                    }

                    Button("Privacy Policy (GDPR / DSGVO)") {
                        openLegal(
                            title: "Privacy Policy (GDPR)",
                            content: "All customer data is processed exclusively within the European Union (Frankfurt am Main and Falkenstein, Germany) under strict GDPR/DSGVO compliance."
                        )
                    }

                    Button("Data Processing Agreement (DPA)") {
                        openLegal(
                            title: "Data Processing Agreement",
                            content: "Standard EU Contractual Clauses and DPA for automated server infrastructure management."
                        )
                    }
                }

                // Section 8: Authentication & Session
                Section {
                    Button(role: .destructive) {
                        dismiss()
                        appState.logout()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Sign Out of VaultScope", systemImage: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }

                // Section 9: Danger Zone
                Section("Account Closure") {
                    Button(role: .destructive) {
                        showDeleteAccountAlert = true
                    } label: {
                        Label("Close & Delete Account", systemImage: "person.crop.circle.badge.xmark")
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 4) {
                            Text("VaultScope Client")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(VaultTheme.textMuted)
                            Text("Version 1.0.0 (Production Native iOS)")
                                .font(.caption2)
                                .foregroundColor(VaultTheme.textFaint)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            // Edit Profile Sheet
            .sheet(isPresented: $showEditProfileSheet) {
                NavigationStack {
                    Form {
                        Section("Contact Details") {
                            TextField("Full Name", text: $editName)
                            TextField("Username", text: $editUsername)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            TextField("Phone Number", text: $editPhone)
                                .keyboardType(.phonePad)
                        }

                        Section("Company & Billing Address") {
                            TextField("Company Name (Optional)", text: $editCompany)
                            TextField("Street Address", text: $editAddress)
                            HStack {
                                TextField("Postal Code", text: $editPostalCode)
                                    .frame(maxWidth: 100)
                                TextField("City", text: $editCity)
                            }
                            TextField("Country", text: $editCountry)
                        }

                        Section("VAT Identification (EU Businesses)") {
                            TextField("e.g. DE123456789", text: $editVatId)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.characters)
                                .font(.subheadline.monospaced())

                            Button {
                                verifyVatAction()
                            } label: {
                                HStack {
                                    Label("Verify via EU VIES Gateway", systemImage: "checkmark.seal")
                                    Spacer()
                                    if isVerifyingVat { ProgressView() }
                                }
                            }
                            .disabled(editVatId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isVerifyingVat)

                            if let res = vatResultMsg {
                                Text(res)
                                    .font(.caption)
                                    .foregroundColor(res.contains("successfully") ? VaultTheme.emerald : VaultTheme.amber)
                            }
                        }
                    }
                    .navigationTitle("Edit Profile")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showEditProfileSheet = false }
                        }
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Save") {
                                saveProfile()
                            }
                            .disabled(isSavingProfile)
                        }
                    }
                }
            }
            // 2FA Setup Sheet
            .sheet(isPresented: $showMfaSetupSheet) {
                NavigationStack {
                    Form {
                        Section("1. Setup Key") {
                            Text("Add this secret key into your authenticator app (1Password, Google Authenticator, Apple Passwords):")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Text(mfaSecret)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = mfaSecret
                                    appState.showNotification("2FA Secret copied.")
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 4)
                        }

                        Section("2. Verify 6-digit Code") {
                            TextField("Enter 6-digit code (e.g. 123456)", text: $mfaCodeInput)
                                .keyboardType(.numberPad)
                                .font(.title3.monospaced())

                            if let err = mfaSetupError {
                                Text(err)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            Button {
                                confirmEnableMfa()
                            } label: {
                                HStack {
                                    Spacer()
                                    if isEnablingMfa { ProgressView() }
                                    Text("Activate Two-Factor Authentication")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(VaultTheme.cyan)
                            .disabled(mfaCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).count < 6 || isEnablingMfa)
                        }
                    }
                    .navigationTitle("Configure 2FA")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showMfaSetupSheet = false }
                        }
                    }
                }
            }
            // Disable 2FA Prompt
            .sheet(isPresented: $showDisableMfaPrompt) {
                NavigationStack {
                    Form {
                        Section("Disable Two-Factor Authentication") {
                            Text("Please enter your account password or current 6-digit TOTP code to confirm disabling 2FA:")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            SecureField("Password or TOTP Code", text: $disableMfaPassword)

                            Button(role: .destructive) {
                                disableMfaAction()
                            } label: {
                                Text("Disable 2FA")
                                    .frame(maxWidth: .infinity)
                            }
                            .disabled(disableMfaPassword.isEmpty)
                        }
                    }
                    .navigationTitle("Disable 2FA")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showDisableMfaPrompt = false }
                        }
                    }
                }
            }
            // Add Billing Email Sheet
            .sheet(isPresented: $showAddEmailSheet) {
                NavigationStack {
                    Form {
                        Section("New Billing CC Recipient") {
                            TextField("billing@company.com", text: $newBillingEmail)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            if let err = addEmailError {
                                Text(err)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }

                            Button {
                                addBillingEmailAction()
                            } label: {
                                HStack {
                                    Spacer()
                                    if isAddingEmail { ProgressView() }
                                    Text("Add Recipient")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(VaultTheme.cyan)
                            .disabled(newBillingEmail.isEmpty || isAddingEmail)
                        }
                    }
                    .navigationTitle("Add Billing Email")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") { showAddEmailSheet = false }
                        }
                    }
                }
            }
            // Account Deletion Alert
            .confirmationDialog("Close & Delete Account", isPresented: $showDeleteAccountAlert, titleVisibility: .visible) {
                Button("Permanently Delete Account", role: .destructive) {
                    deleteAccountAction()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to permanently delete your VaultScope account? All servers must be stopped/terminated first.")
            }
            // Legal Sheet
            .sheet(isPresented: $showLegalSheet) {
                NavigationStack {
                    ScrollView {
                        Text(legalSheetContent)
                            .padding()
                            .font(.body)
                    }
                    .navigationTitle(legalSheetTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Close") {
                                showLegalSheet = false
                            }
                        }
                    }
                }
            }
        }
    }

    private func startEditProfile() {
        editName = appState.customer.name
        editUsername = appState.customer.username
        editPhone = appState.customer.phone
        editCompany = appState.customer.company
        editAddress = appState.customer.address
        editPostalCode = appState.customer.postalCode
        editCity = appState.customer.city
        editCountry = appState.customer.country
        editVatId = appState.customer.vatId
        vatResultMsg = nil
        showEditProfileSheet = true
    }

    private func verifyVatAction() {
        let trimmed = editVatId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let (isValidFormat, normalized) = InputValidator.validateVatId(trimmed)
        guard isValidFormat else {
            vatResultMsg = "Invalid EU VAT ID format. Must include 2-letter EU country code (e.g. DE123456789)."
            return
        }

        editVatId = normalized
        isVerifyingVat = true
        vatResultMsg = nil
        Task {
            let (_, msg) = await appState.verifyVat(vatId: normalized)
            isVerifyingVat = false
            vatResultMsg = msg
        }
    }

    private func saveProfile() {
        isSavingProfile = true
        Task {
            do {
                try await appState.updateProfile(
                    name: editName,
                    username: editUsername,
                    phone: editPhone,
                    company: editCompany,
                    address: editAddress,
                    postalCode: editPostalCode,
                    city: editCity,
                    country: editCountry,
                    vatId: editVatId
                )
                isSavingProfile = false
                showEditProfileSheet = false
            } catch {
                isSavingProfile = false
                appState.showNotification("Update failed: \(error.localizedDescription)")
            }
        }
    }

    private func initiateMfaSetup() {
        Task {
            do {
                let setup = try await appState.setupMfa()
                mfaSecret = setup.secret
                mfaUrl = setup.url
                mfaCodeInput = ""
                mfaSetupError = nil
                showMfaSetupSheet = true
            } catch {
                appState.showNotification("Failed to start 2FA: \(error.localizedDescription)")
            }
        }
    }

    private func confirmEnableMfa() {
        let code = mfaCodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard InputValidator.validateTotpCode(code) else {
            mfaSetupError = "Please enter a valid 6-digit numeric TOTP code."
            return
        }

        isEnablingMfa = true
        mfaSetupError = nil
        Task {
            do {
                _ = try await appState.enableMfa(code: code)
                isEnablingMfa = false
                showMfaSetupSheet = false
            } catch {
                isEnablingMfa = false
                mfaSetupError = error.localizedDescription
            }
        }
    }

    private func disableMfaAction() {
        let pw = disableMfaPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pw.isEmpty else { return }

        Task {
            do {
                _ = try await appState.disableMfa(code: pw.count == 6 ? pw : nil, password: pw.count != 6 ? pw : nil)
                showDisableMfaPrompt = false
                disableMfaPassword = ""
            } catch {
                appState.showNotification("Failed to disable 2FA: \(error.localizedDescription)")
            }
        }
    }

    private func addBillingEmailAction() {
        let email = newBillingEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let (isValid, errorMsg) = InputValidator.validateEmail(email)
        guard isValid else {
            addEmailError = errorMsg ?? "Invalid email format."
            return
        }

        isAddingEmail = true
        addEmailError = nil
        Task {
            do {
                try await appState.addBillingEmail(email: email)
                isAddingEmail = false
                showAddEmailSheet = false
            } catch {
                isAddingEmail = false
                addEmailError = error.localizedDescription
            }
        }
    }

    private func deleteAccountAction() {
        Task {
            do {
                try await appState.deleteAccount()
                dismiss()
            } catch {
                appState.showNotification("Deletion failed: \(error.localizedDescription)")
            }
        }
    }

    private func testConnection() {
        isTestingConnection = true
        connectionResult = nil
        Task {
            let ok = await appState.testConnection()
            isTestingConnection = false
            connectionResult = ok ? "Connected successfully to \(appState.apiBaseURL)." : "Failed to reach \(appState.apiBaseURL)."
        }
    }

    private func openLegal(title: String, content: String) {
        legalSheetTitle = title
        legalSheetContent = content
        showLegalSheet = true
    }
}
