# Split From Application

The change-monitoring helpers moved here from the Application package, which now holds only the application lifecycle and is being renamed AppLifecycle. The two halves shared no code or state, and keeping them together made non-UI consumers link SwiftUI and the lifecycle to use one observation helper. ActionStatus's `Core` module, which imports Application only for `onChange(of:perform:)`, was the concrete case.

The sources and tests are copied from Application's `feature/startup-modes-investigation` branch at [`7d844f5`](https://github.com/elegantchaos/Application/tree/7d844f5df2752610935a101574b7b37a9a88b80e), with their history left in that repository. That revision already included the full-review fixes: the caller's `ObservationToken` is the only owner of an observation, `onChange(of:perform:)` is no longer discardable, and `UserDefaults.onChange` documents and tests that it reports writes through the observed instance only. The [Application journal](https://github.com/elegantchaos/Application/tree/7d844f5df2752610935a101574b7b37a9a88b80e/Extras/Journal) records that work.

The package restarts at version 1.0. The delivery test suite is now `ObservationDeliveryTests`, so that no type shares the module's name. The package keeps Application's platforms, macOS, iOS, tvOS and watchOS 26, and its main-actor default isolation.
