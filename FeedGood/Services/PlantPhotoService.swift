import Foundation
import UIKit

enum PlantPhotoError: Error, Equatable {
    /// The picked data could not be decoded into an image.
    case unreadableImage
}

/// Prepares user-picked plant photos for on-device storage.
///
/// Permission and storage behavior:
/// - Photos are picked with the system PhotosPicker, which runs out of process
///   and needs no photo-library permission prompt.
/// - Picked images are downscaled and recompressed here so they stay small
///   enough to live inside the local SwiftData store.
/// - Nothing is written to the photo library and nothing leaves the device.
enum PlantPhotoService {
    static let maximumDimension: CGFloat = 1200
    static let compressionQuality: CGFloat = 0.82

    /// Returns storage-ready JPEG data for the picked image, downscaled so its
    /// longest edge is at most `maximumDimension` points.
    /// - Throws: `PlantPhotoError.unreadableImage` when the data is not an image
    ///   or cannot be re-encoded.
    static func prepareForStorage(_ data: Data) throws -> Data {
        guard let source = UIImage(data: data) else {
            throw PlantPhotoError.unreadableImage
        }
        let size = source.size
        guard size.width > 0, size.height > 0 else {
            throw PlantPhotoError.unreadableImage
        }

        let longestEdge = max(size.width, size.height)
        let scale = longestEdge > maximumDimension ? maximumDimension / longestEdge : 1
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)

        // Drawing into the renderer also normalizes EXIF orientation. Forcing
        // scale 1 keeps output pixels equal to the point size, so the stored
        // photo's dimensions are predictable regardless of device scale.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        let rendered = renderer.image { _ in
            source.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        guard let output = rendered.jpegData(compressionQuality: compressionQuality) else {
            throw PlantPhotoError.unreadableImage
        }
        return output
    }
}
