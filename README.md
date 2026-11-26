# ChangeMonitoring

`ChangeMonitoring` is a Swift package for reacting to changes in Observation values, `NotificationCenter` notifications and `UserDefaults`. Each helper returns a token that owns the monitoring: keep the token for as long as you want callbacks, and release or cancel it to stop them.

The package depends only on Foundation and Observation, so it suits model and service code as well as user interface code.

## Observation

`onChange(of:perform:)` tracks a main-actor Observation value and delivers its latest value on the main actor:

```swift
import ChangeMonitoring

@MainActor
final class RefreshService {
  private var authObservation: ObservationToken?

  func connect(to auth: AuthService) {
    authObservation = onChange(of: auth.state) { [weak self] state in
      self?.authStateChanged(state)
    }
  }

  private func authStateChanged(_ state: AuthState) {}
}
```

Mutations before delivery can coalesce into one callback, and mutations made inside the callback precede the next tracking pass. The returned `ObservationToken` owns the observation: store it with the object whose lifetime the observation should follow. Releasing the token, or calling `cancel()`, stops delivery and releases the callback and value reader, together with anything they capture. Overwriting a stored token therefore cancels the previous observation.

## Notifications

`NotificationCenter.onNotification(named:object:perform:)` and `UserDefaults.onChange(initial:_:)` return a `NotificationToken`. Retain the token while monitoring is wanted. Cancelling or releasing it removes the observer. Pass `initial: true` to the defaults helper to call the handler immediately.

The defaults helper reports writes made through the observed `UserDefaults` instance in the current process. A write through another instance, even one opened for the same suite, is readable through the observed instance but produces no callback, and writes from other processes are not reported. Share one instance between the code that writes a setting and the code that observes it.

## Project records

- [Development journal](Extras/Journal/index.md)
- [Decision log](Extras/Decisions/index.md)
