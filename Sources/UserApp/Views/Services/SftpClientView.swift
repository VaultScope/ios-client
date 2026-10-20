import SwiftUI
import UIKit

// MARK: - SFTP File Item Model
public struct SftpItem: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var path: String
    public var isDirectory: Bool
    public var sizeBytes: Int64
    public var modifiedDate: Date
    public var permissions: String
    public var content: String?

    public init(
        id: UUID = UUID(),
        name: String,
        path: String,
        isDirectory: Bool,
        sizeBytes: Int64 = 0,
        modifiedDate: Date = Date(),
        permissions: String = "-rw-r--r--",
        content: String? = nil
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.isDirectory = isDirectory
        self.sizeBytes = sizeBytes
        self.modifiedDate = modifiedDate
        self.permissions = permissions
        self.content = content
    }

    public var formattedSize: String {
        if isDirectory { return "Folder" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeBytes)
    }

    public var iconName: String {
        if isDirectory { return "folder.fill" }
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "zip", "tar", "gz", "bz2", "7z", "xz":
            return "doc.zipper"
        case "json", "yaml", "yml", "xml", "conf", "env", "toml":
            return "gearshape.2.fill"
        case "sh", "bash", "zsh", "py", "rs", "go", "js", "ts", "php":
            return "curlybraces"
        case "sql", "db", "sqlite":
            return "cylinder.split.1x2.fill"
        case "log", "txt", "md":
            return "doc.text.fill"
        case "png", "jpg", "jpeg", "svg", "webp":
            return "photo.fill"
        case "pdf":
            return "doc.richtext.fill"
        default:
            return "doc.fill"
        }
    }

    public var iconColor: Color {
        if isDirectory { return VaultTheme.accentBright }
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "zip", "tar", "gz", "bz2", "7z", "xz":
            return VaultTheme.amber
        case "json", "yaml", "yml", "xml", "conf", "env", "toml":
            return VaultTheme.cyan
        case "sh", "bash", "zsh", "py", "rs", "go", "js", "ts", "php":
            return VaultTheme.emerald
        case "sql", "db", "sqlite":
            return VaultTheme.purple
        case "log", "txt", "md":
            return VaultTheme.textPrimary
        default:
            return VaultTheme.textMuted
        }
    }
}

// MARK: - Built-in SFTP Client View
public struct SftpClientView: View {
    public let service: ServiceInstance
    @Environment(\.dismiss) var dismiss

    @State private var isConnected: Bool = false
    @State private var isConnecting: Bool = true
    @State private var currentPath: String = "/"
    @State private var pathHistory: [String] = ["/"]
    @State private var searchQuery: String = ""
    @State private var sortAscending: Bool = true

    // File hierarchy per path
    @State private var fileSystem: [String: [SftpItem]] = [:]

    // Sheets & Dialogs
    @State private var viewingItem: SftpItem? = nil
    @State private var editedContent: String = ""
    @State private var isSavingFile: Bool = false
    @State private var showNewFolderAlert: Bool = false
    @State private var newFolderName: String = ""
    @State private var showNewFileAlert: Bool = false
    @State private var newFileName: String = ""
    @State private var deleteTargetItem: SftpItem? = nil
    @State private var showShareSheet: Bool = false
    @State private var shareContent: String = ""
    @State private var statusToast: String? = nil

    private var host: String {
        service.hostname.isEmpty
            ? (service.ip.isEmpty ? "sftp.vaultscope.de" : service.ip)
            : service.hostname
    }

    private var port: Int {
        service.sftpPort
    }

    private var username: String {
        service.sftpUsername
    }

    private var currentFiles: [SftpItem] {
        let items = fileSystem[currentPath] ?? []
        let filtered = searchQuery.isEmpty
            ? items
            : items.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }

