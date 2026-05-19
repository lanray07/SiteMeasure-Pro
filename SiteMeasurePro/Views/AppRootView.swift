import SwiftUI

struct AppRootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                AppShellView()
            } else {
                OnboardingView()
            }
        }
    }
}

struct AppShellView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("Dashboard", systemImage: "gauge.with.dots.needle.bottom.50percent")
            }

            NavigationStack {
                ProjectsListView()
            }
            .tabItem {
                Label("Projects", systemImage: "folder")
            }

            NavigationStack {
                CalculatorHubView()
            }
            .tabItem {
                Label("Calculators", systemImage: "function")
            }

            NavigationStack {
                ProposalListView()
            }
            .tabItem {
                Label("Proposals", systemImage: "doc.richtext")
            }

            NavigationStack {
                AccountView()
            }
            .tabItem {
                Label("Account", systemImage: "person.crop.circle")
            }
        }
        .tint(.green)
    }
}

struct CalculatorHubView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    MaterialCalculatorView(project: nil)
                } label: {
                    Label("Material Calculator", systemImage: "shippingbox")
                }

                NavigationLink {
                    LaborCalculatorView(project: nil)
                } label: {
                    Label("Labor Calculator", systemImage: "person.2")
                }
            } footer: {
                Text("Standalone estimates are not saved unless opened from a project.")
            }
        }
        .navigationTitle("Calculators")
    }
}
