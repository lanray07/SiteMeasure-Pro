import Foundation
import CoreGraphics
import Observation
import PhotosUI
import SwiftUI
import SwiftData

struct MeasurementMarker: Identifiable, Hashable {
    let id = UUID()
    var x: Double
    var y: Double
}

@MainActor
@Observable
final class MeasurementWorkflowViewModel {
    var selectedImageData: Data?
    var caption = "Site photo"
    var selectedObject: MeasurementObject = .lawn
    var markers: [MeasurementMarker] = []
    var width: Double = 0
    var height: Double = 0
    var area: Double = 0
    var perimeter: Double = 0
    var confidence: Double = 0
    var slopeNote = ""
    var generatedMaterials: [AIMaterialResult] = []
    var aiSummary = ""
    var isAnalyzing = false
    var errorMessage: String?
    var hasAnalysis = false

    func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self) {
                selectedImageData = data
                errorMessage = nil
            }
        } catch {
            errorMessage = "Unable to load selected photo."
        }
    }

    func applyCameraImageData(_ data: Data?) {
        selectedImageData = data
    }

    func addMarker(at location: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        let normalized = MeasurementMarker(
            x: min(max(location.x / size.width, 0), 1),
            y: min(max(location.y / size.height, 0), 1)
        )
        markers.append(normalized)
    }

    func clearMarkers() {
        markers.removeAll()
    }

    func analyze(project: Project, aiService: any AIService) async {
        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }

        do {
            let result = try await aiService.analyzeSitePhoto(
                AIAnalysisRequest(
                    projectType: project.projectTypeValue,
                    siteNotes: project.notes,
                    measurementType: selectedObject,
                    imageData: selectedImageData
                )
            )
            width = result.measurements.width
            height = result.measurements.height
            area = result.measurements.area
            perimeter = result.measurements.perimeter
            confidence = result.measurements.confidence
            slopeNote = result.measurements.slopeNote
            generatedMaterials = result.materials
            aiSummary = result.summary
            hasAnalysis = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func recalculateArea() {
        area = max(width * height, 0)
        perimeter = max((width + height) * 2, 0)
    }

    func save(project: Project, in context: ModelContext) -> Bool {
        guard hasAnalysis else {
            errorMessage = "Run an AI estimate or enter measurements before saving."
            return false
        }

        if let selectedImageData {
            context.insert(
                SitePhoto(
                    projectId: project.id,
                    imageData: selectedImageData,
                    caption: caption.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
        }

        context.insert(
            Measurement(
                projectId: project.id,
                type: selectedObject,
                width: width,
                height: height,
                area: area,
                perimeter: perimeter,
                confidence: confidence,
                slopeNote: slopeNote
            )
        )

        for material in generatedMaterials {
            context.insert(
                MaterialEstimate(
                    projectId: project.id,
                    category: material.category,
                    materialName: material.materialName,
                    quantity: material.quantity,
                    unit: material.unit,
                    wasteBuffer: material.wasteBuffer,
                    estimatedCost: material.midpointCost
                )
            )
        }

        project.status = ProjectStatus.pendingQuote.rawValue
        project.updatedAt = .now

        do {
            try context.save()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
