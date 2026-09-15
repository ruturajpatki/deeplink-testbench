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

import 'package:flutter/foundation.dart';

@immutable
class DeepLinkEvent {
  final Uri uri;
  final DateTime timestamp;
  final bool isInitialLink;

  DeepLinkEvent({
    required this.uri,
    required this.isInitialLink,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  String get rawUri => uri.toString();
  String get scheme => uri.scheme;
  String get host => uri.host;
  String get path => uri.path;
  Map<String, String> get queryParams => uri.queryParameters;

  String get formattedTimestamp {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeepLinkEvent &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          timestamp == other.timestamp &&
          isInitialLink == other.isInitialLink;

  @override
  int get hashCode => uri.hashCode ^ timestamp.hashCode ^ isInitialLink.hashCode;

  @override
  String toString() {
    return 'DeepLinkEvent(uri: $uri, isInitialLink: $isInitialLink, timestamp: $formattedTimestamp)';
  }
}
