import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct MeasurementWorkspaceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.aiService) private var aiService
    @State private var viewModel = MeasurementWorkflowViewModel()
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var saved = false

    let project: Project

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(project.title)
                        .font(.largeTitle.weight(.bold))
                    Text("Capture site photos, mark measurement points, then run the mock AI estimate.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                photoControls

                SitePhotoMarkupCanvas(
                    imageData: viewModel.selectedImageData,
                    markers: $viewModel.markers
                ) { location, size in
                    viewModel.addMarker(at: location, in: size)
                }

                markerToolbar

                VStack(alignment: .leading, spacing: 12) {
                    Picker("Object type", selection: $viewModel.selectedObject) {
                        ForEach(MeasurementObject.allCases) { object in
                            Text(object.rawValue).tag(object)
                        }
                    }
                    .pickerStyle(.menu)

                    TextField("Photo caption", text: $viewModel.caption)
                        .textFieldStyle(.roundedBorder)
                }

                PrimaryActionButton(title: "Estimate With Mock AI", systemImage: "sparkles", isLoading: viewModel.isAnalyzing) {
                    Task {
                        await viewModel.analyze(project: project, aiService: aiService)
                    }
                }

                if viewModel.hasAnalysis {
                    editableResults
                    generatedMaterials
                }

                DisclaimerListView()
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Measurement")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCamera) {
            CameraPicker(imageData: Binding(
                get: { viewModel.selectedImageData },
                set: { viewModel.applyCameraImageData($0) }
            ))
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                await viewModel.loadPhoto(from: newItem)
            }
        }
        .alert("Measurement", isPresented: Binding(
            get: { viewModel.errorMessage != nil || saved },
            set: {
                if !$0 {
                    viewModel.errorMessage = nil
                    saved = false
                }
            }
        )) {
            Button("OK", role: .cancel) {
                if saved {
                    dismiss()
                }
            }
        } message: {
            Text(saved ? "Measurement, photo, and material estimates saved." : viewModel.errorMessage ?? "")
        }
    }

    private var photoControls: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("Upload", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                showingCamera = true
            } label: {
                Label("Camera", systemImage: "camera")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
        }
    }

    private var markerToolbar: some View {
        HStack {
            Label("\(viewModel.markers.count) markers", systemImage: "mappin")
                .font(.subheadline.weight(.semibold))
            Spacer()
            Button {
                viewModel.clearMarkers()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.markers.isEmpty)
        }
    }

    private var editableResults: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Editable Measurements")
                    .font(.title3.weight(.bold))
                Spacer()
                Text(AppFormatters.percent(viewModel.confidence))
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.green.opacity(0.14), in: Capsule())
                    .foregroundStyle(.green)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricField(title: "Width", suffix: "m", value: $viewModel.width)
                MetricField(title: "Height", suffix: "m", value: $viewModel.height)
                MetricField(title: "Area", suffix: "sq m", value: $viewModel.area)
                MetricField(title: "Perimeter", suffix: "m", value: $viewModel.perimeter)
            }

            Button {
                viewModel.recalculateArea()
            } label: {
                Label("Recalculate From Width and Height", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.bordered)

            Text(viewModel.slopeNote)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                if viewModel.save(project: project, in: modelContext) {
                    saved = true
                }
            } label: {
                Label("Save Measurement", systemImage: "tray.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        )
    }

    private var generatedMaterials: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Material Estimate")
                .font(.title3.weight(.bold))
            Text(viewModel.aiSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(viewModel.generatedMaterials) { material in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(material.materialName)
                            .font(.headline)
                        Spacer()
                        Text("\(AppFormatters.number(material.quantity)) \(material.unit)")
                            .font(.subheadline.weight(.semibold))
                    }
                    Text("\(AppFormatters.currency(material.estimatedCostLow)) - \(AppFormatters.currency(material.estimatedCostHigh)) with \(AppFormatters.percent(material.wasteBuffer)) waste buffer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
}
