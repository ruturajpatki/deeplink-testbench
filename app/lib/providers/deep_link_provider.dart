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

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deep_link_event.dart';
import '../services/deep_link_service.dart';
import '../services/protocol_registration_service.dart';

@immutable
class DeepLinkState {
  final List<DeepLinkEvent> events;
  final DeepLinkEvent? latestEvent;
  final bool isListening;

  const DeepLinkState({
    this.events = const [],
    this.latestEvent,
    this.isListening = false,
  });

  DeepLinkState copyWith({
    List<DeepLinkEvent>? events,
    DeepLinkEvent? latestEvent,
    bool? isListening,
  }) {
    return DeepLinkState(
      events: events ?? this.events,
      latestEvent: latestEvent ?? this.latestEvent,
      isListening: isListening ?? this.isListening,
    );
  }
}

class DeepLinkNotifier extends Notifier<DeepLinkState> {
  StreamSubscription<Uri>? _subscription;
  Uri? _initialUri;

  @override
  DeepLinkState build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });
    Future.microtask(() => _init());
    return const DeepLinkState();
  }

  Future<void> _init() async {
    final service = ref.read(deepLinkServiceProvider);
    state = state.copyWith(isListening: true);

    // 1. Cold start check
    _initialUri = await service.getInitialLink();
    if (_initialUri != null) {
      addEvent(_initialUri!, isInitialLink: true);
    }

    // 2. Warm start listener
    _subscription = service.uriLinkStream.listen(
      (uri) {
        // Prevent app_links stream from re-emitting the initial cold-start URI on startup
        if (_initialUri != null && uri == _initialUri) {
          _initialUri = null;
          return;
        }
        addEvent(uri, isInitialLink: false);
      },
      onError: (err) {
        debugPrint('Error listening to deep links: $err');
      },
    );
  }

  void addEvent(Uri uri, {required bool isInitialLink}) {
    final newEvent = DeepLinkEvent(
      uri: uri,
      isInitialLink: isInitialLink,
    );
    final updatedList = [newEvent, ...state.events];
    state = state.copyWith(
      events: updatedList,
      latestEvent: newEvent,
    );
  }

  void clearLog() {
    state = state.copyWith(events: []);
  }
}

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService();
});

final deepLinkNotifierProvider =
    NotifierProvider<DeepLinkNotifier, DeepLinkState>(DeepLinkNotifier.new);

// Protocol Registration State
@immutable
class ProtocolRegistrationState {
  final String scheme;
  final String status;
  final bool isLoading;

  const ProtocolRegistrationState({
    this.scheme = 'myapp',
    this.status = 'Checking...',
    this.isLoading = false,
  });

  ProtocolRegistrationState copyWith({
    String? scheme,
    String? status,
    bool? isLoading,
  }) {
    return ProtocolRegistrationState(
      scheme: scheme ?? this.scheme,
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ProtocolRegistrationNotifier
    extends Notifier<ProtocolRegistrationState> {
  @override
  ProtocolRegistrationState build() {
    Future.microtask(() => refreshStatus());
    return const ProtocolRegistrationState();
  }

  void setScheme(String newScheme) {
    state = state.copyWith(scheme: newScheme);
    refreshStatus();
  }

  Future<void> refreshStatus() async {
    final service = ref.read(protocolRegistrationServiceProvider);
    state = state.copyWith(isLoading: true);
    final status = await service.getStatus(state.scheme);
    state = state.copyWith(status: status, isLoading: false);
  }

  Future<bool> register() async {
    final service = ref.read(protocolRegistrationServiceProvider);
    state = state.copyWith(isLoading: true);
    final success = await service.register(state.scheme);
    await refreshStatus();
    return success;
  }

  Future<bool> unregister() async {
    final service = ref.read(protocolRegistrationServiceProvider);
    state = state.copyWith(isLoading: true);
    final success = await service.unregister(state.scheme);
    await refreshStatus();
    return success;
  }
}

final protocolRegistrationServiceProvider =
    Provider<ProtocolRegistrationService>((ref) {
  return ProtocolRegistrationService();
});

final protocolRegistrationProvider = NotifierProvider<
    ProtocolRegistrationNotifier,
    ProtocolRegistrationState>(ProtocolRegistrationNotifier.new);
