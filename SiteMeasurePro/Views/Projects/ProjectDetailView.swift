import SwiftData
import SwiftUI

struct ProjectDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var project: Project

    @Query(sort: \SitePhoto.createdAt, order: .reverse) private var allPhotos: [SitePhoto]
    @Query(sort: \Measurement.createdAt, order: .reverse) private var allMeasurements: [Measurement]
    @Query(sort: \MaterialEstimate.createdAt, order: .reverse) private var allMaterials: [MaterialEstimate]
    @Query(sort: \LaborEstimate.createdAt, order: .reverse) private var allLabor: [LaborEstimate]
    @Query(sort: \Proposal.createdAt, order: .reverse) private var allProposals: [Proposal]

    private var photos: [SitePhoto] {
        allPhotos.filter { $0.projectId == project.id }
    }

    private var measurements: [Measurement] {
        allMeasurements.filter { $0.projectId == project.id }
    }

    private var materials: [MaterialEstimate] {
        allMaterials.filter { $0.projectId == project.id }
    }

    private var labor: [LaborEstimate] {
        allLabor.filter { $0.projectId == project.id }
    }

    private var proposals: [Proposal] {
        allProposals.filter { $0.projectId == project.id }
    }

    private var materialTotal: Double {
        materials.reduce(0) { $0 + $1.estimatedCost }
    }

    private var laborTotal: Double {
        labor.first?.totalCost ?? 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                projectHeader
                actionGrid
                EstimateSummaryView(materialTotal: materialTotal, laborTotal: laborTotal)

                contentSection("Site Photos") {
                    if photos.isEmpty {
                        EmptyStateView(title: "No photos", message: "Capture or upload site photos from the measurement workflow.", systemImage: "camera")
                    } else {
                        ForEach(photos) { photo in
                            SitePhotoCard(photo: photo)
                        }
                    }
                }

                contentSection("Measurements") {
                    if measurements.isEmpty {
                        EmptyStateView(title: "No measurements", message: "Mark points on a site photo and run a mock AI estimate.", systemImage: "ruler")
                    } else {
                        ForEach(measurements) { measurement in
                            NavigationLink {
                                MeasurementEditView(measurement: measurement)
                            } label: {
                                MeasurementCard(measurement: measurement)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                contentSection("Materials") {
                    if materials.isEmpty {
                        EmptyStateView(title: "No materials", message: "Generate AI material estimates or use the calculator.", systemImage: "shippingbox")
                    } else {
                        ForEach(materials.prefix(5)) { material in
                            MaterialCard(material: material)
                        }
                    }
                }

                contentSection("Proposals") {
                    if proposals.isEmpty {
                        EmptyStateView(title: "No proposals", message: "Generate a client-ready PDF proposal when your estimate is ready.", systemImage: "doc.richtext")
                    } else {
                        ForEach(proposals) { proposal in
                            ProposalCard(proposal: proposal)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(project.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(ProjectStatus.allCases) { status in
                        Button(status.rawValue) {
                            project.status = status.rawValue
                            project.updatedAt = .now
                            try? modelContext.save()
                        }
                    }
                } label: {
                    Label("Status", systemImage: "tag")
                }
            }
        }
    }

    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.title)
                        .font(.largeTitle.weight(.bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(project.clientName)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: project.statusValue)
            }

            if !project.propertyAddress.isEmpty {
                Label(project.propertyAddress, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !project.notes.isEmpty {
                Text(project.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            NavigationLink {
                MeasurementWorkspaceView(project: project)
            } label: {
                actionTile("Measure", icon: "camera.viewfinder", tint: .green)
            }

            NavigationLink {
                MaterialCalculatorView(project: project)
            } label: {
                actionTile("Materials", icon: "shippingbox", tint: .orange)
            }

            NavigationLink {
                LaborCalculatorView(project: project)
            } label: {
                actionTile("Labor", icon: "person.2", tint: .blue)
            }

            NavigationLink {
                ProposalGeneratorView(project: project)
            } label: {
                actionTile("Proposal", icon: "doc.badge.plus", tint: .teal)
            }
        }
        .buttonStyle(.plain)
    }

    private func actionTile(_ title: String, icon: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(tint)
            Text(title)
                .font(.headline)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }

    private func contentSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.bold))
            content()
        }
    }
}
