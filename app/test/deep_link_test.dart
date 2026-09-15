/*
 * Package: DeeplinkTestbench
 * Author: Ruturaj V Patki
 * Email: ruturajvpatki@zohomail.com
 *
 * Copyright 2026 Ruturaj V Patki
 * Originally authored by Ruturaj V Patki.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deeplink_testbench/models/deep_link_event.dart';
import 'package:deeplink_testbench/providers/deep_link_provider.dart';
import 'package:deeplink_testbench/services/deep_link_service.dart';

class MockDeepLinkService implements DeepLinkService {
  final Uri? initialUri;
  final Stream<Uri> stream;

  MockDeepLinkService({this.initialUri, required this.stream});

  @override
  Future<Uri?> getInitialLink() async => initialUri;

  @override
  Stream<Uri> get uriLinkStream => stream;
}

void main() {
  group('DeepLinkEvent Model Tests', () {
    test('Correctly parses Uri parameters, scheme, host, and path', () {
      final uri = Uri.parse('radx://project.task?pid=7654357788&intent=share');
      final event = DeepLinkEvent(uri: uri, isInitialLink: true);

      expect(event.scheme, equals('radx'));
      expect(event.host, equals('project.task'));
      expect(event.path, equals(''));
      expect(event.queryParams['pid'], equals('7654357788'));
      expect(event.queryParams['intent'], equals('share'));
      expect(event.isInitialLink, isTrue);
      expect(event.rawUri, equals('radx://project.task?pid=7654357788&intent=share'));
    });

    test('Immutability and equality check', () {
      final now = DateTime.now();
      final uri = Uri.parse('radx://test.path?key=value');

      final event1 = DeepLinkEvent(uri: uri, isInitialLink: false, timestamp: now);
      final event2 = DeepLinkEvent(uri: uri, isInitialLink: false, timestamp: now);

      expect(event1, equals(event2));
      expect(event1.hashCode, equals(event2.hashCode));
    });
  });

  group('DeepLinkNotifier Riverpod Tests', () {
    test('Initial cold start link is processed and logged as INITIAL', () async {
      final initialUri = Uri.parse('radx://cold.start?pid=100');
      final service = MockDeepLinkService(
        initialUri: initialUri,
        stream: const Stream.empty(),
      );

      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      // Trigger read to initialize notifier
      container.read(deepLinkNotifierProvider);

      await Future.delayed(Duration.zero);

      final state = container.read(deepLinkNotifierProvider);
      expect(state.events.length, equals(1));
      expect(state.latestEvent?.rawUri, equals('radx://cold.start?pid=100'));
      expect(state.latestEvent?.isInitialLink, isTrue);
    });

    test('Warm start stream events are added to history and tagged as RECEIVED', () async {
      final service = MockDeepLinkService(
        initialUri: null,
        stream: Stream.fromIterable([
          Uri.parse('radx://warm.start?pid=200'),
          Uri.parse('radx://warm.start?pid=300'),
        ]),
      );

      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      container.read(deepLinkNotifierProvider);

      await Future.delayed(Duration.zero);

      final state = container.read(deepLinkNotifierProvider);
      expect(state.events.length, equals(2));
      expect(state.events.first.rawUri, equals('radx://warm.start?pid=300'));
      expect(state.events.first.isInitialLink, isFalse);
      expect(state.events.last.rawUri, equals('radx://warm.start?pid=200'));
      expect(state.events.last.isInitialLink, isFalse);
    });

    test('clearLog removes all recorded events', () async {
      final service = MockDeepLinkService(
        initialUri: Uri.parse('radx://test'),
        stream: const Stream.empty(),
      );

      final container = ProviderContainer(
        overrides: [
          deepLinkServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(deepLinkNotifierProvider.notifier);
      await Future.delayed(Duration.zero);

      expect(container.read(deepLinkNotifierProvider).events.isNotEmpty, isTrue);

      notifier.clearLog();

      final updatedState = container.read(deepLinkNotifierProvider);
      expect(updatedState.events.isEmpty, isTrue);
      expect(updatedState.latestEvent, isNotNull);
    });
  });
}
