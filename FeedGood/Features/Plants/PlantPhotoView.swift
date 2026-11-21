import SwiftUI
import UIKit

/// Renders a plant's stored photo, or the garden placeholder when there is none.
/// Callers set the frame and clipping shape.
struct PlantPhotoView: View {
    let photoData: Data?

    var body: some View {
        if let photoData, let image = UIImage(data: photoData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                FeedGoodTheme.mist
                Image(systemName: "leaf.fill")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(FeedGoodTheme.moss)
                    .rotationEffect(.degrees(-24))
            }
        }
    }
}
