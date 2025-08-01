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
        '&components=country:in'
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
      print('Error searching places: $e');
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
        '&key=$apiKey'
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
      print('Error getting place details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting place details')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF111416),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1D21),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          localizations?.searchPlaces ?? 'Search Places',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: localizations?.searchForPlaces ?? 'Search for places...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _suggestions.clear();
                            _showSuggestions = false;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFF1A1D21),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCAE3F2), width: 2),
                ),
              ),
            ),
          ),
          
          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCAE3F2)),
                ),
              ),
            ),
          
          // Suggestions list
          if (_showSuggestions && !_isLoading)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  final structuredFormatting = suggestion['structured_formatting'];
                  final mainText = structuredFormatting['main_text'] ?? '';
                  final secondaryText = structuredFormatting['secondary_text'] ?? '';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: const Color(0xFF1A1D21),
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Color(0xFFCAE3F2),
                      ),
                      title: Text(
                        mainText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: secondaryText.isNotEmpty
                          ? Text(
                              secondaryText,
                              style: const TextStyle(color: Colors.grey),
                            )
                          : null,
                      onTap: () => _getPlaceDetails(suggestion['place_id']),
                    ),
                  );
                },
              ),
            ),
          
          // No results message
          if (_showSuggestions && !_isLoading && _suggestions.isEmpty && _searchController.text.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations?.noPlacesFound ?? 'No places found',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 