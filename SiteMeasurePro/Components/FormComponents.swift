import SwiftUI
import UIKit

struct MetricField: View {
    let title: String
    let suffix: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                TextField(title, value: $value, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                Text(suffix)
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

struct PrimaryActionButton: View {
    let title: String
    let systemImage: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(.borderedProminent)
        .disabled(isLoading)
    }
}

struct SitePhotoMarkupCanvas: View {
    let imageData: Data?
    @Binding var markers: [MeasurementMarker]
    var onAddMarker: (CGPoint, CGSize) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.secondary.opacity(0.08))

                if let imageData, let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "camera.metering.center.weighted")
                            .font(.largeTitle)
                        Text("Add a site photo")
                            .font(.headline)
                        Text("Tap uploaded photos to place measurement markers.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                boundaryPath(size: geometry.size)
                    .stroke(.green, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                ForEach(Array(markers.enumerated()), id: \.element.id) { index, marker in
                    markerView(index: index + 1)
                        .position(x: marker.x * geometry.size.width, y: marker.y * geometry.size.height)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(coordinateSpace: .local) { location in
                onAddMarker(location, geometry.size)
            }
        }
        .frame(minHeight: 320)
    }

    private func boundaryPath(size: CGSize) -> Path {
        Path { path in
            guard let first = markers.first else { return }
            path.move(to: CGPoint(x: first.x * size.width, y: first.y * size.height))
            for marker in markers.dropFirst() {
                path.addLine(to: CGPoint(x: marker.x * size.width, y: marker.y * size.height))
            }
            if markers.count > 2 {
                path.closeSubpath()
            }
        }
    }

    private func markerView(index: Int) -> some View {
        ZStack {
            Circle()
                .fill(.green)
                .frame(width: 34, height: 34)
            Text("\(index)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
        }
        .shadow(radius: 4, y: 2)
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var imageData: Data?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageData = image.jpegData(compressionQuality: 0.85)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ShareItem: Identifiable {
    let url: URL

    var id: String {
        url.absoluteString
    }
}
