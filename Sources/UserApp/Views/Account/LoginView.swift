import SwiftUI

public struct LoginView: View {
    @EnvironmentObject var appState: AppState

    @State private var isRegisterMode: Bool = false
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var username: String = ""
    @State private var fullName: String = ""
    @State private var companyName: String = ""
    @State private var cityName: String = "Berlin"
    @State private var countryName: String = "Germany"
    @State private var totpCode: String = ""
    @State private var requiresMfa: Bool = false

    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var successInfoMessage: String? = nil
    @State private var showServerSettings: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Brand
                    VStack(spacing: 12) {
                        if let path = Bundle.module.path(forResource: "LogoPicture", ofType: "png") ?? Bundle.module.path(forResource: "logo-image", ofType: "png"),
                           let uiImage = UIImage(contentsOfFile: path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 60)
                                .padding(.bottom, 2)
                        } else {
                            Image(systemName: "shield.fill")
                                .font(.system(size: 48))
                                .foregroundColor(VaultTheme.accentBright)
                        }

                        if let path = Bundle.module.path(forResource: "Logo", ofType: "png"),
                           let uiImage = UIImage(contentsOfFile: path) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 32)
                        } else {
                            Text("VaultScope")
                                .font(.system(size: 32, weight: .bold, design: .default))
                                .foregroundColor(VaultTheme.textPrimary)
                        }

                        Text("Cloud Infrastructure Client Portal")
                            .font(.subheadline)
                            .foregroundColor(VaultTheme.textMuted)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(appState.isBackendOnline ? VaultTheme.emerald : VaultTheme.amber)
                                .frame(width: 8, height: 8)
                            Text(appState.isBackendOnline ? "Connected to API" : "Checking API Connection...")
                                .font(.caption2.monospaced())
                                .foregroundColor(VaultTheme.textMuted)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.top, 16)

                    // Auth Mode Selector
                    Picker("Authentication Mode", selection: $isRegisterMode) {
                        Text("Sign In").tag(false)
                        Text("Create Account").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .onChange(of: isRegisterMode) {
                        errorMessage = nil
                        successInfoMessage = nil
                        requiresMfa = false
                    }

                    // Credentials Form
                    VStack(spacing: 16) {
                        if isRegisterMode {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Username")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.secondary)
                                TextField("e.g. tony_stark", text: $username)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled()
                                    .textInputAutocapitalization(.never)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Full Name")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.secondary)
                                TextField("e.g. Tony Stark", text: $fullName)
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Company (Optional)")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.secondary)
                                TextField("e.g. Stark Industries GmbH", text: $companyName)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                            TextField("client@vaultscope.net", text: $email)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                            SecureField("Enter password", text: $password)
                                .textFieldStyle(.roundedBorder)

                            if isRegisterMode && !password.isEmpty {
                                let (strength, feedback) = InputValidator.evaluatePasswordStrength(password)
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 4) {
                                        ForEach(1...4, id: \.self) { step in
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(step <= strength.rawValue ? strengthColor(strength) : VaultTheme.lineStrong)
                                                .frame(height: 4)
                                        }
                                    }
                                    HStack {
                                        Text("Strength: \(strength.title)")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundColor(strengthColor(strength))
                                        Spacer()
                                        Text(feedback)
                                            .font(.caption2)
                                            .foregroundColor(VaultTheme.textMuted)
                                    }
                                }
                                .padding(.top, 2)
                            }
                        }

                        if isRegisterMode {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Confirm Password")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(.secondary)
                                SecureField("Repeat password", text: $confirmPassword)
                                    .textFieldStyle(.roundedBorder)

                                if !confirmPassword.isEmpty {
                                    if password == confirmPassword {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(VaultTheme.emerald)
                                            Text("Passwords match")
                                                .foregroundColor(VaultTheme.emerald)
                                        }
                                        .font(.caption2)
                                        .padding(.top, 2)
                                    } else {
                                        HStack(spacing: 4) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(VaultTheme.rose)
                                            Text("Passwords do not match")
                                                .foregroundColor(VaultTheme.rose)
                                        }
                                        .font(.caption2)
                                        .padding(.top, 2)
                                    }
                                }
                            }

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("City")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.secondary)
                                    TextField("City", text: $cityName)
                                        .textFieldStyle(.roundedBorder)
                                }

                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Country")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.secondary)
                                    TextField("Country", text: $countryName)
                                        .textFieldStyle(.roundedBorder)
                                }
                            }
                        }

                        // MFA 2FA Challenge Field
                        if requiresMfa && !isRegisterMode {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Image(systemName: "shield.checkered")
                                        .foregroundColor(VaultTheme.cyan)
                                    Text("Two-Factor Authentication Code")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(VaultTheme.cyan)
                                }
                                TextField("6-digit TOTP code (e.g. 123456)", text: $totpCode)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                    .font(.body.monospaced())
                            }
                            .padding(.top, 4)
                        }

                        // Error Banner
                        if let err = errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(err)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.top, 4)
                        }

                        // Success Info Banner
                        if let info = successInfoMessage {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(VaultTheme.emerald)
                                Text(info)
                                    .font(.caption)
                                    .foregroundColor(VaultTheme.emerald)
                            }
                            .padding(.top, 4)
                        }

                        // Submit Button
                        Button {
                            if isRegisterMode {
                                handleRegister()
                            } else {
                                handleLogin()
                            }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .padding(.trailing, 4)
                                }
                                Text(isRegisterMode ? "Create Account" : (requiresMfa ? "Verify & Sign In" : "Sign In"))
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(VaultTheme.accent)
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .padding(.top, 8)
                    }
                    .padding(20)
                    .liquidGlass(cornerRadius: 20)
                    .padding(.horizontal)

                    // Server Configuration
                    DisclosureGroup("API Server Connection", isExpanded: $showServerSettings) {
                        VStack(alignment: .leading, spacing: 10) {
                            TextField("API Base URL", text: $appState.apiBaseURL)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption.monospaced())
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)

                            VStack(alignment: .leading, spacing: 6) {
                                Button("Live Production API (api.vaultscope.de)") {
                                    appState.apiBaseURL = "https://api.vaultscope.de"
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(VaultTheme.cyan)
                                .font(.caption.weight(.medium))

                                HStack(spacing: 8) {
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
                            }
                        }
                        .padding(.top, 8)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                .padding(.bottom, 32)
            }
            .background(VaultTheme.obsidian.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .task {
                _ = await appState.testConnection()
            }
        }
    }

    private func strengthColor(_ strength: PasswordStrength) -> Color {
        switch strength {
        case .veryWeak, .weak: return VaultTheme.rose
        case .fair: return VaultTheme.amber
        case .strong: return VaultTheme.cyan
        case .veryStrong: return VaultTheme.emerald
        }
    }

    private func handleLogin() {
        let (isValidEmail, emailErr) = InputValidator.validateEmail(email)
        guard isValidEmail else {
            errorMessage = emailErr ?? "Please enter a valid email address."
            return
        }

        if requiresMfa {
            guard InputValidator.validateTotpCode(totpCode) else {
                errorMessage = "Please enter a valid 6-digit numeric TOTP code."
                return
            }
        }

        errorMessage = nil
        successInfoMessage = nil
        isLoading = true

        Task {
            do {
                try await appState.login(
                    email: email,
                    password: password,
                    totpCode: requiresMfa ? totpCode : nil
                )
                isLoading = false
            } catch let error as APIError {
                isLoading = false
                switch error {
                case .mfaRequired(let msg):
                    requiresMfa = true
                    errorMessage = msg
                default:
                    errorMessage = error.localizedDescription
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func handleRegister() {
        let (isValidEmail, emailErr) = InputValidator.validateEmail(email)
        guard isValidEmail else {
            errorMessage = emailErr ?? "Please enter a valid email address."
            return
        }

        let (isValidPw, pwErr) = InputValidator.validatePassword(password)
        guard isValidPw else {
            errorMessage = pwErr ?? "Password does not meet enterprise security requirements."
            return
        }

        if password != confirmPassword {
            errorMessage = "Passwords do not match."
            return
        }

        errorMessage = nil
        successInfoMessage = nil
        isLoading = true

        Task {
            do {
                let msg = try await appState.register(
                    username: username.isEmpty ? email.components(separatedBy: "@").first ?? "client" : username,
                    name: fullName.isEmpty ? "Client User" : fullName,
                    email: email,
                    password: password,
                    company: companyName,
                    city: cityName,
                    country: countryName
                )
                isLoading = false
                if !appState.isAuthenticated {
                    successInfoMessage = msg
                    isRegisterMode = false
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
