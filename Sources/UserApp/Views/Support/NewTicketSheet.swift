import SwiftUI

public struct NewTicketSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var subject: String = ""
    @State private var selectedCategory: String = "Technical Support"
    @State private var selectedPriority: TicketPriority = .normal
    @State private var selectedServiceId: UUID? = nil
    @State private var messageText: String = ""
    @State private var isSubmitting: Bool = false

    private let categories = [
        "Technical Support",
        "Abuse & Security",
        "DMCA & Legal"
    ]

    public init() {}

    public var body: some View {
        NavigationStack {
            Form {
                Section("Classification") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }

                    Picker("Priority", selection: $selectedPriority) {
                        Text("Normal").tag(TicketPriority.normal)
                        Text("High").tag(TicketPriority.high)
                        Text("Critical").tag(TicketPriority.critical)
                    }

                    if !appState.services.isEmpty {
                        Picker("Related Service", selection: $selectedServiceId) {
                            Text("None").tag(nil as UUID?)
                            ForEach(appState.services) { srv in
                                Text("\(srv.hostname) (\(srv.name))").tag(srv.id as UUID?)
                            }
                        }
                    }
                }

                Section("Issue Details") {
                    TextField("Subject summary", text: $subject)

                    TextEditor(text: $messageText)
                        .frame(minHeight: 120)
                }

                Section {
                    Button {
                        submitTicket()
                    } label: {
                        if isSubmitting {
                            HStack {
                                Spacer()
                                ProgressView()
                                Text("Submitting...")
                                Spacer()
                            }
                        } else {
                            Text("Submit Support Ticket")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(VaultTheme.cyan)
                    .disabled(subject.isEmpty || messageText.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("New Ticket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }

    private func submitTicket() {
        isSubmitting = true
        appState.createTicket(
            subject: subject,
            category: selectedCategory,
            priority: selectedPriority,
            relatedServiceId: selectedServiceId,
            initialMessage: messageText
        )
        dismiss()
    }
}
