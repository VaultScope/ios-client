import SwiftUI
import UIKit

public struct ServiceDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    public let serviceId: UUID

    @State private var selectedTimeframe: String = "24H"
    @State private var copiedSSH: Bool = false
    @State private var copiedIP: Bool = false
    @State private var copiedSftp: Bool = false
    @State private var showSftpPassword: Bool = false
    @State private var showShutdownAlert: Bool = false
    @State private var showRebootAlert: Bool = false
    @State private var showDeleteAlert: Bool = false

    // Sheets
    @State private var showConsoleSheet: Bool = false
    @State private var isLoadingConsole: Bool = false
    @State private var consoleURL: String? = nil
    @State private var showReinstallSheet: Bool = false
    @State private var showCancelSheet: Bool = false
    @State private var showSftpClientSheet: Bool = false

    private var service: ServiceInstance? {
        appState.services.first(where: { $0.id == serviceId })
    }

    public init(serviceId: UUID) {
        self.serviceId = serviceId
    }

    public var body: some View {
        Group {
            if let srv = service {
                List {
                    // Cancellation Banner
                    if srv.cancelAtPeriodEnd {
                        cancellationBanner(srv: srv)
                    }

                    // Section 1: Overview
                    systemOverviewSection(srv: srv)

                    // Section 2: Power Controls
                    powerOperationsSection(srv: srv)

                    if !srv.isSftp {
                        // Section 3: Management Tools
                        serverManagementSection(srv: srv)

                        // Section 4: Networking
                        networkingSection(srv: srv)
                    } else {
                        // SFTP Storage Credentials
                        sftpStorageSection(srv: srv)
                    }

                    // Section 5: Telemetry
                    telemetrySection(srv: srv)

                    // Section 6: Cancellation / Danger
                    dangerZoneSection(srv: srv)
                }
                .listStyle(.insetGrouped)
                .navigationTitle(srv.hostname)
                .navigationBarTitleDisplayMode(.inline)
                .confirmationDialog("Graceful Reboot", isPresented: $showRebootAlert, titleVisibility: .visible) {
                    Button("Reboot Now", role: .destructive) {
                        appState.rebootServer(serviceId: srv.id)
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Trigger ACPI reboot on \(srv.hostname)?")
                }
                .confirmationDialog("Power Off Server", isPresented: $showShutdownAlert, titleVisibility: .visible) {
                    Button("Power Off", role: .destructive) {
                        appState.stopServer(serviceId: srv.id)
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Send ACPI poweroff signal to \(srv.hostname)?")
                }
                .confirmationDialog("Terminate Server", isPresented: $showDeleteAlert, titleVisibility: .visible) {
                    Button("Terminate & Erase NVMe", role: .destructive) {
                        appState.deleteServer(serviceId: srv.id)
                        dismiss()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("Permanently delete \(srv.hostname)? Disks will be wiped.")
                }
                .sheet(isPresented: $showConsoleSheet) {
                    ConsoleSheetView(hostname: srv.hostname, consoleURL: consoleURL)
                }
                .sheet(isPresented: $showReinstallSheet) {
                    ReinstallSheetView(serviceId: srv.id)
                }
                .sheet(isPresented: $showCancelSheet) {
                    CancelServiceSheetView(serviceId: srv.id, formattedNextDue: srv.formattedNextDue)
                }
                .sheet(isPresented: $showSftpClientSheet) {
                    SftpClientView(service: srv)
                }
            } else {
                ContentUnavailableView("Server Not Found", systemImage: "exclamationmark.triangle")
            }
        }
    }

    @ViewBuilder
    private func cancellationBanner(srv: ServiceInstance) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(VaultTheme.amber)
                    Text("Cancellation Scheduled")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(VaultTheme.amber)
                }
                Text("This service will be automatically terminated at the end of the current billing cycle.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button {
                    appState.uncancelService(serviceId: srv.id)
                } label: {
                    Label("Revoke Cancellation", systemImage: "arrow.uturn.backward.circle.fill")
                        .font(.caption.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(VaultTheme.emerald)
                .padding(.top, 2)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func systemOverviewSection(srv: ServiceInstance) -> some View {
        Section("System Overview") {
            HStack {
                Text("Status")
                Spacer()
                StatusPill(title: srv.status.title, color: srv.status.color)
            }

            HStack {
                Text("Hostname")
                Spacer()
                Text(srv.hostname)
                    .font(.subheadline.monospaced())
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Plan")
                Spacer()
                HStack(spacing: 6) {
                    if srv.isTrial {
                        Text("FREE TRIAL")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(VaultTheme.purple.opacity(0.2))
                            .foregroundColor(VaultTheme.purple)
                            .cornerRadius(4)
                    }
                    Text(srv.productName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text("Category")
                Spacer()
                Label(srv.categoryTitle, systemImage: srv.categoryIcon)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Specifications")
                Spacer()
                Text(srv.specs)
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Datacenter")
                Spacer()
                Label(srv.datacenter, systemImage: "mappin.circle.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if !srv.isSftp {
                HStack {
                    Text("Operating System")
                    Spacer()
                    Label(srv.osImage, systemImage: "opticaldisc")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Uptime")
                    Spacer()
                    Text(srv.uptimeString)
                        .font(.subheadline.monospaced())
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Text("Renewal Due")
                Spacer()
                Text(srv.formattedNextDue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Monthly Rate")
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(srv.formattedGrossPrice)
                        .font(.subheadline.weight(.semibold).monospaced())
                    Text(srv.formattedPriceBreakdown)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func powerOperationsSection(srv: ServiceInstance) -> some View {
        Section("Power Operations") {
            if srv.status == .stopped {
                Button {
                    appState.startServer(serviceId: srv.id)
                } label: {
                    Label("Start Server", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(VaultTheme.emerald)
            } else {
                HStack(spacing: 12) {
                    Button {
                        showRebootAlert = true
                    } label: {
                        Label("Reboot", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        showShutdownAlert = true
                    } label: {
                        Label("Power Off", systemImage: "power")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
    }

    @ViewBuilder
    private func serverManagementSection(srv: ServiceInstance) -> some View {
        Section("Server Management") {
            Button {
                requestConsole(srvId: srv.id)
            } label: {
                HStack {
                    Label("Launch Web Console (VNC / KVM)", systemImage: "display")
                    Spacer()
                    if isLoadingConsole {
                        ProgressView()
                    }
                }
            }

            Button {
                showReinstallSheet = true
            } label: {
                Label("Reinstall Operating System", systemImage: "arrow.triangle.2.circlepath")
            }

            Button {
                showSftpClientSheet = true
            } label: {
                Label("Browse Files via SFTP", systemImage: "folder.badge.gearshape")
            }
        }
    }

    @ViewBuilder
    private func networkingSection(srv: ServiceInstance) -> some View {
        Section("Networking & SSH Access") {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Public IPv4")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(srv.ip.isEmpty ? "Provisioning IP..." : srv.ip)
                        .font(.subheadline.monospaced())
                }
                Spacer()
                if !srv.ip.isEmpty {
                    Button {
                        UIPasteboard.general.string = srv.ip
                        copiedIP = true
                        Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            copiedIP = false
                        }
                    } label: {
                        Image(systemName: copiedIP ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                }
            }

            if !srv.ipv6.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Public IPv6")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(srv.ipv6)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }

            if !srv.ip.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SSH Command")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("ssh root@\(srv.ip)")
                            .font(.subheadline.monospaced())
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Button {
                        UIPasteboard.general.string = "ssh root@\(srv.ip)"
                        copiedSSH = true
                        Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            copiedSSH = false
                        }
                    } label: {
                        Image(systemName: copiedSSH ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }

    @ViewBuilder
    private func sftpStorageSection(srv: ServiceInstance) -> some View {
        Section {
            Button {
                showSftpClientSheet = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "folder.badge.gearshape.fill")
                        .font(.title2)
                        .foregroundColor(VaultTheme.accentBright)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Open Built-in SFTP Client")
                            .font(.headline)
                            .foregroundColor(VaultTheme.textPrimary)
                        Text("Browse files, create folders & edit configs")
                            .font(.caption2)
                            .foregroundColor(VaultTheme.textMuted)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundColor(VaultTheme.textMuted)
                }
                .padding(.vertical, 4)
            }
        } header: {
            Text("Interactive Storage Explorer")
        }

        Section("SFTP Storage Access") {
            HStack {
                Text("Endpoint Host")
                Spacer()
                Text(srv.hostname.isEmpty ? (srv.ip.isEmpty ? "sftp.vaultscope.de" : srv.ip) : srv.hostname)
                    .font(.subheadline.monospaced())
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Port")
                Spacer()
                Text("\(srv.sftpPort)")
                    .font(.subheadline.monospaced())
                    .foregroundColor(VaultTheme.accentBright)
            }

            HStack {
                Text("Username")
                Spacer()
                Text(srv.sftpUsername)
                    .font(.subheadline.monospaced())
                    .foregroundColor(.secondary)
                Button {
                    UIPasteboard.general.string = srv.sftpUsername
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
            }

            if let pass = srv.sftpPassword, !pass.isEmpty {
                HStack {
                    Text("Password")
                    Spacer()
                    Text(showSftpPassword ? pass : "••••••••••••")
                        .font(.subheadline.monospaced())
                        .foregroundColor(.secondary)

                    Button {
                        showSftpPassword.toggle()
                    } label: {
                        Image(systemName: showSftpPassword ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)

                    Button {
                        UIPasteboard.general.string = pass
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Connect via Terminal / SSHFS")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    Text(srv.sftpCommand)
                        .font(.caption.monospaced())
                        .foregroundColor(.primary)
                    Spacer()
                    Button {
                        UIPasteboard.general.string = srv.sftpCommand
                        copiedSftp = true
                        Task {
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            copiedSftp = false
                        }
                    } label: {
                        Image(systemName: copiedSftp ? "checkmark" : "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }

    @ViewBuilder
    private func telemetrySection(srv: ServiceInstance) -> some View {
        Section {
            Picker("Timeframe", selection: $selectedTimeframe) {
                Text("1H").tag("1H")
                Text("24H").tag("24H")
                Text("7D").tag("7D")
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))

            let cpuPoints: [Double] = srv.status == .running ? [
                max(4, srv.currentCpuPercent * 0.85),
                max(4, srv.currentCpuPercent * 0.95),
                max(4, srv.currentCpuPercent * 1.08),
                max(4, srv.currentCpuPercent * 0.92),
                srv.currentCpuPercent
            ] : [0, 0, 0, 0, 0]

            MetricMiniGraph(
                title: "CPU Load",
                currentValue: String(format: "%.1f", srv.currentCpuPercent),
                data: cpuPoints,
                color: VaultTheme.cyan,
                unit: "%"
            )
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            .listRowBackground(Color.clear)

            let memPoints: [Double] = srv.status == .running ? [
                max(10, srv.currentMemoryPercent * 0.96),
                max(10, srv.currentMemoryPercent * 0.98),
                max(10, srv.currentMemoryPercent * 1.03),
                srv.currentMemoryPercent
            ] : [0, 0, 0, 0, 0]

            MetricMiniGraph(
                title: "Memory Allocation",
                currentValue: String(format: "%.1f", srv.currentMemoryPercent),
                data: memPoints,
                color: VaultTheme.purple,
                unit: "%"
            )
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            .listRowBackground(Color.clear)
        } header: {
            Text("Real-Time Telemetry")
        }
    }

    @ViewBuilder
    private func dangerZoneSection(srv: ServiceInstance) -> some View {
        Section("Subscription & Lifecycle") {
            if srv.cancelAtPeriodEnd {
                Button {
                    appState.uncancelService(serviceId: srv.id)
                } label: {
                    Label("Revoke Scheduled Cancellation", systemImage: "arrow.uturn.backward")
                        .foregroundColor(VaultTheme.emerald)
                }
            } else {
                Button {
                    showCancelSheet = true
                } label: {
                    Label("Cancel Subscription", systemImage: "xmark.circle")
                        .foregroundColor(VaultTheme.amber)
                }
            }

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Terminate Server Instance", systemImage: "trash.fill")
            }
        }
    }

    private func requestConsole(srvId: UUID) {
        isLoadingConsole = true
        Task {
            let url = await appState.getConsole(serviceId: srvId)
            isLoadingConsole = false
            consoleURL = url
            showConsoleSheet = true
        }
    }
}

// MARK: - Sub-sheet: Reinstall OS
struct ReinstallSheetView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let serviceId: UUID
    @State private var selectedReinstallOs: String = "ubuntu-24.04"

    var body: some View {
        NavigationStack {
            Form {
                Section("Select Operating System") {
                    let images: [OsImage] = (appState.storefrontOptions?.osImages.isEmpty == false)
                        ? appState.storefrontOptions!.osImages
                        : [
                            OsImage(id: "ubuntu-24.04", name: "Ubuntu 24.04 LTS"),
                            OsImage(id: "ubuntu-22.04", name: "Ubuntu 22.04 LTS"),
                            OsImage(id: "debian-12", name: "Debian 12 Bookworm"),
                            OsImage(id: "almalinux-9", name: "AlmaLinux 9"),
                            OsImage(id: "rockylinux-9", name: "Rocky Linux 9")
                        ]

                    Picker("Operating System", selection: $selectedReinstallOs) {
                        ForEach(images) { img in
                            Text(img.name).tag(img.id)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section {
                    Button(role: .destructive) {
                        appState.reinstallServer(serviceId: serviceId, osImage: selectedReinstallOs)
                        dismiss()
                    } label: {
                        Text("Reinstall OS & Wipe Primary Disk")
                            .frame(maxWidth: .infinity)
                    }
                } footer: {
                    Text("Warning: Reinstalling will overwrite the root filesystem and format the primary NVMe disk.")
                }
            }
            .navigationTitle("Reinstall OS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Sub-sheet: Cancel Service
struct CancelServiceSheetView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    let serviceId: UUID
    let formattedNextDue: String

    @State private var cancelReason: String = "No longer needed"
    @State private var feedbackText: String = ""

    private let cancellationReasons = [
        "No longer needed",
        "Migrating elsewhere",
        "Cost considerations",
        "Technical limitations",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Cancel Subscription")
                            .font(.headline)
                        Text("Your service will remain operational until the end of the current billing cycle (\(formattedNextDue)), after which it will be safely terminated.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Section("Reason for Cancellation") {
                    Picker("Reason", selection: $cancelReason) {
                        ForEach(cancellationReasons, id: \.self) { reason in
                            Text(reason).tag(reason)
                        }
                    }

                    TextField("Optional feedback or notes", text: $feedbackText)
                }

                Section {
                    Button(role: .destructive) {
                        appState.cancelService(
                            serviceId: serviceId,
                            mode: "period_end",
                            reason: cancelReason,
                            feedback: feedbackText.isEmpty ? nil : feedbackText
                        )
                        dismiss()
                    } label: {
                        Text("Confirm Cancellation at Period End")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Cancel Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Keep Service") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Sub-sheet: Console
struct ConsoleSheetView: View {
    @Environment(\.dismiss) var dismiss
    let hostname: String
    let consoleURL: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let urlStr = consoleURL, let url = URL(string: urlStr) {
                    VStack(spacing: 16) {
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 48))
                            .foregroundColor(VaultTheme.cyan)

                        Text("Out-of-Band Console Ready")
                            .font(.title3.weight(.bold))

                        Text("A secure VNC / KVM console session has been created for \(hostname). Tap below to open in your browser.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Link(destination: url) {
                            Label("Open Web Console", systemImage: "arrow.up.right.square.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(VaultTheme.cyan)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(VaultTheme.amber)
                        Text("No Console Session Available")
                            .font(.headline)
                        Text("The hypervisor did not return an active out-of-band console URL for this server.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .navigationTitle("Server Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
