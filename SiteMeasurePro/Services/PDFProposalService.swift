import Foundation
import UIKit

struct ProposalPDFInput {
    var project: Project
    var measurements: [Measurement]
    var materials: [MaterialEstimate]
    var labor: LaborEstimate?
    var summary: String
    var businessName: String
}

struct PDFProposalService {
    func generateProposal(input: ProposalPDFInput) throws -> URL {
        let directory = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Proposals", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let fileName = "\(input.project.title.slugified.isEmpty ? "proposal" : input.project.title.slugified)-\(input.project.id.uuidString.prefix(8)).pdf"
        let url = directory.appendingPathComponent(fileName)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        try renderer.writePDF(to: url) { context in
            context.beginPage()
            var y: CGFloat = 48

            drawHeader(input: input, pageRect: pageRect, y: &y)
            drawSection(
                "Project Overview",
                lines: [
                    input.summary,
                    "Project type: \(input.project.projectType)",
                    "Status: \(input.project.status)",
                    "Target completion: \(input.project.targetCompletionDate.map { AppFormatters.mediumDate.string(from: $0) } ?? "To be confirmed")"
                ],
                context: context,
                pageRect: pageRect,
                y: &y
            )

            drawSection(
                "Measurements",
                lines: input.measurements.isEmpty ? ["No saved measurements yet."] : input.measurements.map {
                    "\($0.type): \(AppFormatters.number($0.width, suffix: "m")) x \(AppFormatters.number($0.height, suffix: "m")), area \(AppFormatters.number($0.area, suffix: "sq m")), confidence \(AppFormatters.percent($0.confidence)). \($0.slopeNote)"
                },
                context: context,
                pageRect: pageRect,
                y: &y
            )

            drawSection(
                "Materials",
                lines: input.materials.isEmpty ? ["No saved material estimate yet."] : input.materials.map {
                    "\($0.materialName): \(AppFormatters.number($0.quantity, suffix: $0.unit)), waste buffer \(AppFormatters.percent($0.wasteBuffer)), allowance \(AppFormatters.currency($0.estimatedCost))"
                },
                context: context,
                pageRect: pageRect,
                y: &y
            )

            let laborLines: [String]
            if let labor = input.labor {
                laborLines = [
                    "Crew size: \(labor.crewSize)",
                    "Estimated hours: \(AppFormatters.number(labor.hours))",
                    "Labor rate: \(AppFormatters.currency(labor.laborRate))/hour",
                    "Equipment: \(AppFormatters.currency(labor.equipmentCost))",
                    "Travel: \(AppFormatters.currency(labor.travelCost))",
                    "Profit margin: \(AppFormatters.percent(labor.profitMargin))",
                    "Total labor/equipment estimate: \(AppFormatters.currency(labor.totalCost))"
                ]
            } else {
                laborLines = ["No saved labor estimate yet."]
            }

            drawSection("Labor", lines: laborLines, context: context, pageRect: pageRect, y: &y)

            let materialTotal = input.materials.reduce(0) { $0 + $1.estimatedCost }
            let laborTotal = input.labor?.totalCost ?? 0
            drawSection(
                "Estimated Pricing",
                lines: [
                    "Materials: \(AppFormatters.currency(materialTotal))",
                    "Labor and equipment: \(AppFormatters.currency(laborTotal))",
                    "Estimated total: \(AppFormatters.currency(materialTotal + laborTotal))"
                ],
                context: context,
                pageRect: pageRect,
                y: &y
            )

            drawSection(
                "Exclusions, Terms, and Disclaimer",
                lines: [
                    "Excludes hidden ground conditions, structural remediation, permit fees, utility relocation, and changes requested after approval unless otherwise stated.",
                    "Measurements are estimates only and must be verified manually before work starts.",
                    "SiteMeasure Pro is not a certified surveying tool. AI calculations and pricing must be reviewed before quoting clients.",
                    "Client signature: ________________________________   Date: ______________"
                ],
                context: context,
                pageRect: pageRect,
                y: &y
            )
        }

        return url
    }

    private func drawHeader(input: ProposalPDFInput, pageRect: CGRect, y: inout CGFloat) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 26, weight: .bold),
            .foregroundColor: UIColor.label
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: UIColor.secondaryLabel
        ]

        "SiteMeasure Pro Proposal".draw(
            in: CGRect(x: 48, y: y, width: pageRect.width - 96, height: 34),
            withAttributes: titleAttributes
        )
        y += 40

        let details = """
        \(input.businessName)
        Client: \(input.project.clientName)
        Address: \(input.project.propertyAddress)
        Created: \(AppFormatters.mediumDate.string(from: .now))
        """
        details.draw(
            in: CGRect(x: 48, y: y, width: pageRect.width - 96, height: 72),
            withAttributes: subtitleAttributes
        )
        y += 84
    }

    private func drawSection(
        _ title: String,
        lines: [String],
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        y: inout CGFloat
    ) {
        ensureSpace(120, context: context, pageRect: pageRect, y: &y)

        let headingAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
            .foregroundColor: UIColor.systemGreen
        ]
        let bodyAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.label
        ]

        title.draw(
            in: CGRect(x: 48, y: y, width: pageRect.width - 96, height: 22),
            withAttributes: headingAttributes
        )
        y += 26

        for line in lines {
            let height = estimatedHeight(for: line, width: pageRect.width - 96, attributes: bodyAttributes)
            ensureSpace(height + 10, context: context, pageRect: pageRect, y: &y)
            line.draw(
                in: CGRect(x: 48, y: y, width: pageRect.width - 96, height: height),
                withAttributes: bodyAttributes
            )
            y += height + 8
        }

        y += 8
    }

    private func ensureSpace(
        _ requiredHeight: CGFloat,
        context: UIGraphicsPDFRendererContext,
        pageRect: CGRect,
        y: inout CGFloat
    ) {
        if y + requiredHeight > pageRect.height - 56 {
            context.beginPage()
            y = 48
        }
    }

    private func estimatedHeight(
        for text: String,
        width: CGFloat,
        attributes: [NSAttributedString.Key: Any]
    ) -> CGFloat {
        let rect = text.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return ceil(rect.height) + 2
    }
}
