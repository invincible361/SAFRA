import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/ai_route_service.dart';
import '../l10n/app_localizations.dart';
import '../config/api_config.dart';

class AIRouteSelectionScreen extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String destinationName;

  const AIRouteSelectionScreen({
    Key? key,
    required this.origin,
    required this.destination,
    required this.destinationName,
  }) : super(key: key);

  @override
  State<AIRouteSelectionScreen> createState() => _AIRouteSelectionScreenState();
}

class _AIRouteSelectionScreenState extends State<AIRouteSelectionScreen> {
  List<RouteOption> _routeOptions = [];
  bool _isLoading = true;
  String? _error;
  RouteOption? _selectedRoute;
  Map<String, dynamic> _userPreferences = {};

  @override
  void initState() {
    super.initState();
    _loadRouteOptions();
  }

  Future<void> _loadRouteOptions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final routes = await AIRouteService.generateRouteOptions(
        origin: widget.origin,
        destination: widget.destination,
        googleApiKey: ApiConfig.googleMapsApiKey,
      );

      if (!mounted) return;
      setState(() {
        _routeOptions = routes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load route options: $e';
        _isLoading = false;
      });
    }
  }

  void _showPreferencesDialog() {
    showDialog(
      context: context,
      builder: (context) => _PreferencesDialog(
        preferences: _userPreferences,
        onPreferencesChanged: (preferences) {
          setState(() {
            _userPreferences = preferences;
            _routeOptions = AIRouteService.getRecommendations(_routeOptions, preferences);
          });
        },
      ),
    );
  }

  void _selectRoute(RouteOption route) {
    setState(() {
      _selectedRoute = route;
    });
  }

  void _startNavigation() {
    if (_selectedRoute != null) {
      Navigator.pop(context, _selectedRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.aiRouteSelection ?? 'AI Route Selection'),
        backgroundColor: const Color(0xFF111416),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showPreferencesDialog,
            tooltip: 'Preferences',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _error != null
              ? _buildErrorView()
              : _buildRouteOptionsView(),
      bottomNavigationBar: _selectedRoute != null
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Analyzing routes with AI...'),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[600],
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Unknown error',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadRouteOptions,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteOptionsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _routeOptions.length,
      itemBuilder: (context, index) {
        final route = _routeOptions[index];
        final isSelected = _selectedRoute?.id == route.id;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 2,
          color: isSelected ? Colors.blue[50] : Colors.white,
          child: InkWell(
            onTap: () => _selectRoute(route),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          route.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: Colors.blue[600],
                          size: 24,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    route.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.access_time,
                        '${route.duration} min',
                        Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.straighten,
                        '${route.distance.toStringAsFixed(1)} km',
                        Colors.green,
                      ),
                      const SizedBox(width: 8),
                      _buildTrafficChip(route.trafficLevel),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAnalysisSection(route),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrafficChip(String trafficLevel) {
    Color color;
    String label;
    
    switch (trafficLevel.toLowerCase()) {
      case 'low':
        color = Colors.green;
        label = 'Low Traffic';
        break;
      case 'high':
        color = Colors.red;
        label = 'High Traffic';
        break;
      default:
        color = Colors.orange;
        label = 'Medium Traffic';
    }
    
    return _buildInfoChip(Icons.traffic, label, color);
  }

  Widget _buildAnalysisSection(RouteOption route) {
    final analysis = route.analysis;
    final pros = analysis['pros'] as List<String>? ?? [];
    final cons = analysis['cons'] as List<String>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pros.isNotEmpty) ...[
          const Text(
            '✅ Advantages:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          ...pros.map((pro) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '• $pro',
              style: const TextStyle(fontSize: 12),
            ),
          )),
          const SizedBox(height: 8),
        ],
        if (cons.isNotEmpty) ...[
          const Text(
            '⚠️ Considerations:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          ...cons.map((con) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '• $con',
              style: const TextStyle(fontSize: 12),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedRoute!.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${_selectedRoute!.duration} min • ${_selectedRoute!.distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _startNavigation,
            icon: const Icon(Icons.navigation),
            label: Text(AppLocalizations.of(context)?.startNavigation ?? 'Start Navigation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4169E1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferencesDialog extends StatefulWidget {
  final Map<String, dynamic> preferences;
  final Function(Map<String, dynamic>) onPreferencesChanged;

  const _PreferencesDialog({
    required this.preferences,
    required this.onPreferencesChanged,
  });

  @override
  State<_PreferencesDialog> createState() => _PreferencesDialogState();
}

class _PreferencesDialogState extends State<_PreferencesDialog> {
  late Map<String, dynamic> _preferences;

  @override
  void initState() {
    super.initState();
    _preferences = Map.from(widget.preferences);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Route Preferences'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreferenceSwitch(
              'prefer_fastest',
              '🚗 Prefer fastest route',
              'Prioritize speed over other factors',
            ),
            _buildPreferenceSwitch(
              'prefer_eco_friendly',
              '🌱 Prefer eco-friendly route',
              'Choose public transport or walking',
            ),
            _buildPreferenceSwitch(
              'avoid_traffic',
              '🚦 Avoid traffic',
              'Prefer routes with less congestion',
            ),
            _buildPreferenceSwitch(
              'prefer_scenic',
              '🌳 Prefer scenic route',
              'Choose more picturesque paths',
            ),
            _buildPreferenceSwitch(
              'prefer_safe',
              '🛡️ Prefer safe route',
              'Choose well-lit, populated areas',
            ),
            const SizedBox(height: 16),
            const Text(
              'Maximum Duration (minutes):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: (_preferences['max_duration'] ?? 60).toDouble(),
              min: 15,
              max: 120,
              divisions: 21,
              label: '${(_preferences['max_duration'] ?? 60).round()} min',
              onChanged: (value) {
                setState(() {
                  _preferences['max_duration'] = value.round();
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onPreferencesChanged(_preferences);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildPreferenceSwitch(String key, String title, String subtitle) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      value: _preferences[key] ?? false,
      onChanged: (value) {
        setState(() {
          _preferences[key] = value;
        });
      },
    );
  }
} 