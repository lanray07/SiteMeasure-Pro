import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(SubscriptionStore.self) private var subscriptionStore
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @Query(sort: \MaterialEstimate.createdAt, order: .reverse) private var materials: [MaterialEstimate]
    @Query(sort: \LaborEstimate.createdAt, order: .reverse) private var laborEstimates: [LaborEstimate]
    @Query(sort: \Proposal.createdAt, order: .reverse) private var proposals: [Proposal]

    private var pendingProjects: [Project] {
        projects.filter { $0.statusValue == .pendingQuote || $0.statusValue == .draft }
    }

    private var estimatedRevenue: Double {
        let materialTotal = materials.reduce(0) { $0 + $1.estimatedCost }
        let laborTotal = laborEstimates.reduce(0) { $0 + $1.totalCost }
        return materialTotal + laborTotal
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                NavigationLink {
                    PaywallView()
                } label: {
                    UpgradeBanner(plan: subscriptionStore.currentPlan)
                }
                .buttonStyle(.plain)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatTile(title: "Recent Projects", value: "\(projects.count)", icon: "folder", tint: .green)
                    StatTile(title: "Pending Quotes", value: "\(pendingProjects.count)", icon: "clock", tint: .orange)
                    StatTile(title: "Saved Proposals", value: "\(proposals.count)", icon: "doc.richtext", tint: .blue)
                    StatTile(title: "Estimated Revenue", value: AppFormatters.currency(estimatedRevenue), icon: "sterlingsign.circle", tint: .teal)
                }

                quickActions

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Projects")
                            .font(.title3.weight(.bold))
                        Spacer()
                        NavigationLink("View All") {
                            ProjectsListView()
                        }
                        .font(.subheadline.weight(.semibold))
                    }

                    if projects.isEmpty {
                        EmptyStateView(
                            title: "No projects yet",
                            message: "Create your first project to capture photos, estimate measurements, and build a proposal.",
                            systemImage: "folder.badge.plus",
                            assetName: "EmptyProjects"
                        )
                    } else {
                        ForEach(projects.prefix(3)) { project in
                            NavigationLink {
                                ProjectDetailView(project: project)
                            } label: {
                                ProjectCard(project: project)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("SiteMeasure Pro")
                .font(.largeTitle.weight(.bold))
            Text("Field-ready measurements, estimates, and proposals.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Subscription: \(subscriptionStore.currentPlan.rawValue)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(subscriptionStore.hasActiveSubscription ? .green : .secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.title3.weight(.bold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                NavigationLink {
                    ProjectFormView()
                } label: {
                    actionTile("New Measurement", icon: "camera.viewfinder", tint: .green)
                }

                NavigationLink {
                    ProjectFormView()
                } label: {
                    actionTile("New Estimate", icon: "plus.forwardslash.minus", tint: .blue)
                }

                NavigationLink {
                    ProposalListView()
                } label: {
                    actionTile("Generate Proposal", icon: "doc.badge.plus", tint: .teal)
                }

                NavigationLink {
                    MaterialCalculatorView(project: nil)
                } label: {
                    actionTile("Material Calculator", icon: "shippingbox", tint: .orange)
                }

                NavigationLink {
                    LaborCalculatorView(project: nil)
                } label: {
                    actionTile("Labor Calculator", icon: "person.2", tint: .purple)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func actionTile(_ title: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(title)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}
