import Foundation
import SwiftUI

struct AIAnalysisRequest {
    var projectType: ProjectType
    var siteNotes: String
    var measurementType: MeasurementObject
    var imageData: Data?
}

struct AIMeasurementResult: Codable, Hashable {
    var width: Double
    var height: Double
    var area: Double
    var perimeter: Double
    var confidence: Double
    var slopeNote: String
}

struct AIMaterialResult: Codable, Hashable, Identifiable {
    var id = UUID()
    var category: MaterialCategory
    var materialName: String
    var quantity: Double
    var unit: String
    var wasteBuffer: Double
    var estimatedCostLow: Double
    var estimatedCostHigh: Double

    enum CodingKeys: String, CodingKey {
        case category
        case materialName
        case quantity
        case unit
        case wasteBuffer
        case estimatedCostLow
        case estimatedCostHigh
    }

    var midpointCost: Double {
        (estimatedCostLow + estimatedCostHigh) / 2
    }
}

struct AIAnalysisResult: Codable, Hashable {
    var measurements: AIMeasurementResult
    var materials: [AIMaterialResult]
    var summary: String
}

protocol AIService {
    func analyzeSitePhoto(_ request: AIAnalysisRequest) async throws -> AIAnalysisResult
    func estimateMeasurements(projectType: ProjectType, notes: String, measurementType: MeasurementObject) async throws -> AIMeasurementResult
    func calculateMaterials(projectType: ProjectType, measurements: AIMeasurementResult) async throws -> [AIMaterialResult]
    func generateProposalSummary(project: Project, measurements: [Measurement], materials: [MaterialEstimate], labor: LaborEstimate?) async throws -> String
}

enum AIServiceError: LocalizedError {
    case invalidResponse
    case requestFailed(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The AI endpoint returned an unexpected response."
        case .requestFailed(let statusCode):
            return "The AI endpoint failed with status code \(statusCode)."
        }
    }
}

struct MockAIService: AIService {
    func analyzeSitePhoto(_ request: AIAnalysisRequest) async throws -> AIAnalysisResult {
        try await Task.sleep(for: .milliseconds(650))
        let measurement = try await estimateMeasurements(
            projectType: request.projectType,
            notes: request.siteNotes,
            measurementType: request.measurementType
        )
        let materials = try await calculateMaterials(projectType: request.projectType, measurements: measurement)
        let summary = "Estimated \(request.measurementType.rawValue.lowercased()) dimensions for a \(request.projectType.rawValue.lowercased()) project. Values are conservative planning estimates and should be verified manually before quoting."
        return AIAnalysisResult(measurements: measurement, materials: materials, summary: summary)
    }

    func estimateMeasurements(projectType: ProjectType, notes: String, measurementType: MeasurementObject) async throws -> AIMeasurementResult {
        let baseWidth: Double
        let baseHeight: Double

        switch projectType {
        case .roofing:
            baseWidth = 8.8
            baseHeight = 6.4
        case .fencing:
            baseWidth = 18.0
            baseHeight = 1.8
        case .driveway:
            baseWidth = 5.4
            baseHeight = 9.2
        case .decking:
            baseWidth = 4.8
            baseHeight = 6.0
        case .lawnInstallation, .gardenRedesign:
            baseWidth = 10.5
            baseHeight = 8.5
        case .patio:
            baseWidth = 5.6
            baseHeight = 4.2
        case .drainage, .exteriorCleaning, .custom:
            baseWidth = 7.2
            baseHeight = 5.0
        }

        let objectAdjustment = Double(measurementType.rawValue.count % 4) * 0.35
        let width = baseWidth + objectAdjustment
        let height = baseHeight + objectAdjustment / 2
        let area = max(width * height, 0)
        let perimeter = max((width + height) * 2, 0)

        return AIMeasurementResult(
            width: width,
            height: height,
            area: area,
            perimeter: perimeter,
            confidence: 0.78,
            slopeNote: "Slope and grade are placeholders. Confirm levels on site before procurement."
        )
    }

