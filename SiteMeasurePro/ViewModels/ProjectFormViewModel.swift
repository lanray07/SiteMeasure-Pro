import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class ProjectFormViewModel {
    var title = ""
    var clientName = ""
    var propertyAddress = ""
    var projectType: ProjectType = .lawnInstallation
    var notes = ""
    var status: ProjectStatus = .draft
    var targetCompletionDate = Date().addingTimeInterval(60 * 60 * 24 * 14)
    var includeTargetDate = true
    var errorMessage: String?

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func makeProject() -> Project? {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanClient = clientName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanTitle.isEmpty, !cleanClient.isEmpty else {
            errorMessage = "Add a project title and client name."
            return nil
        }

        return Project(
            title: cleanTitle,
            clientName: cleanClient,
            propertyAddress: propertyAddress.trimmingCharacters(in: .whitespacesAndNewlines),
            projectType: projectType,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            status: status,
            targetCompletionDate: includeTargetDate ? targetCompletionDate : nil
        )
    }

    func save(in context: ModelContext) -> Bool {
        guard let project = makeProject() else { return false }
        context.insert(project)

        do {
            try context.save()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
