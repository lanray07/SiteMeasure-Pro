import Foundation
import Observation

@Observable
final class AppState {
    var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Self.onboardingKey)
        }
    }

    var selectedIndustry: Industry {
        didSet {
            UserDefaults.standard.set(selectedIndustry.rawValue, forKey: Self.industryKey)
        }
    }

    private static let onboardingKey = "hasCompletedOnboarding"
    private static let industryKey = "selectedIndustry"

    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Self.onboardingKey)
        if let rawIndustry = UserDefaults.standard.string(forKey: Self.industryKey),
           let industry = Industry(rawValue: rawIndustry) {
            selectedIndustry = industry
        } else {
            selectedIndustry = .landscaping
        }
    }

    func completeOnboarding(industry: Industry) {
        selectedIndustry = industry
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
}