    func calculateMaterials(projectType: ProjectType, measurements: AIMeasurementResult) async throws -> [AIMaterialResult] {
        let area = max(measurements.area, 1)
        let perimeter = max(measurements.perimeter, 1)

        switch projectType.industry {
        case .landscaping:
            if projectType == .patio {
                return [
                    material(.landscaping, "Paving slabs", area * 1.08, "sq m", 0.08, area * 22, area * 48),
                    material(.landscaping, "Gravel sub-base", area * 0.16, "tonnes", 0.12, area * 8, area * 15),
                    material(.landscaping, "Bedding mortar", area * 0.06, "tonnes", 0.1, area * 5, area * 9)
                ]
            } else {
                return [
                    material(.landscaping, "Turf rolls", area * 1.08, "sq m", 0.08, area * 8, area * 13),
                    material(.landscaping, "Topsoil", area * 0.08, "bulk bags", 0.1, area * 2.4, area * 4.1),
                    material(.landscaping, "Mulch", area * 0.06, "bulk bags", 0.12, area * 1.8, area * 3.5),
                    material(.landscaping, "Gravel or paving allowance", area * 0.04, "allowance", 0.1, area * 3, area * 9)
                ]
            }
        case .roofing:
            return [
                material(.roofing, "Roof tiles/shingles", area * 1.12, "sq m", 0.12, area * 28, area * 46),
                material(.roofing, "Underlayment", area * 1.1, "sq m", 0.1, area * 4, area * 7),
                material(.roofing, "Flashing allowance", perimeter * 0.25, "linear m", 0.08, perimeter * 3, perimeter * 7)
            ]
        case .fencing:
            return [
                material(.fencing, "Fence panels", ceil(perimeter / 1.8), "panels", 0.05, perimeter * 18, perimeter * 34),
                material(.fencing, "Posts", ceil(perimeter / 1.8) + 1, "posts", 0.05, perimeter * 7, perimeter * 14),
                material(.fencing, "Post concrete", ceil(perimeter / 1.8), "bags", 0.08, perimeter * 4, perimeter * 8),
                material(.fencing, "Screws and fixings", ceil(perimeter * 8), "pieces", 0.1, perimeter * 1.5, perimeter * 3.5)
            ]
        case .driveways:
            return [
                material(.driveways, "Base aggregate", area * 0.18, "tonnes", 0.12, area * 12, area * 19),
                material(.driveways, "Tarmac/resin/concrete/block surface", area * 1.08, "sq m", 0.08, area * 32, area * 68),
                material(.driveways, "Edge restraints", perimeter, "linear m", 0.05, perimeter * 7, perimeter * 15)
            ]
        case .decking:
            return [
                material(.decking, "Deck boards", area * 1.12, "sq m", 0.12, area * 35, area * 70),
                material(.decking, "Joists and frame", perimeter * 0.8, "linear m", 0.1, perimeter * 12, perimeter * 22),
                material(.decking, "Fixings", area * 28, "pieces", 0.1, area * 2, area * 5)
            ]
        case .generalConstruction, .propertyServices:
            return [
                material(.general, "General materials allowance", area, "sq m", 0.1, area * 18, area * 42),
                material(.general, "Consumables", area * 0.25, "allowance", 0.1, area * 2, area * 5)
            ]
        }
    }

    func generateProposalSummary(project: Project, measurements: [Measurement], materials: [MaterialEstimate], labor: LaborEstimate?) async throws -> String {
        let measuredArea = measurements.reduce(0) { $0 + $1.area }
        let materialTotal = materials.reduce(0) { $0 + $1.estimatedCost }
        let laborTotal = labor?.totalCost ?? 0
        return """
        This proposal covers the planned \(project.projectType.lowercased()) works for \(project.clientName). SiteMeasure Pro estimated approximately \(AppFormatters.number(measuredArea, suffix: "sq m")) from uploaded photos and marked reference points. The estimate includes a material allowance of \(AppFormatters.currency(materialTotal)) and labor/equipment allowance of \(AppFormatters.currency(laborTotal)). Measurements, levels, access, and supplier pricing must be verified before the final client quote is accepted.
        """
    }

