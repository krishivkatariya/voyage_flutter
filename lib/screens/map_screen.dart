import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  final String? destination;

  const MapScreen({super.key, this.destination});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const Color _purple = Color(0xFF6D4AFF);
  static const Color _background = Color(0xFFF8F7FC);
  static const Color _darkPurple = Color(0xFF241B35);

  final MapController _mapController = MapController();
  late Future<vt.Style> _styleFuture;

  Future<vt.Style> _loadMapStyle() {
    return vt.StyleReader(
      uri: 'https://tiles.openfreemap.org/styles/liberty',
      language: 'en',
      logger: const vt.Logger.console(),
    ).read();
  }

  final Distance _distanceCalculator = const Distance();

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();

  LatLng? _start;
  LatLng? _end;

  List<LatLng> _routePoints = [];

  double? _roadDistanceKm;
  double? _durationMinutes;

  bool _loadingRoute = false;
  bool _searchingStart = false;
  bool _searchingDestination = false;
  bool _mapReady = false;

  String? _error;

  static const LatLng _defaultLocation = LatLng(20.0, 0.0);

  double? get _straightDistanceKm {
    if (_start == null || _end == null) return null;

    return _distanceCalculator.as(LengthUnit.Kilometer, _start!, _end!);
  }

  @override
  void initState() {
    super.initState();
    _styleFuture = _loadMapStyle();

    final destination = widget.destination?.trim();

    if (destination != null && destination.isNotEmpty) {
      // onMapReady() performs the initial destination search.
      _destinationController.text = destination;
    }
  }

  @override
  void dispose() {
    _startController.dispose();
    _destinationController.dispose();
    _styleFuture.then((style) => style.dispose()).ignore();
    _mapController.dispose();
    super.dispose();
  }

  Future<LatLng?> _geocode(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '1',
    });

    final response = await http
        .get(uri, headers: {'User-Agent': 'VoyageTripPlanner/1.0'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Location search is temporarily unavailable.');
    }

    final results = jsonDecode(response.body) as List<dynamic>;

    if (results.isEmpty) return null;

    final result = results.first as Map<String, dynamic>;

    return LatLng(
      double.parse(result['lat'].toString()),
      double.parse(result['lon'].toString()),
    );
  }

  void _clearRouteResults() {
    _routePoints = [];
    _roadDistanceKm = null;
    _durationMinutes = null;
    _error = null;
  }

  Future<void> _searchStart() async {
    final query = _startController.text.trim();

    if (query.isEmpty) {
      _showError('Enter a starting location.');
      return;
    }

    setState(() {
      _searchingStart = true;
      _error = null;
    });

    try {
      final location = await _geocode(query);

      if (!mounted) return;

      if (location == null) {
        setState(() {
          _error = 'Starting location not found. Try another search.';
        });
        return;
      }

      setState(() {
        _start = location;
        _clearRouteResults();
      });

      if (_mapReady) {
        _mapController.move(location, 10);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not search for the starting location.';
      });
    } finally {
      if (mounted) {
        setState(() => _searchingStart = false);
      }
    }
  }

  Future<void> _searchDestination() async {
    final query = _destinationController.text.trim();

    if (query.isEmpty) {
      _showError('Enter a destination to search.');
      return;
    }

    setState(() {
      _searchingDestination = true;
      _error = null;
    });

    try {
      final location = await _geocode(query);

      if (!mounted) return;

      if (location == null) {
        setState(() {
          _error = 'Destination not found. Try another search.';
        });
        return;
      }

      // IMPORTANT: save the searched destination coordinates.
      setState(() {
        _end = location;
        _clearRouteResults();
      });

      if (_mapReady) {
        _mapController.move(location, 10);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error = 'Could not search for this destination.';
      });
    } finally {
      if (mounted) {
        setState(() => _searchingDestination = false);
      }
    }
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      if (_start == null || _end != null) {
        _start = point;
        _startController.clear();
        _end = null;
        _destinationController.clear();
      } else {
        _end = point;
        _destinationController.clear();
      }

      _clearRouteResults();
    });
  }

  Future<void> _calculateRoute() async {
    if (_start == null || _end == null) {
      _showError('Select both a starting point and destination.');
      return;
    }

    if (_start == _end) {
      _showError('Choose two different locations.');
      return;
    }

    setState(() {
      _loadingRoute = true;
      _error = null;
      _routePoints = [];
      _roadDistanceKm = null;
      _durationMinutes = null;
    });

    try {
      final start = _start!;
      final end = _end!;

      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/'
            '${start.longitude},${start.latitude};'
            '${end.longitude},${end.latitude}',
        {'overview': 'full', 'geometries': 'geojson'},
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        throw Exception('Routing service is unavailable.');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>?;

      if (routes == null || routes.isEmpty) {
        throw Exception('No driving route found.');
      }

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;

      final points = coordinates.map((coordinate) {
        final values = coordinate as List<dynamic>;

        return LatLng(
          (values[1] as num).toDouble(),
          (values[0] as num).toDouble(),
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _routePoints = points;
        _roadDistanceKm = (route['distance'] as num).toDouble() / 1000;
        _durationMinutes = (route['duration'] as num).toDouble() / 60;
      });

      if (_mapReady && points.isNotEmpty) {
        _mapController.fitCamera(
          CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.all(55),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error =
            'Could not calculate the driving route. '
            'Check both locations and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingRoute = false);
      }
    }
  }

  void _resetSelection() {
    setState(() {
      _start = null;
      _end = null;
      _startController.clear();
      _destinationController.clear();
      _clearRouteResults();
    });

    if (_mapReady) {
      _mapController.move(_defaultLocation, 2.5);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildMarker(String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
          ),
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _darkPurple,
            ),
          ),
        ),
        Icon(Icons.location_on, size: 34, color: color),
      ],
    );
  }

  Widget _buildDistanceRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: _purple, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.black87)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: _darkPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistancePanel() {
    final straightDistance = _straightDistanceKm;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 330),
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Plan your route',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _darkPurple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _start == null
                  ? 'Search or tap the map to set your start.'
                  : _end == null
                  ? 'Now select your destination.'
                  : 'Both locations selected.',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _startController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchStart(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.trip_origin),
                hintText: 'Search starting point',
                isDense: true,
                suffixIcon: IconButton(
                  onPressed: _searchingStart ? null : _searchStart,
                  icon: _searchingStart
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _destinationController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchDestination(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on_outlined),
                hintText: 'Search destination or city',
                isDense: true,
                suffixIcon: IconButton(
                  onPressed: _searchingDestination ? null : _searchDestination,
                  icon: _searchingDestination
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (straightDistance != null) ...[
              const SizedBox(height: 10),
              _buildDistanceRow(
                Icons.straighten,
                'Straight-line distance',
                '${straightDistance.toStringAsFixed(2)} km',
              ),
            ],
            if (_roadDistanceKm != null) ...[
              _buildDistanceRow(
                Icons.route,
                'Driving distance',
                '${_roadDistanceKm!.toStringAsFixed(2)} km',
              ),
              _buildDistanceRow(
                Icons.schedule,
                'Estimated driving time',
                _formatDuration(_durationMinutes!),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetSelection,
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _start != null && _end != null && !_loadingRoute
                        ? _calculateRoute
                        : null,
                    icon: _loadingRoute
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.directions_car),
                    label: Text(
                      _loadingRoute ? 'Finding route...' : 'Find route',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Driving estimates use available road data and do not '
              'include live traffic.',
              style: TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(double minutes) {
    final totalMinutes = minutes.round();
    final hours = totalMinutes ~/ 60;
    final remainingMinutes = totalMinutes % 60;

    if (hours == 0) return '$remainingMinutes min';

    return '$hours hr $remainingMinutes min';
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.destination?.trim();
    final hasTripDestination = destination != null && destination.isNotEmpty;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Explore Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.explore, color: _purple, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Explore your destination',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _darkPurple,
                          ),
                        ),
                        Text(
                          hasTripDestination
                              ? 'Trip destination: $destination'
                              : 'Explore places around the world',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<vt.Style>(
                future: _styleFuture,
                builder: (context, snapshot) {
                  final style = snapshot.data;

                  if (style == null) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.map_outlined,
                                size: 42,
                                color: _purple,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Could not load the map style.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _darkPurple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Check your internet connection and try again.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _styleFuture = _loadMapStyle();
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return const Center(
                      child: CircularProgressIndicator(color: _purple),
                    );
                  }

                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _defaultLocation,
                      initialZoom: 2.5,
                      maxZoom: 19,
                      onMapReady: () {
                        _mapReady = true;

                        if (hasTripDestination) {
                          _searchDestination();
                        }
                      },
                      onTap: _handleMapTap,
                    ),
                    children: [
                      vt.VectorTileLayer(
                        theme: style.theme,
                        tileProviders: style.providers,
                        rasterSources: style.rasterSources,
                        sprites: style.sprites,
                      ),
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 5,
                              color: _purple,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          if (_start != null)
                            Marker(
                              point: _start!,
                              width: 90,
                              height: 48,
                              alignment: Alignment.bottomCenter,
                              child: _buildMarker('Start', Colors.green),
                            ),
                          if (_end != null)
                            Marker(
                              point: _end!,
                              width: 100,
                              height: 48,
                              alignment: Alignment.bottomCenter,
                              child: _buildMarker('Destination', _purple),
                            ),
                        ],
                      ),
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            style.attributions
                                .map((attribution) => attribution.text)
                                .join(' · '),
                          ),
                          const TextSourceAttribution('Routing by OSRM'),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildDistancePanel(),
          ],
        ),
      ),
    );
  }
}
