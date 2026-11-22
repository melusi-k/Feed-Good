# Feed Good App Icon

The app icon is a simple potted plant with two leaves, no lettering, and a warm ivory canvas. iOS applies the platform icon mask; the source artwork therefore remains a full-bleed square.

## Source and build output

- `FeedGood/Assets.xcassets/AppIcon.appiconset/FeedGood-AppIcon.svg` is the editable vector source.
- `FeedGood/Assets.xcassets/AppIcon.appiconset/FeedGood-AppIcon.png` is generated at 1024 × 1024 pixels for the iOS app icon asset catalog.
- `Contents.json` declares the universal iOS 1024 × 1024 icon entry.

Run `scripts/generate-app-icon.sh` after changing the SVG. It uses CairoSVG to regenerate the PNG. The Build IPA workflow runs this script before XcodeGen and the Xcode build.

The 1024 × 1024 universal asset is the current Xcode asset-catalog format; Xcode generates the device-specific renditions. Separate legacy 20/29/40/60-point files are not required for this format.
