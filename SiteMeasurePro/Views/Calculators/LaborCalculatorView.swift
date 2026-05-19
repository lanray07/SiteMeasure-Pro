import SwiftData
import SwiftUI

struct LaborCalculatorView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = LaborCalculatorViewModel()
    @State private var saved = false

    let project: Project?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Labor Calculator")
                        .font(.largeTitle.weight(.bold))
                    Text(project?.title ?? "Standalone labor estimate")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    MetricField(title: "Estimated hours", suffix: "hrs", value: $viewModel.hours)

                    Stepper(value: $viewModel.crewSize, in: 1...20) {
                        HStack {
                            Text("Crew size")
                            Spacer()
                            Text("\(viewModel.crewSize)")
                                .fontWeight(.semibold)
                        }
                    }

                    MetricField(title: "Labor rate", suffix: "£/hr", value: $viewModel.laborRate)
                    MetricField(title: "Equipment cost", suffix: "£", value: $viewModel.equipmentCost)
                    MetricField(title: "Travel cost", suffix: "£", value: $viewModel.travelCost)

                    VStack(alignment: .leading) {
                        HStack {
                            Text("Profit margin")
                            Spacer()
                            Text(AppFormatters.percent(viewModel.profitMargin))
                                .fontWeight(.semibold)
                        }
                        Slider(value: $viewModel.profitMargin, in: 0...0.7, step: 0.05)
                    }
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                )

                EstimateSummaryView(materialTotal: 0, laborTotal: viewModel.totalCost)

                VStack(alignment: .leading, spacing: 10) {
                    summaryRow("Labor subtotal", value: viewModel.laborSubtotal)
                    summaryRow("Equipment", value: viewModel.equipmentCost)
                    summaryRow("Travel", value: viewModel.travelCost)
                    summaryRow("Before margin", value: viewModel.costBeforeMargin)
                    summaryRow("Total with margin", value: viewModel.totalCost, isStrong: true)
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.quaternary, lineWidth: 1)
                )

                if let project {
                    Button {
                        if viewModel.save(project: project, in: modelContext) {
                            saved = true
                        }
                    } label: {
                        Label("Save Labor Estimate", systemImage: "tray.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Labor")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Labor Calculator", isPresented: Binding(
            get: { viewModel.errorMessage != nil || saved },
            set: {
                if !$0 {
                    viewModel.errorMessage = nil
                    saved = false
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saved ? "Labor estimate saved to project." : viewModel.errorMessage ?? "")
        }
    }

    private func summaryRow(_ title: String, value: Double, isStrong: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(isStrong ? .primary : .secondary)
            Spacer()
            Text(AppFormatters.currency(value))
                .fontWeight(isStrong ? .bold : .semibold)
        }
        .font(isStrong ? .headline : .subheadline)
    }
}