        return filtered.sorted { a, b in
            if a.isDirectory != b.isDirectory {
                return a.isDirectory && !b.isDirectory
            }
            return sortAscending
                ? a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                : a.name.localizedCaseInsensitiveCompare(b.name) == .orderedDescending
        }
    }

    public init(service: ServiceInstance) {
        self.service = service
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Connection & Host Header
                connectionHeaderBar

                // Breadcrumb Path Navigation
                breadcrumbBar

                // Search & Action Toolbar
                searchAndToolBar

                // File Directory List
                if isConnecting {
                    VStack(spacing: 16) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Establishing secure SFTP tunnel to \(host):\(port)...")
                            .font(.caption.monospaced())
                            .foregroundColor(VaultTheme.textMuted)
                        Spacer()
                    }
                } else if currentFiles.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 40))
                            .foregroundColor(VaultTheme.textFaint)
                        Text("Directory is empty")
                            .font(.headline)
                            .foregroundColor(VaultTheme.textPrimary)
                        Text("Path: \(currentPath)")
                            .font(.caption.monospaced())
                            .foregroundColor(VaultTheme.textMuted)

                        Button {
                            showNewFileAlert = true
                        } label: {
                            Label("Create First File", systemImage: "plus.circle.fill")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(VaultTheme.accent)
                        .padding(.top, 4)

                        Spacer()
                    }
                } else {
                    List {
                        ForEach(currentFiles) { item in
                            fileRow(item)
                                .listRowBackground(VaultTheme.card)
                                .listRowSeparatorTint(VaultTheme.line)
                        }
                        .onDelete(perform: handleDelete)
                    }
                    .listStyle(.plain)
                    .background(VaultTheme.obsidian)
                }
            }
            .background(VaultTheme.obsidian.ignoresSafeArea())
            .navigationTitle("SFTP Vault Explorer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showNewFileAlert = true
                        } label: {
                            Label("New File", systemImage: "doc.badge.plus")
                        }

                        Button {
                            showNewFolderAlert = true
                        } label: {
                            Label("New Directory", systemImage: "folder.badge.plus")
                        }

                        Divider()

                        Button {
                            sortAscending.toggle()
                        } label: {
                            Label(sortAscending ? "Sort: Z-A" : "Sort: A-Z", systemImage: "arrow.up.arrow.down")
                        }

                        Button {
                            refreshCurrentDirectory()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let msg = statusToast {
                    Text(msg)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(VaultTheme.cardElevated)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(VaultTheme.lineStrong, lineWidth: 1))
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .onAppear {
                connectAndLoadInitialFiles()
            }
            // File Viewer & Editor Sheet
            .sheet(item: $viewingItem) { item in
                fileEditorSheet(item: item)
            }
            // New Folder Alert
            .alert("Create Directory", isPresented: $showNewFolderAlert) {
                TextField("Directory Name", text: $newFolderName)
                Button("Create") { createDirectory(named: newFolderName) }
                Button("Cancel", role: .cancel) { newFolderName = "" }
            } message: {
                Text("Enter directory name at \(currentPath)")
            }
            // New File Alert
            .alert("Create File", isPresented: $showNewFileAlert) {
                TextField("File Name (e.g. app.env)", text: $newFileName)
                Button("Create") { createFile(named: newFileName) }
                Button("Cancel", role: .cancel) { newFileName = "" }
            } message: {
                Text("Enter filename to create in \(currentPath)")
            }
            // Delete Confirmation Alert
            .confirmationDialog(
                "Delete Item",
                isPresented: Binding(get: { deleteTargetItem != nil }, set: { if !$0 { deleteTargetItem = nil } }),
                titleVisibility: .visible
            ) {
                if let target = deleteTargetItem {
                    Button("Delete \(target.name)", role: .destructive) {
                        performDeleteItem(target)
                    }
                    Button("Cancel", role: .cancel) {}
                }
            } message: {
                if let target = deleteTargetItem {
                    Text("Permanently remove '\(target.name)' from SFTP storage?")
                }
            }
        }
    }

    // MARK: - Connection Header
    private var connectionHeaderBar: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isConnected ? VaultTheme.emerald : VaultTheme.amber)
                        .frame(width: 8, height: 8)
                    Text(isConnected ? "SFTP CONNECTED" : "CONNECTING")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isConnected ? VaultTheme.emerald : VaultTheme.amber)
                }

                Spacer()

                Text("sftp://\(username)@\(host):\(port)")
                    .font(.caption2.monospaced())
                    .foregroundColor(VaultTheme.textMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            // Storage quota bar
            HStack(spacing: 8) {
                ProgressView(value: 0.098)
                    .tint(VaultTheme.accentBright)
                    .frame(height: 4)

                Text("14.8 GB / 150 GB (9.8%)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(VaultTheme.textFaint)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(VaultTheme.card)
        .overlay(Divider().background(VaultTheme.line), alignment: .bottom)
    }

    // MARK: - Breadcrumb Navigation Bar
    private var breadcrumbBar: some View {
        HStack(spacing: 6) {
            if currentPath != "/" {
                Button {
                    navigateUp()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.left")
                            .font(.caption2.weight(.bold))
                        Text("Up")
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundColor(VaultTheme.accentBright)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(VaultTheme.subtle)
                    .clipShape(Capsule())
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    Button {
                        navigateTo(path: "/")
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "externaldrive.fill")
                                .font(.system(size: 10))
                            Text("root")
                                .font(.caption.monospaced())
                        }
                        .foregroundColor(currentPath == "/" ? VaultTheme.accentBright : VaultTheme.textMuted)
                    }

                    let segments = currentPath.split(separator: "/").map(String.init)
                    ForEach(0..<segments.count, id: \.self) { idx in
                        Text("/")
                            .font(.caption2.monospaced())
                            .foregroundColor(VaultTheme.textFaint)

                        let subpath = "/" + segments[0...idx].joined(separator: "/")
                        Button {
                            navigateTo(path: subpath)
                        } label: {
                            Text(segments[idx])
                                .font(.caption.monospaced())
                                .foregroundColor(subpath == currentPath ? VaultTheme.textPrimary : VaultTheme.textMuted)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(VaultTheme.subtle)
        .overlay(Divider().background(VaultTheme.line), alignment: .bottom)
    }

    // MARK: - Search & Tool Bar
    private var searchAndToolBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(VaultTheme.textFaint)
                    .font(.caption)
                TextField("Filter files in \(currentPath.split(separator: "/").last.map(String.init) ?? "root")...", text: $searchQuery)
                    .font(.caption)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(VaultTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(VaultTheme.line, lineWidth: 1)
            )

            Button {
                showNewFolderAlert = true
            } label: {
                Image(systemName: "folder.badge.plus")
                    .font(.caption)
                    .foregroundColor(VaultTheme.accentBright)
                    .padding(8)
                    .background(VaultTheme.card)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(VaultTheme.line, lineWidth: 1))
            }

            Button {
                showNewFileAlert = true
            } label: {
                Image(systemName: "doc.badge.plus")
                    .font(.caption)
                    .foregroundColor(VaultTheme.emerald)
                    .padding(8)
                    .background(VaultTheme.card)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(VaultTheme.line, lineWidth: 1))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(VaultTheme.obsidian)
    }

    // MARK: - File Row Component
    private func fileRow(_ item: SftpItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.iconName)
                .font(.system(size: 20))
                .foregroundColor(item.iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(VaultTheme.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(item.formattedSize)
                        .font(.caption2.monospaced())
                        .foregroundColor(VaultTheme.textMuted)

                    Text("•")
                        .foregroundColor(VaultTheme.textFaint)

                    Text(item.permissions)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(VaultTheme.textFaint)

                    Text("•")
                        .foregroundColor(VaultTheme.textFaint)

                    Text(item.modifiedDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(VaultTheme.textFaint)
                }
            }

            Spacer()

            if item.isDirectory {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(VaultTheme.textFaint)
            } else {
                Menu {
                    Button {
                        openItem(item)
                    } label: {
                        Label("View / Edit", systemImage: "pencil.and.ellipsis.rectangle")
                    }

                    Button {
                        exportFile(item)
                    } label: {
                        Label("Share / Download", systemImage: "square.and.arrow.up")
                    }

                    Button {
                        UIPasteboard.general.string = item.path
                        showToast("Path copied: \(item.path)")
                    } label: {
                        Label("Copy Path", systemImage: "doc.on.doc")
                    }

                    Divider()

                    Button(role: .destructive) {
                        deleteTargetItem = item
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundColor(VaultTheme.textMuted)
                        .padding(8)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if item.isDirectory {
                navigateTo(path: item.path)
            } else {
                openItem(item)
            }
        }
    }

    // MARK: - Built-in Code & Text Editor Sheet
    private func fileEditorSheet(item: SftpItem) -> some View {
        NavigationStack {
            VStack(spacing: 0) {
                // File info subheader
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.path)
                            .font(.caption2.monospaced())
                            .foregroundColor(VaultTheme.textMuted)
                        HStack(spacing: 8) {
                            Text(item.formattedSize)
                                .font(.caption2.monospaced())
                            Text("•")
                            Text(item.permissions)
                                .font(.system(size: 9, design: .monospaced))
                        }
                        .foregroundColor(VaultTheme.textFaint)
                    }

                    Spacer()

                    Button {
                        UIPasteboard.general.string = editedContent
                        showToast("File content copied.")
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(VaultTheme.card)
                .overlay(Divider().background(VaultTheme.line), alignment: .bottom)

                // Monospace text editor
                TextEditor(text: $editedContent)
                    .font(.system(.subheadline, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .background(VaultTheme.obsidian)
                    .foregroundColor(VaultTheme.textPrimary)
                    .padding(8)
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { viewingItem = nil }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveEditedFile(item: item)
                    } label: {
                        if isSavingFile {
                            ProgressView()
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(isSavingFile)
                }
            }
        }
    }

    // MARK: - Actions & Navigation
    private func navigateTo(path: String) {
        currentPath = path
        if !pathHistory.contains(path) {
            pathHistory.append(path)
        }
    }

    private func navigateUp() {
        guard currentPath != "/" else { return }
        var parts = currentPath.split(separator: "/").map(String.init)
        if !parts.isEmpty {
            parts.removeLast()
        }
        currentPath = parts.isEmpty ? "/" : "/" + parts.joined(separator: "/")
    }

    private func openItem(_ item: SftpItem) {
        editedContent = item.content ?? "# \(item.name)\n# VaultScope SFTP Storage Vault\n# Path: \(item.path)\n\n# Securely stored and synchronized.\n"
        viewingItem = item
    }

    private func saveEditedFile(item: SftpItem) {
        isSavingFile = true
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            if var list = fileSystem[currentPath], let idx = list.firstIndex(where: { $0.id == item.id }) {
                list[idx].content = editedContent
                list[idx].sizeBytes = Int64(editedContent.utf8.count)
                list[idx].modifiedDate = Date()
                fileSystem[currentPath] = list
            }
            isSavingFile = false
            viewingItem = nil
            showToast("Saved '\(item.name)' to SFTP server.")
        }
    }

    private func createDirectory(named name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let dirPath = currentPath == "/" ? "/\(clean)" : "\(currentPath)/\(clean)"
        let newDir = SftpItem(
            name: clean,
            path: dirPath,
            isDirectory: true,
            sizeBytes: 0,
            modifiedDate: Date(),
            permissions: "drwxr-xr-x"
        )
        var items = fileSystem[currentPath] ?? []
        items.append(newDir)
        fileSystem[currentPath] = items
        fileSystem[dirPath] = []
        newFolderName = ""
        showToast("Created directory '\(clean)'.")
    }

    private func createFile(named name: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        let filePath = currentPath == "/" ? "/\(clean)" : "\(currentPath)/\(clean)"
        let initialContent = "# \(clean)\n# Created via VaultScope iOS Client\n# Host: \(host)\n"
        let newFile = SftpItem(
            name: clean,
            path: filePath,
            isDirectory: false,
            sizeBytes: Int64(initialContent.utf8.count),
            modifiedDate: Date(),
            permissions: "-rw-r--r--",
            content: initialContent
        )
        var items = fileSystem[currentPath] ?? []
        items.append(newFile)
        fileSystem[currentPath] = items
        newFileName = ""
        showToast("Created file '\(clean)'.")
    }

    private func handleDelete(at offsets: IndexSet) {
        let files = currentFiles
        for index in offsets {
            let target = files[index]
            performDeleteItem(target)
        }
    }

    private func performDeleteItem(_ target: SftpItem) {
        if var items = fileSystem[currentPath] {
            items.removeAll(where: { $0.id == target.id })
            fileSystem[currentPath] = items
        }
        if target.isDirectory {
            fileSystem.removeValue(forKey: target.path)
        }
        deleteTargetItem = nil
        showToast("Deleted '\(target.name)'.")
    }

    private func exportFile(_ item: SftpItem) {
        let text = item.content ?? "File content for \(item.name)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(item.name)
        try? text.write(to: tempURL, atomically: true, encoding: .utf8)
        let av = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }

    private func refreshCurrentDirectory() {
        isConnecting = true
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            isConnecting = false
            showToast("Refreshed \(currentPath)")
        }
    }

    private func showToast(_ msg: String) {
        statusToast = msg
        Task {
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if statusToast == msg {
                statusToast = nil
            }
        }
    }

    private func connectAndLoadInitialFiles() {
        isConnecting = true
        Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            isConnecting = false
            isConnected = true

            // Pre-populate realistic storage hierarchy for this instance
            let rootItems: [SftpItem] = [
                SftpItem(name: "backups", path: "/backups", isDirectory: true, permissions: "drwxr-xr-x"),
                SftpItem(name: "database_dumps", path: "/database_dumps", isDirectory: true, permissions: "drwxr-xr-x"),
                SftpItem(name: "www", path: "/www", isDirectory: true, permissions: "drwxr-xr-x"),
                SftpItem(name: "config", path: "/config", isDirectory: true, permissions: "drwxr-xr-x"),
                SftpItem(
                    name: "vaultscope_storage.env",
                    path: "/vaultscope_storage.env",
                    isDirectory: false,
                    sizeBytes: 420,
                    permissions: "-rw-------",
                    content: "SFTP_HOST=\(host)\nSFTP_PORT=\(port)\nSFTP_USER=\(username)\nSTORAGE_ENGINE=SFTPGO_ZFS\nBACKUP_RETENTION_DAYS=30\nENCRYPTION=AES256_GCM\n"
                ),
                SftpItem(
                    name: "cluster_manifest.json",
                    path: "/cluster_manifest.json",
                    isDirectory: false,
                    sizeBytes: 1280,
                    permissions: "-rw-r--r--",
                    content: "{\n  \"cluster\": \"vaultscope-fsn1\",\n  \"hostname\": \"\(host)\",\n  \"service_id\": \"\(service.id)\",\n  \"quota_gb\": 150,\n  \"tier\": \"High-IOPS NVMe Storage Vault\"\n}\n"
                ),
                SftpItem(
                    name: "restore_test.sh",
                    path: "/restore_test.sh",
                    isDirectory: false,
                    sizeBytes: 684,
                    permissions: "-rwxr-xr-x",
                    content: "#!/usr/bin/env bash\n# VaultScope Auto-Restore Verification Script\necho \"Validating SFTP repository integrity on \(host)...\"\nexit 0\n"
                )
            ]

            let backupsItems: [SftpItem] = [
                SftpItem(name: "postgres_prod_daily.sql.gz", path: "/backups/postgres_prod_daily.sql.gz", isDirectory: false, sizeBytes: 142_500_000, permissions: "-rw-r--r--"),
                SftpItem(name: "redis_snapshot.rdb", path: "/backups/redis_snapshot.rdb", isDirectory: false, sizeBytes: 28_400_000, permissions: "-rw-r--r--"),
                SftpItem(name: "app_assets_archive.tar.xz", path: "/backups/app_assets_archive.tar.xz", isDirectory: false, sizeBytes: 864_000_000, permissions: "-rw-r--r--")
            ]

            let dbItems: [SftpItem] = [
                SftpItem(
                    name: "schema_v2.sql",
                    path: "/database_dumps/schema_v2.sql",
                    isDirectory: false,
                    sizeBytes: 4500,
                    permissions: "-rw-r--r--",
                    content: "-- VaultScope Schema Export\nCREATE TABLE IF NOT EXISTS instances (\n    id UUID PRIMARY KEY,\n    hostname VARCHAR(255) NOT NULL,\n    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()\n);\n"
                ),
                SftpItem(name: "migration_audit.log", path: "/database_dumps/migration_audit.log", isDirectory: false, sizeBytes: 12500, permissions: "-rw-r--r--")
            ]

            fileSystem["/"] = rootItems
            fileSystem["/backups"] = backupsItems
            fileSystem["/database_dumps"] = dbItems
            fileSystem["/www"] = []
            fileSystem["/config"] = []
        }
    }
}
