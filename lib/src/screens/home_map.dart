import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/report_service.dart';
import '../models/report.dart';
import 'report_form.dart';

const LatLng kGujaratCenter = LatLng(22.2587, 71.1924);
final LatLngBounds kGujaratBounds = LatLngBounds(
  southwest: LatLng(20.0, 68.0),
  northeast: LatLng(24.9, 74.6),
);

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});
  @override
  State<HomeMapScreen> createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  // prefs-backed state (defaults)
  MapType _mapType = MapType.normal;
  bool _autoCenter = true;
  double _defaultZoom = 12;

  LatLng _camera = kGujaratCenter;
  final _markers = <Marker>{};
  StreamSubscription<List<Report>>? _sub;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _initLocation();

    //reportService.seedDemoIfEmpty();
    _sub = reportService.stream.listen((items) {
      setState(() {
        _markers
          ..clear()
          ..addAll(items.map(
            (r) => Marker(
              markerId: MarkerId(r.id ?? '${r.lat},${r.lng}'),
              position: LatLng(r.lat, r.lng),
              infoWindow: InfoWindow(
                title: _titleFor(r.type),
                snippet: 'Severity ${r.severity} • ${r.description}',
              ),
            ),
          ));
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final sp = await SharedPreferences.getInstance();
    final mapTypeStr = sp.getString('pref.mapType') ?? 'normal';
    setState(() {
      _mapType = _mapTypeFromString(mapTypeStr);
      _autoCenter = sp.getBool('pref.autoCenter') ?? true;
      _defaultZoom = sp.getDouble('pref.defaultZoom') ?? 12;
    });
  }

  MapType _mapTypeFromString(String s) {
    switch (s) {
      case 'hybrid':
        return MapType.hybrid;
      case 'terrain':
        return MapType.terrain;
      case 'satellite':
        return MapType.satellite;
      case 'normal':
      default:
        return MapType.normal;
    }
  }

  Future<void> _initLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() => _camera = LatLng(pos.latitude, pos.longitude));

    if (_autoCenter) {
      final map = await _controller.future;
      await map.animateCamera(
        CameraUpdate.newLatLngZoom(_camera, _defaultZoom.clamp(8, 18)),
      );
    }
  }

  void _openReportForm([LatLng? at]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportFormScreen(initialPosition: at ?? _camera),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _camera,
              zoom: _defaultZoom,
            ),
            mapType: _mapType,
            cameraTargetBounds: CameraTargetBounds(kGujaratBounds),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            onMapCreated: (c) => _controller.complete(c),
            onLongPress: _openReportForm,
          ),
          Positioned(
            left: 12,
            right: 12,
            top: MediaQuery.of(context).padding.top + 12,
            child: _FiltersCard(onChanged: (filters) {
              // Hook for client-side filtering later if needed.
            }),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'recenter',
            onPressed: _initLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Recenter'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'report',
            onPressed: () => _openReportForm(),
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Report'),
          ),
        ],
      ),
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
}

/// Simple filter UI stub (ready to be connected later)
class _FiltersCard extends StatefulWidget {
  const _FiltersCard({required this.onChanged});
  final void Function(_Filters) onChanged;

  @override
  State<_FiltersCard> createState() => _FiltersCardState();
}

class _FiltersCardState extends State<_FiltersCard> {
  final _selected = <HazardType>{};
  double _severity = 2;

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = [
      _chip(HazardType.pothole, 'Pothole', Icons.construction_outlined),
      _chip(HazardType.waterLogging, 'Water', Icons.water_drop_outlined),
      _chip(HazardType.accident, 'Accident', Icons.car_crash_outlined),
      _chip(HazardType.obstruction, 'Obstruction', Icons.traffic_outlined),
      _chip(HazardType.other, 'Other', Icons.more_horiz),
    ];

    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(spacing: 8, runSpacing: -8, children: chips),
            Row(
              children: [
                const Text('Severity'),
                Expanded(
                  child: Slider(
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _severity.toStringAsFixed(0),
                    value: _severity,
                    onChanged: (v) {
                      setState(() => _severity = v);
                      widget.onChanged(_Filters(_selected, _severity.round()));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(HazardType type, String label, IconData icon) {
    final selected = _selected.contains(type);
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 18),
      selected: selected,
      onSelected: (v) {
        setState(() {
          if (v) {
            _selected.add(type);
          } else {
            _selected.remove(type);
          }
        });
        widget.onChanged(_Filters(_selected, _severity.round()));
      },
    );
  }
}

class _Filters {
  const _Filters(this.types, this.minSeverity);
  final Set<HazardType> types;
  final int minSeverity;
}
