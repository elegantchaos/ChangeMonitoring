// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/10/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Observation
import Testing

@testable import ChangeMonitoring

/// Verifies cancellation releases resources even when no later mutation occurs.
@MainActor
struct ObservationLifetimeTests {
  /// Cancellation releases the callback independently of the observed source.
  @Test(arguments: [false, true])
  func cancellationReleasesCallback(withPendingDelivery: Bool) {
    let source = ObservableValue()
    var owner: ObservableValue? = ObservableValue()
    weak let releasedOwner = owner
    let token = onChange(of: source.value) { [captured = owner] value in
      captured?.value = value
    }
    owner = nil
    #expect(releasedOwner != nil)
    if withPendingDelivery {
      source.value = 1
    }
    token.cancel()
    #expect(releasedOwner == nil)
    token.cancel()
  }

  /// Cancellation also releases the autoclosure's observed source.
  @Test
  func cancellationReleasesValueReader() throws {
    var source: ObservableValue? = ObservableValue()
    weak let releasedSource = source
    let token = observe(try #require(source))
    source = nil
    token.cancel()
    #expect(releasedSource == nil)
  }

  /// Dropping the token releases it, its callback, and the observed source without a later mutation.
  @Test
  func droppingTokenReleasesResources() throws {
    var source: ObservableValue? = ObservableValue()
    var owner: ObservableValue? = ObservableValue()
    weak let releasedSource = source
    weak let releasedOwner = owner
    var token: ObservationToken? = observe(try #require(source), retaining: try #require(owner))
    weak let releasedToken = token
    source = nil
    owner = nil
    #expect(releasedToken != nil)

    token = nil
    #expect(releasedToken == nil)
    #expect(releasedSource == nil)
    #expect(releasedOwner == nil)
  }

  /// Observes the source with a callback that keeps the owner alive.
  private func observe(_ source: ObservableValue, retaining owner: ObservableValue) -> ObservationToken {
    onChange(of: source.value) { value in owner.value = value }
  }

  /// Captures the source by value so only the observation keeps it alive.
  private func observe(_ source: ObservableValue) -> ObservationToken {
    onChange(of: source.value) { _ in }
  }
}
