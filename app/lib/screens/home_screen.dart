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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deep_link_event.dart';
import '../providers/deep_link_provider.dart';
import '../widgets/about_dialog_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final TextEditingController _schemeController;

  @override
  void initState() {
    super.initState();
    final currentScheme = ref.read(protocolRegistrationProvider).scheme;
    _schemeController = TextEditingController(text: currentScheme);
  }

  @override
  void dispose() {
    _schemeController.dispose();
    super.dispose();
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => const CustomAboutDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deepLinkState = ref.watch(deepLinkNotifierProvider);
    final regState = ref.watch(protocolRegistrationProvider);
    final latestEvent = deepLinkState.latestEvent;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link_rounded, size: 28),
            SizedBox(width: 10),
            Text('DeepLink Test Bench', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'About DeepLink Test Bench',
            onPressed: _showAboutDialog,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 800;

          final leftColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStatusCard(context, latestEvent),
              const SizedBox(height: 16),
              _buildParsedDetailsCard(context, latestEvent),
              const SizedBox(height: 16),
              _buildRegistrationCard(context, regState),
            ],
          );

          final rightColumn = _buildLogCard(context, deepLinkState);

          if (isNarrow) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  leftColumn,
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 400,
                    child: rightColumn,
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: SingleChildScrollView(child: leftColumn),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: rightColumn,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, DeepLinkEvent? latestEvent) {
    final hasReceived = latestEvent != null;
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'Current Deep-Link State',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  avatar: Icon(
                    hasReceived ? Icons.check_circle : Icons.hourglass_empty_rounded,
                    size: 16,
                    color: hasReceived ? Colors.green.shade700 : Colors.orange.shade700,
                  ),
                  label: Text(
                    hasReceived ? 'Received' : 'Waiting...',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: hasReceived ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                  backgroundColor:
                      hasReceived ? Colors.green.shade50 : Colors.orange.shade50,
                  side: BorderSide(
                    color: hasReceived ? Colors.green.shade200 : Colors.orange.shade200,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Last Raw URI:',
              style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      latestEvent?.rawUri ?? 'No deep link received yet.',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        color: hasReceived
                            ? theme.colorScheme.onSurface
                            : Colors.grey.shade500,
                        fontStyle: hasReceived ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ),
                  if (hasReceived)
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Copy URI',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: latestEvent.rawUri));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('URI copied to clipboard')),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParsedDetailsCard(BuildContext context, DeepLinkEvent? latestEvent) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Parsed Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (latestEvent == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'Waiting for incoming URI scheme event...',
                    style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else ...[
              _buildDetailRow(context, 'Scheme', latestEvent.scheme),
              _buildDetailRow(context, 'Host', latestEvent.host),
              _buildDetailRow(context, 'Path', latestEvent.path.isEmpty ? '/' : latestEvent.path),
              _buildDetailRow(
                context,
                'Event Type',
                latestEvent.isInitialLink ? 'COLD START (INITIAL)' : 'WARM START (SINGLE INSTANCE)',
                highlight: true,
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Query Parameters:',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (latestEvent.queryParams.isEmpty)
                Text(
                  'None',
                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: latestEvent.queryParams.entries.map((entry) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const Text(' = '),
                            Expanded(
                              child: SelectableText(
                                entry.value,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
                color: highlight ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationCard(
      BuildContext context, ProtocolRegistrationState regState) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings_suggest_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'OS Protocol Registration',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Protocol scheme text field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _schemeController,
                    decoration: const InputDecoration(
                      labelText: 'Custom URI Scheme',
                      hintText: 'e.g. myapp',
                      prefixText: 'Scheme: ',
                      suffixText: '://',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (val) {
                      ref.read(protocolRegistrationProvider.notifier).setScheme(val.trim());
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.outlined(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh Status',
                  onPressed: () {
                    ref.read(protocolRegistrationProvider.notifier).refreshStatus();
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Live Status Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  if (regState.isLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Expanded(
                      child: Text(
                        regState.status,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: regState.status.contains('Registered')
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.app_registration_rounded),
                  label: const Text('Register Protocol'),
                  onPressed: regState.isLoading
                      ? null
                      : () async {
                          final success = await ref
                              .read(protocolRegistrationProvider.notifier)
                              .register();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Successfully registered protocol ${regState.scheme}://'
                                      : 'Failed to register protocol',
                                ),
                              ),
                            );
                          }
                        },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Unregister'),
                  onPressed: regState.isLoading
                      ? null
                      : () async {
                          final success = await ref
                              .read(protocolRegistrationProvider.notifier)
                              .unregister();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Unregistered protocol ${regState.scheme}://'
                                      : 'Failed to unregister protocol',
                                ),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, DeepLinkState deepLinkState) {
    final theme = Theme.of(context);
    final events = deepLinkState.events;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.history_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Deep Link Log',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${events.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: const Text('Clear Log'),
                  onPressed: events.isEmpty
                      ? null
                      : () {
                          ref.read(deepLinkNotifierProvider.notifier).clearLog();
                        },
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Expanded(
              child: events.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No deep links recorded in this session',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return _buildLogItem(context, event);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(BuildContext context, DeepLinkEvent event) {
    final theme = Theme.of(context);
    final isInitial = event.isInitialLink;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isInitial ? Colors.blue.shade200 : Colors.purple.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                label: Text(isInitial ? 'INITIAL (COLD)' : 'RECEIVED (WARM)'),
                backgroundColor: isInitial ? Colors.blue.shade50 : Colors.purple.shade50,
                side: BorderSide(
                  color: isInitial ? Colors.blue.shade300 : Colors.purple.shade300,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    event.formattedTimestamp,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            event.rawUri,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (event.queryParams.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: event.queryParams.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${e.key}=${e.value}',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
