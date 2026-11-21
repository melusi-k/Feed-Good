import XCTest
import UIKit
@testable import FeedGood

final class PlantPhotoServiceTests: XCTestCase {
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

    func testOversizedPhotoIsDownscaledToMaximumDimension() throws {
        let raw = makePNG(width: 2400, height: 1200)

        let prepared = try PlantPhotoService.prepareForStorage(raw)

        let image = try XCTUnwrap(UIImage(data: prepared))
        XCTAssertEqual(image.size.width, PlantPhotoService.maximumDimension, accuracy: 1)
        XCTAssertEqual(image.size.height, PlantPhotoService.maximumDimension / 2, accuracy: 1)
    }

    func testSmallPhotoKeepsItsDimensions() throws {
        let raw = makePNG(width: 400, height: 300)

        let prepared = try PlantPhotoService.prepareForStorage(raw)

        let image = try XCTUnwrap(UIImage(data: prepared))
        XCTAssertEqual(image.size.width, 400, accuracy: 1)
        XCTAssertEqual(image.size.height, 300, accuracy: 1)
    }

    func testPreparedPhotoIsJPEGData() throws {
        let raw = makePNG(width: 100, height: 100)

        let prepared = try PlantPhotoService.prepareForStorage(raw)

        // JPEG magic bytes FF D8 FF.
        XCTAssertEqual(Array(prepared.prefix(3)), [0xFF, 0xD8, 0xFF])
    }

    func testUnreadableDataThrows() {
        let notAnImage = Data([0x00, 0x01, 0x02, 0x03])

        XCTAssertThrowsError(try PlantPhotoService.prepareForStorage(notAnImage)) { error in
            XCTAssertEqual(error as? PlantPhotoError, .unreadableImage)
        }
    }
}
