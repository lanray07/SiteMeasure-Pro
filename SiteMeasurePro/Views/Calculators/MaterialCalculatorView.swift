import SwiftData
import SwiftUI

struct MaterialCalculatorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.aiService) private var aiService
    @State private var viewModel = MaterialCalculatorViewModel()
    @State private var saved = false

    let project: Project?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Material Calculator")
                        .font(.largeTitle.weight(.bold))
                    Text(project?.title ?? "Standalone estimate")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                inputCard

                PrimaryActionButton(title: "Calculate Materials", systemImage: "shippingbox", isLoading: viewModel.isLoading) {
                    Task {
                        viewModel.recalculateFromDimensions()
                        await viewModel.calculate(aiService: aiService)
                    }
                }

                if !viewModel.results.isEmpty {
                    resultsCard
                }

                DisclaimerListView()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Materials")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let project {
                viewModel.projectType = project.projectTypeValue
            }
        }
        .alert("Material Calculator", isPresented: Binding(
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
            Text(saved ? "Material estimate saved to project." : viewModel.errorMessage ?? "")
        }
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Picker("Project type", selection: $viewModel.projectType) {
                ForEach(ProjectType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.menu)
            .disabled(project != nil)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricField(title: "Width", suffix: "m", value: $viewModel.width)
                MetricField(title: "Height", suffix: "m", value: $viewModel.height)
                MetricField(title: "Area", suffix: "sq m", value: $viewModel.area)
                MetricField(title: "Perimeter", suffix: "m", value: $viewModel.perimeter)
            }

            Button {
                viewModel.recalculateFromDimensions()
            } label: {
                Label("Recalculate Area and Perimeter", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }

    private var resultsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Material Breakdown")
                    .font(.title3.weight(.bold))
                Spacer()
                Text(AppFormatters.currency(viewModel.results.reduce(0) { $0 + $1.midpointCost }))
                    .font(.headline)
            }

            ForEach(viewModel.results) { result in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(result.materialName)
                            .font(.headline)
                        Spacer()
                        Text("\(AppFormatters.number(result.quantity)) \(result.unit)")
                            .font(.subheadline.weight(.semibold))
                    }
                    Text("\(AppFormatters.currency(result.estimatedCostLow)) - \(AppFormatters.currency(result.estimatedCostHigh)) with \(AppFormatters.percent(result.wasteBuffer)) waste")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if let project {
                Button {
                    if viewModel.save(project: project, in: modelContext) {
                        saved = true
                    }
                } label: {
                    Label("Save Materials to Project", systemImage: "tray.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}
