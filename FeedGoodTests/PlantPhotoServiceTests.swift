import Foundation
import Testing
import UIKit
@testable import FeedGood

struct PlantPhotoServiceTests {
    private func makePNG(width: CGFloat, height: CGFloat) -> Data {
        let size = CGSize(width: width, height: height)
        // Scale 1 keeps point size == pixel size, so assertions about the
        // stored photo's dimensions are deterministic.
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            UIColor.green.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.pngData() ?? Data()
    }

    @Test func oversizedPhotoIsDownscaledToMaximumDimension() throws {
        let raw = makePNG(width: 2400, height: 1200)

        let prepared = try PlantPhotoService.prepareForStorage(raw)

        let image = try #require(UIImage(data: prepared))
        #expect(abs(image.size.width - PlantPhotoService.maximumDimension) <= 1)
        #expect(abs(image.size.height - PlantPhotoService.maximumDimension / 2) <= 1)
    }

    @Test func smallPhotoKeepsItsDimensions() throws {
        let raw = makePNG(width: 400, height: 300)

        let prepared = try PlantPhotoService.prepareForStorage(raw)

        let image = try #require(UIImage(data: prepared))
        #expect(abs(image.size.width - 400) <= 1)
        #expect(abs(image.size.height - 300) <= 1)
    }

    @Test func preparedPhotoIsJPEGData() throws {
        let raw = makePNG(width: 100, height: 100)

        let prepared = try PlantPhotoService.prepareForStorage(raw)

        // JPEG magic bytes FF D8 FF.
        #expect(Array(prepared.prefix(3)) == [0xFF, 0xD8, 0xFF])
    }

    @Test func unreadableDataThrows() {
        let notAnImage = Data([0x00, 0x01, 0x02, 0x03])

        #expect {
            try PlantPhotoService.prepareForStorage(notAnImage)
        } throws: { error in
            error as? PlantPhotoError == .unreadableImage
        }
    }
}
