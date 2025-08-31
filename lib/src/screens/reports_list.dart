import 'dart:async';
import 'package:flutter/material.dart';

import '../models/report.dart';
import '../services/report_service.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  late StreamSubscription<List<Report>> _sub;
  List<Report> _items = [];

  @override
  void initState() {
    super.initState();
    _sub = reportService.stream.listen((v) {
      if (mounted) setState(() => _items = v);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const Center(
        child: Text('No reports yet. Long-press the map to add one.'),
      );
    }

    return ListView.separated(
      itemCount: _items.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (_, i) {
        final r = _items[i];
        return ListTile(
          leading: CircleAvatar(child: Text('S${r.severity}')),
          title: Text(_titleFor(r.type)),
          subtitle: Text(
            [
              if ((r.description ?? '').isNotEmpty) r.description!,
              _formatTime(r.createdAt),
            ].join('\n'),
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (_) => Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_titleFor(r.type),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text('Severity: ${r.severity}'),
                    Text('Lat/Lng: ${r.lat.toStringAsFixed(5)}, '
                        '${r.lng.toStringAsFixed(5)}'),
                    const SizedBox(height: 8),
                    if ((r.description ?? '').isNotEmpty) Text(r.description!),
                    const SizedBox(height: 12),
                    Text('Created: ${_formatTime(r.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _titleFor(HazardType t) {
    switch (t) {
      case HazardType.pothole:
        return 'Pothole';
      case HazardType.waterLogging:
        return 'Water logging';
      case HazardType.accident:
        return 'Accident';
      case HazardType.obstruction:
        return 'Obstruction';
      case HazardType.other:
        return 'Other';
    }
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    // simple readable format
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
           '${local.day.toString().padLeft(2, '0')} '
           '${local.hour.toString().padLeft(2, '0')}:'
           '${local.minute.toString().padLeft(2, '0')}';
  }
}
