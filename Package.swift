// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoonlightLocationGuard",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "MoonlightLocationGuard", targets: ["MoonlightLocationGuard"])],
    targets: [.executableTarget(name: "MoonlightLocationGuard")]
)
