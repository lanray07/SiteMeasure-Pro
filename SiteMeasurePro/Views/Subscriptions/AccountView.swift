import SwiftUI

struct AccountView: View {
    @Environment(AppState.self) private var appState
    @Environment(SubscriptionStore.self) private var subscriptionStore

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SiteMeasure Pro")
                        .font(.title2.weight(.bold))
                    Text("Premium contractor SaaS tools for outdoor measurements, estimates, and proposals.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }

            Section("Subscription") {
                HStack {
                    Label("Current plan", systemImage: "sparkles")
                    Spacer()
                    Text(subscriptionStore.currentPlan.rawValue)
                        .fontWeight(.semibold)
                }

                NavigationLink {
                    PaywallView()
                } label: {
                    Label("Manage Plan", systemImage: "creditcard")
                }
            }

            Section("AI and Privacy") {
                Label("Mock AI enabled by default", systemImage: "checkmark.shield")
                Label("Remote endpoint placeholder configured", systemImage: "network")
                Label("No API keys stored in the app", systemImage: "lock")
            }

            Section("Legal") {
                Link(destination: AppConstants.Legal.termsOfUseURL) {
                    Label("Terms of Use (EULA)", systemImage: "doc.text")
                }
                Link(destination: AppConstants.Legal.privacyPolicyURL) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
            }

            Section("Review Disclaimers") {
                ForEach(AppConstants.disclaimers, id: \.self) { disclaimer in
                    Text(disclaimer)
                }
            }

            Section {
                Button(role: .destructive) {
                    appState.resetOnboarding()
                } label: {
                    Label("Reset Onboarding", systemImage: "arrow.counterclockwise")
                }
            }
        }
        .navigationTitle("Account")
    }
}
