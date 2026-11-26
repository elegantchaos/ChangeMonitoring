// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/10/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Testing

@testable import ChangeMonitoring

/// Checks notification filtering, defaults wiring, and explicit observer lifetime.
@MainActor
struct NotificationTests {
  /// Only matching names and objects deliver; cancellation stops delivery.
  @Test
  func filtersAndCancelsNotifications() {
    let center = NotificationCenter()
    let source = NSObject()
    let name = Notification.Name("ApplicationTests.change")
    var calls = 0
    let token = center.onNotification(named: name, object: source) { calls += 1 }
    center.post(name: name, object: NSObject())
    center.post(name: Notification.Name("ApplicationTests.other"), object: source)
    #expect(calls == 0)
    center.post(name: name, object: source)
    #expect(calls == 1)
    token.cancel()
    token.cancel()
    center.post(name: name, object: source)
    #expect(calls == 1)
  }

  /// Destroying the notification token unregisters its callback.
  @Test
  func droppingTokenStopsNotifications() {
    let center = NotificationCenter()
    let name = Notification.Name("ApplicationTests.release")
    var calls = 0
    var token: NotificationToken? = center.onNotification(named: name) { calls += 1 }
    weak let releasedToken = token
    center.post(name: name, object: nil)
    #expect(calls == 1)
    token = nil
    #expect(releasedToken == nil)
    center.post(name: name, object: nil)
    #expect(calls == 1)
  }

  /// Initial delivery is optional and later notifications filter by defaults instance.
  @Test(arguments: [false, true])
  func defaultsInitialDeliveryAndFiltering(initial: Bool) {
    let defaults = UserDefaults()
    var calls = 0
    let token = defaults.onChange(initial: initial) { received in
      #expect(received === defaults)
      calls += 1
    }
    #expect(calls == (initial ? 1 : 0))
    NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: UserDefaults())
    #expect(calls == (initial ? 1 : 0))
    NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: defaults)
    #expect(calls == (initial ? 2 : 1))
    token.cancel()
    NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: defaults)
    #expect(calls == (initial ? 2 : 1))
  }

  /// Writes through the observed instance are reported; writes through another instance of the same suite are not.
  @Test
  func defaultsReportWritesThroughTheObservedInstance() throws {
    let suite = "ApplicationTests.\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suite))
    let otherInstance = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    var calls = 0
    let token = defaults.onChange { _ in calls += 1 }
    defer { token.cancel() }

    otherInstance.set(1, forKey: "value")
    #expect(defaults.integer(forKey: "value") == 1)
    #expect(calls == 0)

    defaults.set(2, forKey: "value")
    #expect(calls == 1)
  }
}
