// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/03/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Observation

/// Observes a main-actor value and delivers its latest value after a mutation.
///
/// Delivery hops to the main actor; mutations before delivery can coalesce into
/// one callback. Mutations performed by the handler precede the next tracking
/// pass and do not trigger an additional callback.
///
/// Retain the returned token for as long as delivery is wanted. Releasing the
/// last reference, or calling `cancel()`, stops delivery and releases the value
/// reader and callback, together with anything they capture. Both the value
/// reader and callback run on the main actor.
@MainActor
public func onChange<Value>(
  of value: @escaping @autoclosure @MainActor @Sendable () -> Value,
  perform: @escaping @MainActor @Sendable (Value) -> Void
) -> ObservationToken {
  let token = ObservationToken()
  token.install {
    [weak token] in
    guard let token else { return }
    withObservationTracking {
      _ = value()
    } onChange: { [weak token] in
      // Observation keeps this handler until the next mutation. Holding the
      // token weakly leaves the caller's reference as the only owner, so
      // dropping it releases the value reader and callback immediately.
      Task { @MainActor [weak token] in
        token?.didChange()
      }
    }
  } handler: {
    perform(value())
  }
  return token
}