    private func material(
        _ category: MaterialCategory,
        _ name: String,
        _ quantity: Double,
        _ unit: String,
        _ wasteBuffer: Double,
        _ low: Double,
        _ high: Double
    ) -> AIMaterialResult {
        AIMaterialResult(
            category: category,
            materialName: name,
            quantity: quantity,
            unit: unit,
            wasteBuffer: wasteBuffer,
            estimatedCostLow: low,
            estimatedCostHigh: high
        )
    }
}

struct RemoteAIService: AIService {
    var endpoint: URL = AppConstants.AI.backendEndpoint
    var session: URLSession = .shared

    func analyzeSitePhoto(_ request: AIAnalysisRequest) async throws -> AIAnalysisResult {
        let payload = RemoteAIRequest(
            projectType: request.projectType.rawValue,
            siteNotes: request.siteNotes,
            measurementType: request.measurementType.rawValue,
            imageBase64: request.imageData?.base64EncodedString() ?? ""
        )

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        guard 200..<300 ~= httpResponse.statusCode else {
            throw AIServiceError.requestFailed(httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(RemoteAIResponse.self, from: data)
        return decoded.analysisResult
    }

    func estimateMeasurements(projectType: ProjectType, notes: String, measurementType: MeasurementObject) async throws -> AIMeasurementResult {
        let result = try await analyzeSitePhoto(
            AIAnalysisRequest(projectType: projectType, siteNotes: notes, measurementType: measurementType, imageData: nil)
        )
        return result.measurements
    }

    func calculateMaterials(projectType: ProjectType, measurements: AIMeasurementResult) async throws -> [AIMaterialResult] {
        let result = try await analyzeSitePhoto(
            AIAnalysisRequest(projectType: projectType, siteNotes: "Material calculation only", measurementType: .customArea, imageData: nil)
        )
        return result.materials
    }

    func generateProposalSummary(project: Project, measurements: [Measurement], materials: [MaterialEstimate], labor: LaborEstimate?) async throws -> String {
        let result = try await analyzeSitePhoto(
            AIAnalysisRequest(projectType: project.projectTypeValue, siteNotes: project.notes, measurementType: .customArea, imageData: nil)
        )
        return result.summary
    }
}

private struct RemoteAIRequest: Codable {
    var projectType: String
    var siteNotes: String
    var measurementType: String
    var imageBase64: String
}

private struct RemoteAIResponse: Codable {
    var measurements: RemoteMeasurements
    var materials: [RemoteMaterial]
    var summary: String

    var analysisResult: AIAnalysisResult {
        AIAnalysisResult(
            measurements: AIMeasurementResult(
                width: measurements.width,
                height: measurements.height,
                area: measurements.area,
                perimeter: measurements.perimeter,
                confidence: measurements.confidence ?? 0.7,
                slopeNote: measurements.slopeNote ?? "Slope not verified. Manual review required."
            ),
            materials: materials.map(\.materialResult),
            summary: summary
        )
    }
}

private struct RemoteMeasurements: Codable {
    var width: Double
    var height: Double
    var area: Double
    var perimeter: Double
    var confidence: Double?
    var slopeNote: String?
}

private struct RemoteMaterial: Codable {
    var category: String?
    var materialName: String
    var quantity: Double
    var unit: String?
    var wasteBuffer: Double?
    var estimatedCost: Double?
    var estimatedCostLow: Double?
    var estimatedCostHigh: Double?

    var materialResult: AIMaterialResult {
        let midpoint = estimatedCost ?? 0
        return AIMaterialResult(
            category: MaterialCategory(rawValue: category ?? "") ?? .general,
            materialName: materialName,
            quantity: quantity,
            unit: unit ?? "units",
            wasteBuffer: wasteBuffer ?? 0.1,
            estimatedCostLow: estimatedCostLow ?? midpoint,
            estimatedCostHigh: estimatedCostHigh ?? midpoint
        )
    }
}

private struct AIServiceKey: EnvironmentKey {
    static let defaultValue: any AIService = MockAIService()
}

extension EnvironmentValues {
    var aiService: any AIService {
        get { self[AIServiceKey.self] }
        set { self[AIServiceKey.self] = newValue }
    }
}
