import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/auth_service.dart';

class _Prefs {
  static const mapType = 'pref.mapType';
  static const autoCenter = 'pref.autoCenter';
  static const defaultZoom = 'pref.defaultZoom';
  static const heatmap = 'pref.heatmap';
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _logout() async {
    await authService.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
  bool _loading = true;
  MapType _mapType = MapType.normal;
  bool _autoCenter = true;
  double _defaultZoom = 12;
  bool _heatmap = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _mapType = _mapTypeFromString(sp.getString(_Prefs.mapType) ?? 'normal');
      _autoCenter = sp.getBool(_Prefs.autoCenter) ?? true;
      _defaultZoom = sp.getDouble(_Prefs.defaultZoom) ?? 12;
      _heatmap = sp.getBool(_Prefs.heatmap) ?? false;
      _loading = false;
    });
    final info = await PackageInfo.fromPlatform();
    setState(() => _version = '${info.appName} v${info.version} (${info.buildNumber})');
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_Prefs.mapType, _mapTypeAsString(_mapType));
    await sp.setBool(_Prefs.autoCenter, _autoCenter);
    await sp.setDouble(_Prefs.defaultZoom, _defaultZoom);
    await sp.setBool(_Prefs.heatmap, _heatmap);
  }

  static String _mapTypeAsString(MapType t) {
    switch (t) {
      case MapType.normal:
        return 'normal';
      case MapType.hybrid:
        return 'hybrid';
      case MapType.terrain:
        return 'terrain';
      case MapType.satellite:
        return 'satellite';
      default:
        return 'normal';
    }
  }

  static MapType _mapTypeFromString(String s) {
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

  Future<void> _pickMapType() async {
    final choice = await showModalBottomSheet<MapType>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Map type')),
              for (final t in const [
                MapType.normal,
                MapType.satellite,
                MapType.terrain,
                MapType.hybrid,
              ])
                RadioListTile<MapType>(
                  value: t,
                  groupValue: _mapType,
                  onChanged: (v) => Navigator.pop(ctx, v),
                  title: Text(_mapTypeAsString(t).toUpperCase()),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (choice != null) {
      setState(() => _mapType = choice);
      _save();
    }
  }

  Future<void> _reset() async {
    setState(() {
      _mapType = MapType.normal;
      _autoCenter = true;
      _defaultZoom = 12;
      _heatmap = false;
    });
    await _save();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings reset to defaults')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionHeader('Map'),
          ListTile(
            leading: const Icon(Icons.layers_outlined),
            title: const Text('Map type'),
            subtitle: Text(_mapTypeAsString(_mapType).toUpperCase()),
            onTap: _pickMapType,
          ),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.my_location_outlined),
            title: const Text('Auto-center on my location'),
            value: _autoCenter,
            onChanged: (v) {
              setState(() => _autoCenter = v);
              _save();
            },
          ),
          ListTile(
            leading: const Icon(Icons.zoom_in_map_outlined),
            title: const Text('Default zoom'),
            subtitle: Slider(
              min: 8,
              max: 18,
              divisions: 10,
              label: _defaultZoom.toStringAsFixed(0),
              value: _defaultZoom,
              onChanged: (v) => setState(() => _defaultZoom = v),
              onChangeEnd: (_) => _save(),
            ),
          ),
          SwitchListTile.adaptive(
            secondary: const Icon(Icons.blur_on_outlined),
            title: const Text('Heatmap layer (prototype)'),
            value: _heatmap,
            onChanged: (v) {
              setState(() => _heatmap = v);
              _save();
            },
          ),
          const Divider(height: 28),
          const _SectionHeader('Permissions & System'),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Open app settings'),
            subtitle: const Text('Manage permissions in Android settings'),
            onTap: Geolocator.openAppSettings,
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Open location settings'),
            onTap: Geolocator.openLocationSettings,
          ),
          const Divider(height: 28),
          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(_version.isEmpty ? 'RoadRadar' : _version),
            subtitle: const Text('Built for Intellify Hackathon'),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Reset to defaults'),
              onPressed: _reset,
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: _logout,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary.withOpacity(.8);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              letterSpacing: .6,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
