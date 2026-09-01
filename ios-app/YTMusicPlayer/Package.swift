// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "YTMusicPlayer",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "YTMusicPlayer",
            targets: ["YTMusicPlayer"]
        )
    ],
    targets: [
        .executableTarget(
            name: "YTMusicPlayer",
            path: ".",
            exclude: ["Info.plist"]
        )
    ]
)
