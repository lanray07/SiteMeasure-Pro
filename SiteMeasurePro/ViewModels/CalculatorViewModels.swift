import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class MaterialCalculatorViewModel {
    var projectType: ProjectType = .lawnInstallation
    var width: Double = 6
    var height: Double = 4
    var area: Double = 24
    var perimeter: Double = 20
    var isLoading = false
    var errorMessage: String?
    var results: [AIMaterialResult] = []

    func updateFromMeasurement(_ measurement: Measurement?) {
        guard let measurement else { return }
        width = measurement.width
        height = measurement.height
        area = measurement.area
        perimeter = measurement.perimeter
    }

    func recalculateFromDimensions() {
        area = max(width * height, 0)
        perimeter = max((width + height) * 2, 0)
    }

    func calculate(aiService: any AIService) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let measurement = AIMeasurementResult(
                width: width,
                height: height,
                area: area,
                perimeter: perimeter,
                confidence: 0.75,
                slopeNote: "Manual calculator input."
            )
            results = try await aiService.calculateMaterials(projectType: projectType, measurements: measurement)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func save(project: Project, in context: ModelContext) -> Bool {
        for result in results {
            context.insert(
                MaterialEstimate(
                    projectId: project.id,
                    category: result.category,
                    materialName: result.materialName,
                    quantity: result.quantity,
                    unit: result.unit,
                    wasteBuffer: result.wasteBuffer,
                    estimatedCost: result.midpointCost
                )
            )
        }

        do {
            try context.save()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

@MainActor
@Observable
final class LaborCalculatorViewModel {
    var hours: Double = 16
    var crewSize: Int = 2
    var laborRate: Double = 45
    var equipmentCost: Double = 120
    var travelCost: Double = 35
    var profitMargin: Double = 0.25
    var errorMessage: String?

    var laborSubtotal: Double {
        max(hours, 0) * Double(max(crewSize, 1)) * max(laborRate, 0)
    }

    var costBeforeMargin: Double {
        laborSubtotal + max(equipmentCost, 0) + max(travelCost, 0)
    }

    var totalCost: Double {
        costBeforeMargin * (1 + max(profitMargin, 0))
    }

    func save(project: Project, in context: ModelContext) -> Bool {
        let estimate = LaborEstimate(
            projectId: project.id,
            hours: hours,
            crewSize: crewSize,
            laborRate: laborRate,
            equipmentCost: equipmentCost,
            travelCost: travelCost,
            profitMargin: profitMargin,
            totalCost: totalCost
        )
        context.insert(estimate)

        do {
            try context.save()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
