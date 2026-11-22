import Foundation
import ImageIO
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
/// - Picked images are downsampled at decode time so a full-size bitmap is
///   never materialized: a 48 MP or ProRAW pick cannot exhaust memory.
/// - Nothing is written to the photo library and nothing leaves the device.
enum PlantPhotoService {
    static let maximumDimension: CGFloat = 1200
    static let compressionQuality: CGFloat = 0.82

    /// Returns storage-ready JPEG data for the picked image, downsampled so its
    /// longest edge is at most `maximumDimension` pixels.
    ///
    /// The source image is never decoded at full size: the pixel dimensions are
    /// read from the image header and ImageIO produces the thumbnail directly.
    /// `kCGImageSourceCreateThumbnailWithTransform` normalizes EXIF orientation,
    /// matching the previous renderer-based path.
    /// - Throws: `PlantPhotoError.unreadableImage` when the data is not an image
    ///   or cannot be re-encoded.
    static func prepareForStorage(_ data: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw PlantPhotoError.unreadableImage
        }
        let pixelSize = sourcePixelSize(of: source)
        guard pixelSize.width > 0, pixelSize.height > 0 else {
            throw PlantPhotoError.unreadableImage
        }

        let longestEdge = max(pixelSize.width, pixelSize.height)
        let limit = Int(maximumDimension)
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: min(longestEdge, limit)
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
            throw PlantPhotoError.unreadableImage
        }

        let image = UIImage(cgImage: thumbnail)
        guard let output = image.jpegData(compressionQuality: compressionQuality) else {
            throw PlantPhotoError.unreadableImage
        }
        return output
    }

    /// Reads pixel dimensions from the image container without decoding pixels.
    private static func sourcePixelSize(of source: CGImageSource) -> (width: Int, height: Int) {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return (0, 0)
        }
        return (width, height)
    }
}
