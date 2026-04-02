import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'widgets/stat_card.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/network/sync_service.dart';
import '../../patients/domain/patient_model.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<Patient> _patients = [];
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupAutoSync();
  }

  void _setupAutoSync() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final hasInternet = results.any((r) => r != ConnectivityResult.none);
      if (hasInternet && _patients.any((p) => !p.isSynced)) {
        await ref.read(syncServiceProvider).syncOfflinePatients();
        if (mounted) _loadData();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _loadData() {
    final hiveService = ref.read(hiveServiceProvider);
    setState(() {
      _patients = hiveService.patientsBox.values
          .map((e) => e as Patient)
          .toList()
        ..sort((a, b) => b.registeredAt.compareTo(a.registeredAt));
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalPatients = _patients.length;
    final criticalPatients =
        _patients.where((p) => p.severity == 'Critical').length;
    final moderatePatients =
        _patients.where((p) => p.severity == 'Moderate').length;
    final minorPatients = _patients.where((p) => p.severity == 'Minor').length;
    final criticalList =
        _patients.where((p) => p.severity == 'Critical').toList();

    // Chart Data
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last7Days =
        List.generate(7, (index) => today.subtract(Duration(days: 6 - index)));

    final countsPerDay = List.generate(7, (index) {
      final targetDate = last7Days[index];
      return _patients.where((p) {
        final regDate = DateTime(
            p.registeredAt.year, p.registeredAt.month, p.registeredAt.day);
        return regDate.isAtSameMomentAs(targetDate);
      }).length;
    });

    final maxCount = countsPerDay.isEmpty
        ? 10
        : countsPerDay.reduce((a, b) => a > b ? a : b);
    final chartMaxY = (maxCount < 10 ? 10 : maxCount).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              context.push('/settings');
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Badge(
                isLabelVisible: _patients.any((p) => !p.isSynced),
                label: Text('${_patients.where((p) => !p.isSynced).length}'),
                child: Icon(
                  _patients.any((p) => !p.isSynced)
                      ? Icons.cloud_sync_outlined
                      : Icons.cloud_done_outlined,
                  color: _patients.any((p) => !p.isSynced)
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Patients',
            onPressed: () {
              context.push('/search'); // Will implement next
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Register Patient',
            onPressed: () async {
              await context.push('/register');
              if (!context.mounted) return;
              _loadData();
            },
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Overview',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total',
                          value: totalPatients.toString(),
                          icon: Icons.people,
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () => context.push('/search'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: 'Critical',
                          value: criticalPatients.toString(),
                          icon: Icons.warning_rounded,
                          color: Theme.of(context).colorScheme.error,
                          onTap: () => context.push('/search'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Moderate',
                          value: moderatePatients.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: Colors.orange,
                          onTap: () => context.push('/search'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: StatCard(
                          title: 'Minor',
                          value: minorPatients.toString(),
                          icon: Icons.healing,
                          color: Colors.green,
                          onTap: () => context.push('/search'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text('Patient Load',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: chartMaxY,
                            barTouchData: const BarTouchData(enabled: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget:
                                      (double value, TitleMeta meta) {
                                    const style = TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12);
                                    final int index = value.toInt();
                                    if (index < 0 || index >= 7) {
                                      return const SizedBox.shrink();
                                    }

                                    final date = last7Days[index];
                                    final isToday =
                                        index == 6; // last element is today
                                    final text = isToday
                                        ? 'Today'
                                        : DateFormat('E').format(date);

                                    return SideTitleWidget(
                                        meta: meta,
                                        child: Text(text, style: style));
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: const FlGridData(show: false),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(7, (index) {
                              return BarChartGroupData(
                                x: index,
                                barRods: [
                                  BarChartRodData(
                                    toY: countsPerDay[index].toDouble(),
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    width: 16,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Critical Alerts',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                  const SizedBox(height: 8),
                  if (criticalList.isEmpty)
                    Card(
                        child: ListTile(
                            title: Text('No critical patients currently.',
                                style: Theme.of(context).textTheme.bodyMedium)))
                  else
                    ...criticalList.map((p) => Card(
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withValues(alpha: 0.1),
                          elevation: 0,
                          child: ListTile(
                            leading: Icon(Icons.emergency,
                                color: Theme.of(context).colorScheme.error),
                            title: Text('${p.name} - ${p.gender}, ${p.age}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(p.injuries),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await context.push('/patient/${p.id}');
                              _loadData();
                            },
                          ),
                        )),
                  const SizedBox(height: 32),
                  Text('Recent Patients',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  if (_patients.isEmpty)
                    Card(
                        child: ListTile(
                            title: Text('No patients registered yet.',
                                style:
                                    Theme.of(context).textTheme.bodyMedium))),
                  ..._patients
                      .map((p) => Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                child: Icon(Icons.person,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                              title: Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  'Added ${DateFormat('MMMd HH:mm').format(p.registeredAt)}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(p.severity,
                                      style: TextStyle(
                                          color: p.severity == 'Critical'
                                              ? Colors.red
                                              : (p.severity == 'Moderate'
                                                  ? Colors.orange
                                                  : Colors.green),
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Icon(
                                    p.isSynced
                                        ? Icons.cloud_done
                                        : Icons.cloud_off,
                                    size: 16,
                                    color:
                                        p.isSynced ? Colors.blue : Colors.grey,
                                  ),
                                ],
                              ),
                              onTap: () async {
                                await context.push('/patient/${p.id}');
                                _loadData();
                              },
                            ),
                          ))
                      .toList(),
                  const SizedBox(height: 40),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: Text(
                        '© Twirwaneho Technologies',
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/register');
          _loadData();
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
