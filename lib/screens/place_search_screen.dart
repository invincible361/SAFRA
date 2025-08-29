import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../l10n/app_localizations.dart';
import '../config/api_config.dart';

class PlaceSearchScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onPlaceSelected;
  final String? initialQuery;

  const PlaceSearchScreen({
    Key? key,
    required this.onPlaceSelected,
    this.initialQuery,
  }) : super(key: key);

  @override
  State<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends State<PlaceSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _searchPlaces(widget.initialQuery!);
    }
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty) {
        _searchPlaces(query);
      } else {
        setState(() {
          _suggestions.clear();
          _showSuggestions = false;
        });
      }
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _showSuggestions = true;
    });

    try {
      final apiKey = ApiConfig.googleMapsApiKey;
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=${Uri.encodeComponent(query)}'
            '&key=$apiKey'
            '&types=establishment|geocode'
            '&components=country:in',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List<dynamic>;

        setState(() {
          _suggestions = predictions.map((prediction) {
            return {
              'place_id': prediction['place_id'],
              'description': prediction['description'],
              'structured_formatting': prediction['structured_formatting'],
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _suggestions.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
      setState(() {
        _suggestions.clear();
        _isLoading = false;
      });
    }
  }

  Future<void> _getPlaceDetails(String placeId) async {
    try {
      final apiKey = ApiConfig.googleMapsApiKey;
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
            '?place_id=$placeId'
            '&fields=name,formatted_address,geometry,place_id'
            '&key=$apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];

        if (result != null) {
          final placeDetails = {
            'place_id': result['place_id'],
            'name': result['name'],
            'formatted_address': result['formatted_address'],
            'geometry': result['geometry'],
          };

          widget.onPlaceSelected(placeDetails);
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Error getting place details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error getting place details'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localizations?.searchPlaces ?? 'Search Places',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 🔍 Modern Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: localizations?.searchForPlaces ?? 'Search for places...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _suggestions.clear();
                      _showSuggestions = false;
                    });
                  },
                  icon: const Icon(Icons.clear, color: Colors.white70),
                )
                    : null,
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Loader
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          // Results
          if (_showSuggestions && !_isLoading)
            Expanded(
              child: _suggestions.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: Colors.white38),
                    const SizedBox(height: 12),
                    Text(
                      localizations?.noPlacesFound ?? 'No places found',
                      style: const TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  final formatting = suggestion['structured_formatting'];
                  final mainText = formatting['main_text'] ?? '';
                  final secondaryText = formatting['secondary_text'] ?? '';

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: Color(0xFFCAE3F2)),
                      title: Text(
                        mainText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: secondaryText.isNotEmpty
                          ? Text(
                        secondaryText,
                        style: const TextStyle(color: Colors.white54),
                      )
                          : null,
                      onTap: () => _getPlaceDetails(suggestion['place_id']),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
