import SwiftUI
import UIKit

struct ProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(.headline)
                    Text(project.clientName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusBadge(status: project.statusValue)
            }

            Label(project.propertyAddress.isEmpty ? "Address not added" : project.propertyAddress, systemImage: "mappin.and.ellipse")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Label(project.projectType, systemImage: project.projectTypeValue.industry.symbolName)
                Spacer()
                Text(AppFormatters.mediumDate.string(from: project.createdAt))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct MeasurementCard: View {
    let measurement: Measurement

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(measurement.type, systemImage: "ruler")
                    .font(.headline)
                Spacer()
                Text(AppFormatters.percent(measurement.confidence))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.green.opacity(0.14), in: Capsule())
                    .foregroundStyle(.green)
            }

            HStack(spacing: 12) {
                metric("Width", AppFormatters.number(measurement.width, suffix: "m"))
                metric("Height", AppFormatters.number(measurement.height, suffix: "m"))
                metric("Area", AppFormatters.number(measurement.area, suffix: "sq m"))
                metric("Perimeter", AppFormatters.number(measurement.perimeter, suffix: "m"))
            }

            Text(measurement.slopeNote)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MaterialCard: View {
    let material: MaterialEstimate

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(material.materialName)
                    .font(.headline)
                Spacer()
                Text(AppFormatters.currency(material.estimatedCost))
                    .font(.subheadline.weight(.semibold))
            }

            HStack {
                Label(material.category, systemImage: "shippingbox")
                Spacer()
                Text("\(AppFormatters.number(material.quantity)) \(material.unit)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            ProgressView(value: material.wasteBuffer, total: 0.25) {
                Text("Waste buffer \(AppFormatters.percent(material.wasteBuffer))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .tint(.green)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct ProposalCard: View {
    let proposal: Proposal
    var onShare: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(proposal.title, systemImage: "doc.richtext")
                    .font(.headline)
                Spacer()
                Text(AppFormatters.currency(proposal.estimatedTotal))
                    .font(.subheadline.weight(.semibold))
            }

            Text(proposal.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack {
                Text(AppFormatters.mediumDate.string(from: proposal.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if let onShare {
                    Button(action: onShare) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct EstimateSummaryView: View {
    let materialTotal: Double
    let laborTotal: Double

    var body: some View {
        VStack(spacing: 12) {
            summaryRow("Materials", value: materialTotal, icon: "shippingbox")
            summaryRow("Labor and equipment", value: laborTotal, icon: "person.2")
            Divider()
            summaryRow("Estimated total", value: materialTotal + laborTotal, icon: "sterlingsign.circle", isTotal: true)
        }
        .padding()
        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.green.opacity(0.25), lineWidth: 1)
        )
    }

    private func summaryRow(_ title: String, value: Double, icon: String, isTotal: Bool = false) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(isTotal ? .headline : .subheadline)
            Spacer()
            Text(AppFormatters.currency(value))
                .font(isTotal ? .title3.weight(.bold) : .subheadline.weight(.semibold))
        }
    }
}

struct SitePhotoCard: View {
    let photo: SitePhoto

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.secondary.opacity(0.08))
                if let data = photo.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(photo.caption.isEmpty ? "Site photo" : photo.caption)
                .font(.headline)
            Text(AppFormatters.mediumDate.string(from: photo.createdAt))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct UpgradeBanner: View {
    let plan: SubscriptionPlan

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.title2)
                .frame(width: 42, height: 42)
                .background(.blue.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 3) {
                Text(plan == .free ? "Unlock Pro estimating" : "\(plan.rawValue) active")
                    .font(.headline)
                Text(plan == .free ? "Unlimited projects, proposal exports, and AI material estimates." : "Premium features are available on this device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.blue.opacity(0.22), lineWidth: 1)
        )
    }
}

struct StatusBadge: View {
    let status: ProjectStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(statusColor.opacity(0.14), in: Capsule())
            .foregroundStyle(statusColor)
    }

    private var statusColor: Color {
        switch status {
        case .draft:
            return .gray
        case .pendingQuote:
            return .orange
        case .quoted:
            return .blue
        case .approved:
            return .green
        case .inProgress:
            return .teal
        case .completed:
            return .mint
        case .archived:
            return .secondary
        }
    }
}

struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            Text(value)
                .font(.title3.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var assetName: String?

    var body: some View {
        VStack(spacing: 12) {
            if let assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct DisclaimerListView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(AppConstants.disclaimers, id: \.self) { disclaimer in
                Label(disclaimer, systemImage: "checkmark.shield")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.orange.opacity(0.24), lineWidth: 1)
        )
    }
}
