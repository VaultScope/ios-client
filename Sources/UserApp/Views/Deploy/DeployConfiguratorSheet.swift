import SwiftUI

public struct DeployConfiguratorSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    public let product: Product

    @State private var customHostname: String = ""
    @State private var selectedLocation: String = "Frankfurt (fsn1)"
    @State private var selectedOs: String = "ubuntu-24.04"
    @State private var sshPublicKey: String = ""
    @State private var isDeploying: Bool = false

    private let datacenterLocations = [
        "Frankfurt (fsn1) - Germany",
        "Nuremberg (nbg1) - Germany",
        "Helsinki (hel1) - Finland",
        "Ashburn (iad1) - US East",
        "Hillsboro (pdx1) - US West"
    ]

    private var availableOsList: [OsImage] {
        if let images = appState.storefrontOptions?.osImages, !images.isEmpty {
            return images
        }
        return [
            OsImage(id: "ubuntu-24.04", name: "Ubuntu 24.04 LTS (Noble)"),
            OsImage(id: "ubuntu-22.04", name: "Ubuntu 22.04 LTS (Jammy)"),
            OsImage(id: "debian-12", name: "Debian 12 (Bookworm)"),
            OsImage(id: "almalinux-9", name: "AlmaLinux 9 (RHEL 9)"),
            OsImage(id: "rockylinux-9", name: "Rocky Linux 9 (Enterprise)"),
            OsImage(id: "archlinux", name: "Arch Linux"),
            OsImage(id: "alpine-3.20", name: "Alpine Linux 3.20")
        ]
    }

    private var hostnameValidation: (isValid: Bool, error: String?) {
        InputValidator.validateHostname(customHostname)
    }

    private var sshKeyValidation: (isValid: Bool, keyType: String?, comment: String?)? {
        let trimmed = sshPublicKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return InputValidator.validateSshPublicKey(trimmed)
    }

    private var isFormValid: Bool {
        if !hostnameValidation.isValid { return false }
        if let ssh = sshKeyValidation, !ssh.isValid { return false }
        return true
    }

    public init(product: Product) {
        self.product = product
        let randomSuffix = String(format: "%04d", Int.random(in: 1000...9999))
        self._customHostname = State(initialValue: "srv-\(randomSuffix).vaultscope.net")
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Plan Summary") {
                    HStack {
                        Text("Selected Plan")
                        Spacer()
                        Text(product.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                    }

                    HStack {
                        Text("Category")
                        Spacer()
                        Text(product.category.uppercased())
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Specifications")
                        Spacer()
                        Text(product.specsSummary)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                }

                Section("Instance Configuration") {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Server Hostname", text: $customHostname)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .font(.subheadline.monospaced())

                        if !customHostname.isEmpty && !hostnameValidation.isValid {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(VaultTheme.rose)
                                Text(hostnameValidation.error ?? "Invalid hostname format.")
                                    .foregroundColor(VaultTheme.rose)
                            }
                            .font(.caption2)
                        }
                    }

                    Picker("Datacenter Region", selection: $selectedLocation) {
                        ForEach(datacenterLocations, id: \.self) { loc in
                            Text(loc).tag(loc)
                        }
                    }

                    if !product.category.lowercased().contains("sftp") {
                        Picker("Operating System", selection: $selectedOs) {
                            ForEach(availableOsList) { os in
                                Text(os.name).tag(os.id)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("SSH Public Key (optional)", text: $sshPublicKey)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .font(.caption.monospaced())

                        if let ssh = sshKeyValidation {
                            if ssh.isValid {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(VaultTheme.emerald)
                                    Text("Valid \(ssh.keyType ?? "SSH") key\(ssh.comment.map { " (\($0))" } ?? "")")
                                        .foregroundColor(VaultTheme.emerald)
                                }
                                .font(.caption2)
                            } else {
                                HStack(spacing: 4) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(VaultTheme.amber)
                                    Text("Invalid OpenSSH public key format")
                                        .foregroundColor(VaultTheme.amber)
                                }
                                .font(.caption2)
                            }
                        }
                    }
                }

                Section("Pricing & VAT Breakdown") {
                    HStack {
                        Text("Monthly Net Rate")
                        Spacer()
                        Text(String(format: "€%.2f", product.price))
                            .font(.subheadline.monospaced())
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("German VAT (19%)")
                        Spacer()
                        Text(String(format: "€%.2f", product.price * 0.19))
                            .font(.subheadline.monospaced())
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Total Gross / Month")
                        Spacer()
                        Text(product.formattedGrossPrice)
                            .font(.headline.weight(.bold).monospaced())
                            .foregroundColor(.primary)
                    }
                }

                Section {
                    if isDeploying {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Provisioning order on VaultScope API...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Button {
                            startDeploy()
                        } label: {
                            Text("Deploy Now (\(product.formattedGrossPrice))")
                                .frame(maxWidth: .infinity)
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(VaultTheme.accent)
                        .disabled(!isFormValid)
                    }
                }
            }
            .navigationTitle("Configure Deployment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func startDeploy() {
        guard isFormValid else { return }
        isDeploying = true
        let host = customHostname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "srv-\(Int.random(in: 1000...9999)).vaultscope.net"
            : customHostname

        appState.deployProduct(product: product, hostname: host)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isDeploying = false
            dismiss()
        }
    }
}
