import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key, required this.initial});
  final LatLng initial;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  late LatLng _target;

  @override
  void initState() {
    super.initState();
    _target = widget.initial;
  }

  Future<void> _goToMyLocation() async {
    try {
      final service = await Geolocator.isLocationServiceEnabled();
      if (!service) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final c = await _controller.future;
      final dest = LatLng(pos.latitude, pos.longitude);
      await c.animateCamera(CameraUpdate.newLatLngZoom(dest, 16));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location'),
        actions: [
          IconButton(
            onPressed: _goToMyLocation,
            icon: const Icon(Icons.my_location),
            tooltip: 'My location',
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _target, zoom: 16),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) => _controller.complete(c),
            onCameraMove: (p) => _target = p.target,
          ),
          const Icon(Icons.location_pin, size: 40, color: Colors.red),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_target),
              icon: const Icon(Icons.check),
              label: const Text('Use this location'),
            ),
          ),
        ],
      ),
    );
  }
}
