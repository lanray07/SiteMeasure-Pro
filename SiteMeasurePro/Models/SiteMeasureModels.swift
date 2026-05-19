import Foundation
import SwiftData

enum Industry: String, CaseIterable, Identifiable, Codable {
    case landscaping = "Landscaping"
    case roofing = "Roofing"
    case fencing = "Fencing"
    case driveways = "Driveways"
    case decking = "Decking"
    case generalConstruction = "General Construction"
    case propertyServices = "Property Services"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .landscaping:
            return "leaf"
        case .roofing:
            return "house"
        case .fencing:
            return "square.grid.3x3"
        case .driveways:
            return "road.lanes"
        case .decking:
            return "rectangle.3.group"
        case .generalConstruction:
            return "hammer"
        case .propertyServices:
            return "building.2"
        }
    }
}

enum ProjectType: String, CaseIterable, Identifiable, Codable {
    case lawnInstallation = "Lawn installation"
    case patio = "Patio"
    case fencing = "Fencing"
    case roofing = "Roofing"
    case decking = "Decking"
    case driveway = "Driveway"
    case drainage = "Drainage"
    case gardenRedesign = "Garden redesign"
    case exteriorCleaning = "Exterior cleaning"
    case custom = "Custom"

    var id: String { rawValue }

    var industry: Industry {
        switch self {
        case .lawnInstallation, .gardenRedesign, .drainage:
            return .landscaping
        case .patio:
            return .landscaping
        case .fencing:
            return .fencing
        case .roofing:
            return .roofing
        case .decking:
            return .decking
        case .driveway:
            return .driveways
        case .exteriorCleaning:
            return .propertyServices
        case .custom:
            return .generalConstruction
        }
    }
}

enum ProjectStatus: String, CaseIterable, Identifiable, Codable {
    case draft = "Draft"
    case pendingQuote = "Pending Quote"
    case quoted = "Quoted"
    case approved = "Approved"
    case inProgress = "In Progress"
    case completed = "Completed"
    case archived = "Archived"

    var id: String { rawValue }

    var tintName: String {
        switch self {
        case .draft:
            return "gray"
        case .pendingQuote:
            return "orange"
        case .quoted:
            return "blue"
        case .approved:
            return "green"
        case .inProgress:
            return "teal"
        case .completed:
            return "mint"
        case .archived:
            return "secondary"
        }
    }
}

enum MeasurementObject: String, CaseIterable, Identifiable, Codable {
    case fence = "Fence"
    case roofEdge = "Roof edge"
    case patioArea = "Patio area"
    case driveway = "Driveway"
    case lawn = "Lawn"
    case pathway = "Pathway"
    case wall = "Wall"
    case gardenBed = "Garden bed"
    case customArea = "Custom area"

    var id: String { rawValue }
}

enum MaterialCategory: String, CaseIterable, Identifiable, Codable {
    case landscaping = "Landscaping"
    case roofing = "Roofing"
    case fencing = "Fencing"
    case driveways = "Driveways"
    case decking = "Decking"
    case general = "General"

    var id: String { rawValue }
}

enum SubscriptionPlan: String, CaseIterable, Identifiable, Codable, Comparable {
    case free = "Free"
    case proMonthly = "Pro Monthly"
    case proYearly = "Pro Yearly"
    case businessMonthly = "Business Monthly"

    var id: String { rawValue }

    static func < (lhs: SubscriptionPlan, rhs: SubscriptionPlan) -> Bool {
        lhs.rank < rhs.rank
    }

    var rank: Int {
        switch self {
        case .free:
            return 0
        case .proMonthly:
            return 1
        case .proYearly:
            return 2
        case .businessMonthly:
            return 3
        }
    }

    var displayPrice: String {
        switch self {
        case .free:
            return "£0"
        case .proMonthly:
            return "£29.99/mo"
        case .proYearly:
            return "£249.99/yr"
        case .businessMonthly:
            return "£99.99/mo"
        }
    }

    var productID: String? {
        switch self {
        case .free:
            return nil
        case .proMonthly:
            return AppConstants.StoreKit.proMonthlyProductID
        case .proYearly:
            return AppConstants.StoreKit.proYearlyProductID
        case .businessMonthly:
            return AppConstants.StoreKit.businessMonthlyProductID
        }
    }

    var includedFeatures: [String] {
        switch self {
        case .free:
            return ["3 projects/month", "Limited measurements", "Basic estimates", "SiteMeasure Pro branding"]
        case .proMonthly, .proYearly:
            return ["Unlimited projects", "AI material estimates", "Proposal exports", "Custom branding", "Saved templates", "Advanced calculators"]
        case .businessMonthly:
            return ["Everything in Pro", "Team users placeholder", "Multi-site projects", "White-label proposals", "Advanced reporting", "CRM placeholder integration"]
        }
    }
}

