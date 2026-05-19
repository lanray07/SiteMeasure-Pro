import SwiftData
import SwiftUI

struct ProjectFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ProjectFormViewModel()

    var body: some View {
        Form {
            Section("Project") {
                TextField("Project title", text: $viewModel.title)
                TextField("Client name", text: $viewModel.clientName)
                TextField("Property address", text: $viewModel.propertyAddress, axis: .vertical)
                    .lineLimit(2...4)

                Picker("Project type", selection: $viewModel.projectType) {
                    ForEach(ProjectType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }

                Picker("Status", selection: $viewModel.status) {
                    ForEach(ProjectStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
            }

            Section("Schedule") {
                Toggle("Set target completion date", isOn: $viewModel.includeTargetDate)
                if viewModel.includeTargetDate {
                    DatePicker("Target completion", selection: $viewModel.targetCompletionDate, displayedComponents: .date)
                }
            }

            Section("Notes") {
                TextField("Site notes, access details, client requirements", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(4...8)
            }

            Section {
                Button {
                    if viewModel.save(in: modelContext) {
                        dismiss()
                    }
                } label: {
                    Label("Create Project", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .disabled(!viewModel.canSave)
            }

            Section("AI Disclaimer") {
                DisclaimerListView()
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("New Project")
        .alert("Project Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
