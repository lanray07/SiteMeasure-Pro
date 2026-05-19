import SwiftData
import SwiftUI

struct MeasurementEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var measurement: Measurement
    @State private var saved = false

    var body: some View {
        Form {
            Section("Measurement Type") {
                Picker("Object", selection: $measurement.type) {
                    ForEach(MeasurementObject.allCases) { object in
                        Text(object.rawValue).tag(object.rawValue)
                    }
                }
            }

            Section("Dimensions") {
                MetricField(title: "Width", suffix: "m", value: $measurement.width)
                MetricField(title: "Height", suffix: "m", value: $measurement.height)
                MetricField(title: "Area", suffix: "sq m", value: $measurement.area)
                MetricField(title: "Perimeter", suffix: "m", value: $measurement.perimeter)

                Button {
                    measurement.area = max(measurement.width * measurement.height, 0)
                    measurement.perimeter = max((measurement.width + measurement.height) * 2, 0)
                } label: {
                    Label("Recalculate From Width and Height", systemImage: "arrow.triangle.2.circlepath")
                }
            }

            Section("Confidence") {
                HStack {
                    Text("AI confidence")
                    Spacer()
                    Text(AppFormatters.percent(measurement.confidence))
                        .fontWeight(.semibold)
                }
                Slider(value: $measurement.confidence, in: 0...1, step: 0.05)
            }

            Section("Review Notes") {
                TextField("Slope, access, or manual verification notes", text: $measurement.slopeNote, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Button {
                    try? modelContext.save()
                    saved = true
                } label: {
                    Label("Save Changes", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("Edit Measurement")
        .alert("Measurement Saved", isPresented: $saved) {
            Button("OK", role: .cancel) {
                dismiss()
            }
        }
    }
}
