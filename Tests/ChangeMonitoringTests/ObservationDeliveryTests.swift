// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/03/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Testing

@testable import ChangeMonitoring

/// Tests callback delivery using explicit signals from the actual handler.
@MainActor
@Suite(.timeLimit(.minutes(1)))
struct ObservationDeliveryTests {
  /// Sequential mutations each deliver their updated value.
  @Test
  func sequentialChangesDeliverCallbacks() async {
    let source = ObservableValue()
    let (values, delivered) = AsyncStream.makeStream(of: Int.self)
    var iterator = values.makeAsyncIterator()
    let token = onChange(of: source.value) { delivered.yield($0) }
    defer { token.cancel() }

    source.value = 1
    #expect(await iterator.next() == 1)
    source.value = 2
    #expect(await iterator.next() == 2)
  }

  /// Same-turn mutations coalesce into delivery of the latest value.
  @Test
  func mutationsCoalesce() async {
    let source = ObservableValue()
    let (values, delivered) = AsyncStream.makeStream(of: Int.self)
    var iterator = values.makeAsyncIterator()
    let token = onChange(of: source.value) { delivered.yield($0) }
    defer { token.cancel() }

    source.value = 1
    source.value = 2
    #expect(await iterator.next() == 2)
  }

  /// Cancelling from a handler stops delivery of later mutations.
  @Test
  func handlerCanCancelObservation() async {
    let source = ObservableValue()
    let (values, delivered) = AsyncStream.makeStream(of: Int.self)
    var iterator = values.makeAsyncIterator()
    var received: [Int] = []
    var token: ObservationToken?
    token = onChange(of: source.value) { value in
      token?.cancel()
      received.append(value)
      delivered.yield(value)
    }

    source.value = 1
    #expect(await iterator.next() == 1)
    source.value = 2
    await drainDelivery(from: source)
    #expect(received == [1])
  }

  /// Dropping the last reference to the token stops delivery.
  @Test
  func droppedTokenStopsObserving() async {
    let source = ObservableValue()
    var received: [Int] = []
    var token: ObservationToken? = onChange(of: source.value) { received.append($0) }
    #expect(token != nil)
    token = nil

    source.value = 1
    await drainDelivery(from: source)
    #expect(received.isEmpty)
  }

  /// Waits until every delivery queued by earlier mutations of the source has run.
  ///
  /// A sentinel observer is installed after those mutations and triggered by a
  /// further one. The main actor runs queued deliveries in order, so the
  /// sentinel's callback follows any delivery the earlier mutations scheduled.
  private func drainDelivery(
    from source: ObservableValue,
    sourceLocation: SourceLocation = #_sourceLocation
  ) async {
    let (values, delivered) = AsyncStream.makeStream(of: Int.self)
    var iterator = values.makeAsyncIterator()
    let sentinel = onChange(of: source.value) { delivered.yield($0) }
    defer { sentinel.cancel() }

    source.value += 1
    #expect(await iterator.next() == source.value, sourceLocation: sourceLocation)
  }
}
