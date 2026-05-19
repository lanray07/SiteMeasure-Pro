import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedIndustry: Industry = .landscaping

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 12) {
                        Image("OnboardingHero")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(.white.opacity(0.65), lineWidth: 1)
                            )
                        Text("Welcome to SiteMeasure Pro")
                            .font(.largeTitle.weight(.bold))
                            .fixedSize(horizontal: false, vertical: true)
                        Text("AI-powered outdoor measurement, estimating, and proposal generation for contractors and property professionals.")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Select Industry")
                            .font(.headline)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                            ForEach(Industry.allCases) { industry in
                                Button {
                                    selectedIndustry = industry
                                } label: {
                                    HStack {
                                        Image(systemName: industry.symbolName)
                                        Text(industry.rawValue)
                                            .fontWeight(.semibold)
                                            .lineLimit(2)
                                        Spacer(minLength: 0)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
                                    .background(
                                        selectedIndustry == industry ? .green.opacity(0.16) : .secondary.opacity(0.08),
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(selectedIndustry == industry ? .green : .clear, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("AI Measurement Disclaimer")
                            .font(.headline)
                        DisclaimerListView()
                    }

                    PrimaryActionButton(title: "Start Measuring", systemImage: "arrow.right", isLoading: false) {
                        appState.completeOnboarding(industry: selectedIndustry)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}
