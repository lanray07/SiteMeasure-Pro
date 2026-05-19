import SwiftData
import SwiftUI

struct ProjectsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt, order: .reverse) private var projects: [Project]
    @State private var searchText = ""
    @State private var statusFilter: ProjectStatus?
    @State private var dateFilter: ProjectDateFilter = .all

    private var filteredProjects: [Project] {
        projects.filter { project in
            let matchesSearch = searchText.isEmpty ||
            project.title.localizedCaseInsensitiveContains(searchText) ||
            project.clientName.localizedCaseInsensitiveContains(searchText) ||
            project.propertyAddress.localizedCaseInsensitiveContains(searchText)

            let matchesStatus = statusFilter == nil || project.statusValue == statusFilter
            let matchesDate = dateFilter.contains(project.createdAt)
            return matchesSearch && matchesStatus && matchesDate
        }
    }

    var body: some View {
        List {
            if projects.isEmpty {
                EmptyStateView(
                    title: "No saved projects",
                    message: "Create a project to start capturing photos and measurements.",
                    systemImage: "folder.badge.plus",
                    assetName: "EmptyProjects"
                )
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } else {
                Section {
                    Picker("Status", selection: $statusFilter) {
                        Text("All").tag(nil as ProjectStatus?)
                        ForEach(ProjectStatus.allCases) { status in
                            Text(status.rawValue).tag(ProjectStatus?.some(status))
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Date", selection: $dateFilter) {
                        ForEach(ProjectDateFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    ForEach(filteredProjects) { project in
                        NavigationLink {
                            ProjectDetailView(project: project)
                        } label: {
                            ProjectCard(project: project)
                                .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                duplicate(project)
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Saved Projects")
        .searchable(text: $searchText, prompt: "Search projects")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    ProjectFormView()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New Project")
            }
        }
    }

    private func duplicate(_ project: Project) {
        let copy = Project(
            title: "\(project.title) Copy",
            clientName: project.clientName,
            propertyAddress: project.propertyAddress,
            projectType: project.projectTypeValue,
            notes: project.notes,
            status: .draft,
            targetCompletionDate: project.targetCompletionDate
        )
        modelContext.insert(copy)
        try? modelContext.save()
    }
}

private enum ProjectDateFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case last7Days = "7 days"
    case last30Days = "30 days"

    var id: String { rawValue }

    func contains(_ date: Date) -> Bool {
        switch self {
        case .all:
            return true
        case .last7Days:
            return date >= Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        case .last30Days:
            return date >= Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .distantPast
        }
    }
}
