import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionStore.self) private var subscriptionStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 42))
                        .foregroundStyle(.green)
                    Text("Upgrade SiteMeasure Pro")
                        .font(.largeTitle.weight(.bold))
                    Text("Use Apple in-app purchases for digital Pro and Business features, including exports, unlimited projects, and advanced AI estimates.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach([SubscriptionPlan.free, .proMonthly, .proYearly, .businessMonthly]) { plan in
                    planCard(plan)
                }

                Button {
                    Task { await subscriptionStore.restorePurchases() }
                } label: {
                    Label("Restore Purchases", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                subscriptionDisclosure
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await subscriptionStore.loadProducts()
        }
        .alert("Subscription", isPresented: Binding(
            get: { subscriptionStore.errorMessage != nil },
            set: { if !$0 { subscriptionStore.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(subscriptionStore.errorMessage ?? "")
        }
    }

    private func planCard(_ plan: SubscriptionPlan) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.rawValue)
                        .font(.title3.weight(.bold))
                    Text(productPrice(for: plan) ?? plan.displayPrice)
                        .font(.headline)
                        .foregroundStyle(.green)
                }
                Spacer()
                if subscriptionStore.currentPlan == plan {
                    Text("Current")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.green.opacity(0.14), in: Capsule())
                        .foregroundStyle(.green)
                }
            }

            ForEach(plan.includedFeatures, id: \.self) { feature in
                Label(feature, systemImage: "checkmark")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if plan != .free {
                Button {
                    if let product = product(for: plan) {
                        Task { await subscriptionStore.purchase(product) }
                    } else {
                        subscriptionStore.errorMessage = "Product not loaded yet. Configure App Store Connect or a StoreKit test plan for \(plan.productID ?? "this plan")."
                    }
                } label: {
                    Label("Choose \(plan.rawValue)", systemImage: "creditcard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(subscriptionStore.isLoading || subscriptionStore.currentPlan == plan)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(subscriptionStore.currentPlan == plan ? Color.green : Color.secondary.opacity(0.25), lineWidth: 1)
        )
    }

    private var subscriptionDisclosure: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subscription Notes")
                .font(.headline)
            Text("Subscriptions renew automatically until cancelled in the user's App Store account settings. Prices shown here are placeholders until configured in App Store Connect. Digital features are unlocked through StoreKit 2 in-app purchases.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("No external checkout or API keys are embedded in this app.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func product(for plan: SubscriptionPlan) -> Product? {
        guard let productID = plan.productID else { return nil }
        return subscriptionStore.products.first { $0.id == productID }
    }

    private func productPrice(for plan: SubscriptionPlan) -> String? {
        product(for: plan)?.displayPrice
    }
}
