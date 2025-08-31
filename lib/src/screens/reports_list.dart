import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/report.dart';
import '../services/report_service.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  GoogleMapController? _mapController;
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

    final markers = _items.map((r) => Marker(
      markerId: MarkerId(r.id ?? '${r.lat},${r.lng}'),
      position: LatLng(r.lat, r.lng),
      infoWindow: InfoWindow(
        title: _titleFor(r.type),
        snippet: 'Severity: ${r.severity}',
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(_titleFor(r.type)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Severity: ${r.severity}'),
                  Text('Lat/Lng: ${r.lat.toStringAsFixed(5)}, ${r.lng.toStringAsFixed(5)}'),
                  if ((r.description ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(r.description!),
                  ],
                  const SizedBox(height: 8),
                  Text('Upvotes: ${r.upvotes}'),
                  Text('Downvotes: ${r.downvotes}'),
                  Text('Requests in 1km: ${r.requestsInRadius}'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.thumb_up),
                        onPressed: () async {
                          await reportService.updateVotes(r.id!, up: true);
                          Navigator.of(context).pop();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.thumb_down),
                        onPressed: () async {
                          await reportService.updateVotes(r.id!, up: false);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    )).toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(_items.first.lat, _items.first.lng),
        zoom: 13,
      ),
      markers: markers,
      onMapCreated: (controller) {
        _mapController = controller;
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
