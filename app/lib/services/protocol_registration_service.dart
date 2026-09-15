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

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:win32_registry/win32_registry.dart';

abstract class ProtocolRegistrationService {
  Future<bool> register(String scheme);
  Future<bool> unregister(String scheme);
  Future<String> getStatus(String scheme);

  factory ProtocolRegistrationService() {
    if (kIsWeb) {
      return UnsupportedProtocolRegistrationService();
    }
    if (Platform.isWindows) {
      return WindowsProtocolRegistrationService();
    } else if (Platform.isMacOS) {
      return MacOsProtocolRegistrationService();
    } else if (Platform.isLinux) {
      return LinuxProtocolRegistrationService();
    } else {
      return UnsupportedProtocolRegistrationService();
    }
  }
}

class WindowsProtocolRegistrationService implements ProtocolRegistrationService {
  @override
  Future<bool> register(String scheme) async {
    try {
      final sanitizedScheme = _sanitizeScheme(scheme);
      if (sanitizedScheme.isEmpty) return false;

      final exePath = Platform.resolvedExecutable;
      final rootPath = 'Software\\Classes\\$sanitizedScheme';

      final key = CURRENT_USER.create(rootPath);
      key.setValue('', RegistryValue.string('URL:$sanitizedScheme Protocol'));
      key.setValue('URL Protocol', const RegistryValue.string(''));
      key.close();

      final commandKey = CURRENT_USER.create('$rootPath\\shell\\open\\command');
      commandKey.setValue('', RegistryValue.string('"$exePath" "%1"'));
      commandKey.close();

      return true;
    } catch (e) {
      debugPrint('Windows protocol registration failed: $e');
      return false;
    }
  }

  @override
  Future<bool> unregister(String scheme) async {
    try {
      final sanitizedScheme = _sanitizeScheme(scheme);
      if (sanitizedScheme.isEmpty) return false;

      final rootPath = 'Software\\Classes\\$sanitizedScheme';
      
      try {
        CURRENT_USER.removeSubkey(rootPath);
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('Windows protocol unregistration failed: $e');
      return false;
    }
  }

  @override
  Future<String> getStatus(String scheme) async {
    try {
      final sanitizedScheme = _sanitizeScheme(scheme);
      if (sanitizedScheme.isEmpty) return 'Invalid scheme';

      final commandPath = 'Software\\Classes\\$sanitizedScheme\\shell\\open\\command';
      final val = CURRENT_USER.getString('', path: commandPath);
      if (val != null && val.isNotEmpty) {
        return 'Registered ($sanitizedScheme://)';
      }
      return 'Not Registered';
    } catch (_) {
      return 'Not Registered';
    }
  }

  String _sanitizeScheme(String scheme) {
    return scheme.replaceAll(RegExp(r'[^a-zA-Z0-9\+\-\.]'), '').toLowerCase();
  }
}

class MacOsProtocolRegistrationService implements ProtocolRegistrationService {
  @override
  Future<bool> register(String scheme) async {
    return true;
  }

  @override
  Future<bool> unregister(String scheme) async {
    return true;
  }

  @override
  Future<String> getStatus(String scheme) async {
    return 'Configured by application bundle';
  }
}

class LinuxProtocolRegistrationService implements ProtocolRegistrationService {
  @override
  Future<bool> register(String scheme) async {
    try {
      final sanitizedScheme = scheme.replaceAll(RegExp(r'[^a-zA-Z0-9\+\-\.]'), '').toLowerCase();
      final exePath = Platform.resolvedExecutable;
      final home = Platform.environment['HOME'] ?? '';
      if (home.isEmpty) return false;

      final appsDir = Directory('$home/.local/share/applications');
      if (!await appsDir.exists()) {
        await appsDir.create(recursive: true);
      }

      final desktopFile = File('${appsDir.path}/$sanitizedScheme-handler.desktop');
      final desktopContent = '''
[Desktop Entry]
Type=Application
Name=$sanitizedScheme DeepLink Handler
Exec=$exePath %u
StartupNotify=false
MimeType=x-scheme-handler/$sanitizedScheme;
''';

      await desktopFile.writeAsString(desktopContent);

      final result = await Process.run('xdg-mime', [
        'default',
        '$sanitizedScheme-handler.desktop',
        'x-scheme-handler/$sanitizedScheme',
      ]);

      return result.exitCode == 0;
    } catch (e) {
      debugPrint('Linux protocol registration failed: $e');
      return false;
    }
  }

  @override
  Future<bool> unregister(String scheme) async {
    try {
      final sanitizedScheme = scheme.replaceAll(RegExp(r'[^a-zA-Z0-9\+\-\.]'), '').toLowerCase();
      final home = Platform.environment['HOME'] ?? '';
      if (home.isEmpty) return false;

      final desktopFile = File('$home/.local/share/applications/$sanitizedScheme-handler.desktop');
      if (await desktopFile.exists()) {
        await desktopFile.delete();
      }
      return true;
    } catch (e) {
      debugPrint('Linux protocol unregistration failed: $e');
      return false;
    }
  }

  @override
  Future<String> getStatus(String scheme) async {
    try {
      final sanitizedScheme = scheme.replaceAll(RegExp(r'[^a-zA-Z0-9\+\-\.]'), '').toLowerCase();
      final home = Platform.environment['HOME'] ?? '';
      if (home.isEmpty) return 'Not Registered';

      final desktopFile = File('$home/.local/share/applications/$sanitizedScheme-handler.desktop');
      if (await desktopFile.exists()) {
        return 'Registered ($sanitizedScheme://)';
      }
      return 'Not Registered';
    } catch (_) {
      return 'Not Registered';
    }
  }
}

class UnsupportedProtocolRegistrationService implements ProtocolRegistrationService {
  @override
  Future<bool> register(String scheme) async => false;

  @override
  Future<bool> unregister(String scheme) async => false;

  @override
  Future<String> getStatus(String scheme) async => 'Platform unsupported';
}
