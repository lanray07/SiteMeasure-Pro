import SwiftData
import SwiftUI

@main
@MainActor
struct SiteMeasureProApp: App {
    private let modelContainer: ModelContainer
    @State private var appState = AppState()
    @State private var subscriptionStore = SubscriptionStore()
    private let aiService: any AIService = MockAIService()

    init() {
        let schema = Schema([
            Project.self,
            SitePhoto.self,
            Measurement.self,
            MaterialEstimate.self,
            LaborEstimate.self,
            Proposal.self,
            SubscriptionState.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create SiteMeasure Pro model container: \(error.localizedDescription)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environment(appState)
                .environment(subscriptionStore)
                .environment(\.aiService, aiService)
        }
        .modelContainer(modelContainer)
    }
}
