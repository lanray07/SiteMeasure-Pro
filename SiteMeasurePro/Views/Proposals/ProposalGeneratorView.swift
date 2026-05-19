import SwiftData
import SwiftUI

struct ProposalGeneratorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.aiService) private var aiService
    @Environment(SubscriptionStore.self) private var subscriptionStore

    let project: Project

    @Query(sort: \Measurement.createdAt, order: .reverse) private var allMeasurements: [Measurement]
    @Query(sort: \MaterialEstimate.createdAt, order: .reverse) private var allMaterials: [MaterialEstimate]
    @Query(sort: \LaborEstimate.createdAt, order: .reverse) private var allLabor: [LaborEstimate]

    @State private var businessName = "Your Business Name"
    @State private var proposalTitle = "Project Proposal"
    @State private var summary = ""
    @State private var isGeneratingSummary = false
    @State private var isGeneratingPDF = false
    @State private var errorMessage: String?
    @State private var shareItem: ShareItem?

    private var measurements: [Measurement] {
        allMeasurements.filter { $0.projectId == project.id }
    }

    private var materials: [MaterialEstimate] {
        allMaterials.filter { $0.projectId == project.id }
    }

    private var labor: LaborEstimate? {
        allLabor.first { $0.projectId == project.id }
    }

    private var materialTotal: Double {
        materials.reduce(0) { $0 + $1.estimatedCost }
    }

    private var laborTotal: Double {
        labor?.totalCost ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Proposal Generator")
                        .font(.largeTitle.weight(.bold))
                    Text(project.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !subscriptionStore.hasActiveSubscription {
                    NavigationLink {
                        PaywallView()
                    } label: {
                        UpgradeBanner(plan: subscriptionStore.currentPlan)
                    }
                    .buttonStyle(.plain)
                }

                FormCard {
                    TextField("Business details", text: $businessName)
                    TextField("Proposal title", text: $proposalTitle)
                    TextField("Proposal summary", text: $summary, axis: .vertical)
                        .lineLimit(5...10)
                }

                EstimateSummaryView(materialTotal: materialTotal, laborTotal: laborTotal)

                HStack(spacing: 12) {
                    PrimaryActionButton(title: "Draft Summary", systemImage: "sparkles", isLoading: isGeneratingSummary) {
                        Task { await generateSummary() }
                    }

                    PrimaryActionButton(title: "Export PDF", systemImage: "doc.richtext", isLoading: isGeneratingPDF) {
                        generatePDF()
                    }
                }

                proposalPreview
                DisclaimerListView()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Proposal")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
        .alert("Proposal Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            if summary.isEmpty {
                summary = "Proposal for \(project.clientName) covering \(project.projectType.lowercased()) works at \(project.propertyAddress)."
            }
        }
    }

    private var proposalPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PDF Sections")
                .font(.title3.weight(.bold))

            ForEach([
                "Business details",
                "Client details",
                "Project overview",
                "Measurements",
                "Materials",
                "Labor",
                "Estimated pricing",
                "Exclusions",
                "Timeline",
                "Terms and disclaimer",
                "Signature placeholder"
            ], id: \.self) { section in
                Label(section, systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }

    private func generateSummary() async {
        isGeneratingSummary = true
        defer { isGeneratingSummary = false }

        do {
            summary = try await aiService.generateProposalSummary(
                project: project,
                measurements: measurements,
                materials: materials,
                labor: labor
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func generatePDF() {
        guard subscriptionStore.hasActiveSubscription else {
            errorMessage = "Proposal PDF export requires a Pro or Business subscription."
            return
        }

        isGeneratingPDF = true
        defer { isGeneratingPDF = false }

        do {
            let service = PDFProposalService()
            let url = try service.generateProposal(
                input: ProposalPDFInput(
                    project: project,
                    measurements: measurements,
                    materials: materials,
                    labor: labor,
                    summary: summary,
                    businessName: businessName
                )
            )

            let proposal = Proposal(
                projectId: project.id,
                title: proposalTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Project Proposal" : proposalTitle,
                summary: summary,
                pdfLocalURL: url.path,
                estimatedTotal: materialTotal + laborTotal
            )
            modelContext.insert(proposal)
            project.status = ProjectStatus.quoted.rawValue
            project.updatedAt = .now
            try modelContext.save()
            shareItem = ShareItem(url: url)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct FormCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .textFieldStyle(.roundedBorder)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}
