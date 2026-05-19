import SwiftData
import SwiftUI

struct ProposalListView: View {
    @Query(sort: \Proposal.createdAt, order: .reverse) private var proposals: [Proposal]
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @State private var shareItem: ShareItem?

    var body: some View {
        List {
            if proposals.isEmpty {
                EmptyStateView(
                    title: "No saved proposals",
                    message: "Open a project and generate a PDF proposal when your estimate is ready.",
                    systemImage: "doc.badge.plus"
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

                if !projects.isEmpty {
                    Section("Generate From Project") {
                        ForEach(projects) { project in
                            NavigationLink {
                                ProposalGeneratorView(project: project)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(project.title)
                                    Text(project.clientName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            } else {
                Section {
                    ForEach(proposals) { proposal in
                        ProposalCard(proposal: proposal) {
                            if let path = proposal.pdfLocalURL {
                                shareItem = ShareItem(url: URL(fileURLWithPath: path))
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Generate Another") {
                    ForEach(projects) { project in
                        NavigationLink {
                            ProposalGeneratorView(project: project)
                        } label: {
                            Label(project.title, systemImage: "doc.badge.plus")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Proposals")
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
    }
}