@Model
final class Project {
    @Attribute(.unique) var id: UUID
    var title: String
    var clientName: String
    var propertyAddress: String
    var projectType: String
    var notes: String
    var status: String
    var targetCompletionDate: Date?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        clientName: String,
        propertyAddress: String,
        projectType: ProjectType,
        notes: String = "",
        status: ProjectStatus = .draft,
        targetCompletionDate: Date? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.clientName = clientName
        self.propertyAddress = propertyAddress
        self.projectType = projectType.rawValue
        self.notes = notes
        self.status = status.rawValue
        self.targetCompletionDate = targetCompletionDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var projectTypeValue: ProjectType {
        ProjectType(rawValue: projectType) ?? .custom
    }

    var statusValue: ProjectStatus {
        ProjectStatus(rawValue: status) ?? .draft
    }
}

@Model
final class SitePhoto {
    @Attribute(.unique) var id: UUID
    var projectId: UUID
    @Attribute(.externalStorage) var imageData: Data?
    var localImageURL: String?
    var caption: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        imageData: Data? = nil,
        localImageURL: String? = nil,
        caption: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.projectId = projectId
        self.imageData = imageData
        self.localImageURL = localImageURL
        self.caption = caption
        self.createdAt = createdAt
    }
}

@Model
final class Measurement {
    @Attribute(.unique) var id: UUID
    var projectId: UUID
    var type: String
    var width: Double
    var height: Double
    var area: Double
    var perimeter: Double
    var confidence: Double
    var slopeNote: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        type: MeasurementObject,
        width: Double,
        height: Double,
        area: Double,
        perimeter: Double,
        confidence: Double,
        slopeNote: String = "Slope not verified. Manual review required.",
        createdAt: Date = .now
    ) {
        self.id = id
        self.projectId = projectId
        self.type = type.rawValue
        self.width = width
        self.height = height
        self.area = area
        self.perimeter = perimeter
        self.confidence = confidence
        self.slopeNote = slopeNote
        self.createdAt = createdAt
    }

    var typeValue: MeasurementObject {
        MeasurementObject(rawValue: type) ?? .customArea
    }
}

@Model
final class MaterialEstimate {
    @Attribute(.unique) var id: UUID
    var projectId: UUID
    var category: String
    var materialName: String
    var quantity: Double
    var unit: String
    var wasteBuffer: Double
    var estimatedCost: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        category: MaterialCategory,
        materialName: String,
        quantity: Double,
        unit: String,
        wasteBuffer: Double,
        estimatedCost: Double,
        createdAt: Date = .now
    ) {
        self.id = id
        self.projectId = projectId
        self.category = category.rawValue
        self.materialName = materialName
        self.quantity = quantity
        self.unit = unit
        self.wasteBuffer = wasteBuffer
        self.estimatedCost = estimatedCost
        self.createdAt = createdAt
    }

    var categoryValue: MaterialCategory {
        MaterialCategory(rawValue: category) ?? .general
    }
}

@Model
final class LaborEstimate {
    @Attribute(.unique) var id: UUID
    var projectId: UUID
    var hours: Double
    var crewSize: Int
    var laborRate: Double
    var equipmentCost: Double
    var travelCost: Double
    var profitMargin: Double
    var totalCost: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        hours: Double,
        crewSize: Int,
        laborRate: Double,
        equipmentCost: Double,
        travelCost: Double,
        profitMargin: Double,
        totalCost: Double,
        createdAt: Date = .now
    ) {
        self.id = id
        self.projectId = projectId
        self.hours = hours
        self.crewSize = crewSize
        self.laborRate = laborRate
        self.equipmentCost = equipmentCost
        self.travelCost = travelCost
        self.profitMargin = profitMargin
        self.totalCost = totalCost
        self.createdAt = createdAt
    }
}

@Model
final class Proposal {
    @Attribute(.unique) var id: UUID
    var projectId: UUID
    var title: String
    var summary: String
    var pdfLocalURL: String?
    var estimatedTotal: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        projectId: UUID,
        title: String,
        summary: String,
        pdfLocalURL: String? = nil,
        estimatedTotal: Double,
        createdAt: Date = .now
    ) {
        self.id = id
        self.projectId = projectId
        self.title = title
        self.summary = summary
        self.pdfLocalURL = pdfLocalURL
        self.estimatedTotal = estimatedTotal
        self.createdAt = createdAt
    }
}

@Model
final class SubscriptionState {
    @Attribute(.unique) var id: UUID
    var plan: String
    var isActive: Bool
    var renewsAt: Date?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        plan: SubscriptionPlan = .free,
        isActive: Bool = false,
        renewsAt: Date? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.plan = plan.rawValue
        self.isActive = isActive
        self.renewsAt = renewsAt
        self.updatedAt = updatedAt
    }

    var planValue: SubscriptionPlan {
        SubscriptionPlan(rawValue: plan) ?? .free
    }
}
