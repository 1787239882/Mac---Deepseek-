// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DeepSeekMenubar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "DeepSeekMenubar",
            exclude: ["Resources/Info.plist"]
        )
    ]
)
