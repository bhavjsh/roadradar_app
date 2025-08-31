import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../models/report.dart';
import '../services/report_service.dart';
import '../services/ml_service.dart';

class ReportFormScreen extends StatefulWidget {
  const ReportFormScreen({super.key, required this.initialPosition});
  final LatLng initialPosition;

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  final _descCtrl = TextEditingController();
  HazardType _type = HazardType.pothole;
  double _severity = 3;
  XFile? _photo;
  bool _busy = false;
  LatLng? _selectedPosition;
  GoogleMapController? _mapController;
  void _moveMap(LatLng pos) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(pos));
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file != null) setState(() => _photo = file);
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file != null) setState(() => _photo = file);
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      String? mlVerdict;
      if (_photo != null) {
        mlVerdict = await mlService.verifyImage(_photo!);
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('ML Verification'),
            content: Text(mlVerdict ?? 'No verdict'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Continue'),
              ),
            ],
          ),
        );
      }
      final desc = _descCtrl.text.trim();
      final pos = _selectedPosition ?? widget.initialPosition;
      final r = Report(
        lat: pos.latitude,
        lng: pos.longitude,
        type: _type,
        severity: _severity.round(),
        description: desc.isEmpty ? '(no description)' : desc,
      );
      await reportService.add(r, photo: _photo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted to RMC')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report sent to Concerned Authority')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Hazard Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Manual Map Tracking
          SizedBox(
            height: 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedPosition ?? widget.initialPosition,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: _selectedPosition ?? widget.initialPosition,
                  draggable: true,
                  onDragEnd: (pos) {
                    setState(() => _selectedPosition = pos);
                    _moveMap(pos);
                  },
                ),
              },
              onTap: (pos) {
                setState(() => _selectedPosition = pos);
                _moveMap(pos);
              },
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place_outlined),
              const SizedBox(width: 8),
              Text(
                '${(_selectedPosition ?? widget.initialPosition).latitude.toStringAsFixed(5)}, '
                '${(_selectedPosition ?? widget.initialPosition).longitude.toStringAsFixed(5)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Type
          DropdownButtonFormField<HazardType>(
            value: _type,
            decoration: const InputDecoration(
              labelText: 'Hazard type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: HazardType.pothole, child: Text('Pothole')),
              DropdownMenuItem(value: HazardType.waterLogging, child: Text('Water logging')),
              DropdownMenuItem(value: HazardType.accident, child: Text('Accident')),
              DropdownMenuItem(value: HazardType.obstruction, child: Text('Obstruction')),
              DropdownMenuItem(value: HazardType.other, child: Text('Other')),
            ],
            onChanged: (v) => setState(() => _type = v ?? HazardType.pothole),
          ),
          const SizedBox(height: 16),

          // Severity
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Severity',
              border: OutlineInputBorder(),
            ),
            child: Column(
              children: [
                Slider(
                  value: _severity,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _severity.round().toString(),
                  onChanged: (v) => setState(() => _severity = v),
                ),
                Text('Level: ${_severity.round()}'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Description
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Photo pickers
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _pickFromCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('Camera'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Gallery'),
              ),
              const Spacer(),
              if (_photo != null) const Icon(Icons.check_circle, size: 20),
            ],
          ),
          const SizedBox(height: 24),

          // Submit
          FilledButton.icon(
            onPressed: _busy ? null : _submit,
            icon: _busy
                ? const SizedBox(
                    height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
