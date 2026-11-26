// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/03/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

/// Owns the value reader and callback for an installed observation loop.
///
/// The caller's reference is the only one that keeps observation alive. Store
/// the token with the object whose lifetime the observation should follow.
/// Releasing it, or calling `cancel()`, stops delivery and releases the value
/// reader and callback, together with anything they capture.
@MainActor
public final class ObservationToken {
  /// Whether this token has permanently stopped monitoring.
  private var isCancelled = false

  /// Installs the next tracking pass without retaining this token itself.
  private var observation: (@MainActor @Sendable () -> Void)?

  /// Reads the current value and delivers it to the caller.
  private var handler: (@MainActor @Sendable () -> Void)?

  /// Creates an active token without an installed observation.
  public init() {}

  /// Stops future callbacks and releases the value reader and handler immediately.
  public func cancel() {
    isCancelled = true
    observation = nil
    handler = nil
  }

  /// Takes ownership of the callbacks and installs the first tracking pass.
  func install(
    observation: @escaping @MainActor @Sendable () -> Void,
    handler: @escaping @MainActor @Sendable () -> Void
  ) {
    guard !isCancelled else { return }
    self.observation = observation
    self.handler = handler
    observation()
  }

  /// Delivers a mutation and tracks the next change unless the handler cancelled.
  func didChange() {
    handler?()
    observation?()
  }
}
