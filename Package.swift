// swift-tools-version: 6.2

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/11/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PackageDescription

/// Cancellable change monitoring for Observation values, notifications and preferences, with its tests.
let package = Package(
  name: "ChangeMonitoring",

  platforms: [
    .macOS("26.0"), .iOS("26.0"), .tvOS("26.0"), .watchOS("26.0"),
  ],

  products: [
    .library(
      name: "ChangeMonitoring",
      targets: ["ChangeMonitoring"]
    )
  ],

  targets: [
    .target(
      name: "ChangeMonitoring"
    ),
    .testTarget(
      name: "ChangeMonitoringTests",
      dependencies: ["ChangeMonitoring"]
    ),
  ]
)

for target in package.targets {
  switch target.type {
    case .regular:
      var settings = target.swiftSettings ?? []
      settings.append(contentsOf: [
        .defaultIsolation(MainActor.self),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableExperimentalFeature("SendableProhibitsMainActorInference"),
      ])
      target.swiftSettings = settings
    case .test:
      var settings = target.swiftSettings ?? []
      settings.append(contentsOf: [
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableExperimentalFeature("SendableProhibitsMainActorInference"),
      ])
      target.swiftSettings = settings
    default:
      continue
  }
}
