// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "DZNetworking",
  platforms: [.iOS(.v13), .macOS(.v10_15), .watchOS(.v6), .tvOS(.v12)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "DZNetworking",
      type: .dynamic,
      targets: ["DZNetworking"]
    ),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "DZNetworking",
      dependencies: [
        
      ],
      path: "Sources/DZNetworking",
      exclude: [],
      publicHeadersPath: ""
    ),
    .testTarget(
      name: "DZNetworkingTests",
      dependencies: ["DZNetworking"]),
  ]
)

/**
 
 exclude: [
 "Info.plist",
 "DZNetworkingTests"
 ],
 sources: ["Core", "Utilities", "Vendors", "ResponseParsers"],
 cSettings: [
 .headerSearchPath("Core"),
 .headerSearchPath("Utilities"),
 .headerSearchPath("Vendors"),
 .headerSearchPath("ResponseParsers")
 ]
 */
