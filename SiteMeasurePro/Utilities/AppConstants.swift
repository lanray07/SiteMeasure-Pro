import Foundation

enum AppConstants {
    enum Legal {
        static let privacyPolicyURL = URL(string: "https://github.com/lanray07/SiteMeasure-Pro/blob/main/docs/privacy-policy.md")!
        static let termsOfUseURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    }

    enum StoreKit {
        static let proMonthlyProductID = "sitemeasure.pro.monthly"
        static let proYearlyProductID = "sitemeasure.pro.yearly"
        static let businessMonthlyProductID = "sitemeasure.business.monthly"

        static let productIDs = [
            proMonthlyProductID,
            proYearlyProductID,
            businessMonthlyProductID
        ]
    }

    enum AI {
        static let backendEndpoint = URL(string: "https://YOUR_BACKEND_URL.com/site-measure-ai")!

        static let internalPrompt = """
        You are SiteMeasure Pro, an AI assistant for outdoor project measurement and estimating. Review the uploaded site image, project type, and user notes. Generate estimated measurements, material estimates, and project summaries using cautious language. Do not claim exact surveying accuracy. Users must verify all measurements and pricing before quoting clients.
        """
    }

    static let disclaimers = [
        "Measurements are estimates only.",
        "Verify all dimensions manually.",
        "SiteMeasure Pro is not a certified surveying tool.",
        "AI calculations must be reviewed before quoting.",
        "Pricing estimates may vary by site conditions, suppliers, and region."
    ]
}
