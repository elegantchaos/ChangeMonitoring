// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/03/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public extension UserDefaults {
  /// Calls the supplied action after a write through this instance.
  ///
  /// Only writes made through this `UserDefaults` object in the current process
  /// are reported. Writes through another instance, even one opened for the
  /// same suite, and writes from other processes produce no callback although
  /// their values are readable here. Share one instance between writers and
  /// observers. Pass `initial: true` to call the action once immediately.
  ///
  /// Retain the returned token while monitoring is wanted; releasing or
  /// cancelling it removes the observer.
  @MainActor
  func onChange(initial: Bool = false, _ action: @escaping @MainActor (UserDefaults) -> Void) -> NotificationToken {
    if initial {
      action(self)
    }

    return NotificationCenter.default.onNotification(
      named: UserDefaults.didChangeNotification,
      object: self
    ) {
      action(self)
    }
  }
}
