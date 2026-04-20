import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/app_colors.dart';
import '../../utils/logger.dart';
import '../../services/directions_service.dart' as ds;
import '../../services/traffic_service.dart';
import '../../widgets/common/loading_widget.dart';
import '../../utils/environment.dart';

// Define missing types
class DirectionsService {
  DirectionsService();
  
  Future<TurnByTurnNavigation> getTurnByTurnNavigation({
    required LatLng origin,
    required LatLng destination,
    TravelMode travelMode = TravelMode.driving,
    bool avoidTolls = false,
    bool avoidHighways = false,
  }) async {
    // Return a mock navigation object for now
    return TurnByTurnNavigation();
  }
}

class TurnByTurnNavigation {
  final List<NavigationStep> steps;
  final LatLng? endLocation;
  
  TurnByTurnNavigation() : steps = [], endLocation = null;
}

class NavigationStep {
  final String instruction;
  final double distance;
  final Duration duration;
  final LatLng? startLocation;
  final LatLng? endLocation;
  final TravelMode travelMode;
  final String maneuver;
  final List<LatLng> polyline;
  
  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    this.startLocation,
    this.endLocation,
    required this.travelMode,
    required this.maneuver,
    this.polyline = const [],
  });
}

class StepInstruction {
  final String instruction;
  final String? roadName;
  
  StepInstruction() : instruction = '', roadName = null;
}

enum TravelMode {
  driving,
  walking,
  cycling,
  transit
}

class TurnByTurnNavigationScreen extends StatefulWidget {
  final LatLng? origin;
  final LatLng? destination;
  final List<LatLng>? waypoints;
  
  const TurnByTurnNavigationScreen({
    super.key,
    this.origin,
    this.destination,
    this.waypoints,
  });

  @override
  State<TurnByTurnNavigationScreen> createState() => _TurnByTurnNavigationScreenState();
}

class _TurnByTurnNavigationScreenState extends State<TurnByTurnNavigationScreen> {
  GoogleMapController? _mapController;
  ds.DirectionsService? _directionsService;
  TrafficService? _trafficService;
  StreamSubscription<Position>? _positionStream;
  
  // Navigation state
  TurnByTurnNavigation? _navigation;
  NavigationStep? _currentStep;
  int _currentStepIndex = 0;
  bool _isNavigating = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Location tracking
  Position? _currentPosition;
  LatLng? _currentLocation;
  double _distanceToNextTurn = 0.0;
  double _bearingToNextTurn = 0.0;
  
  // Map state
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  
  // UI state
  bool _showInstructions = true;
  bool _voiceGuidance = true;
  NavigationView _viewMode = NavigationView.split;
  
  @override
  void initState() {
    super.initState();
    _directionsService = ds.DirectionsService(apiKey: Environment.googleMapsApiKey);
    _trafficService = TrafficService();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    // Use provided locations or defaults
    final origin = widget.origin ?? const LatLng(13.5127, 2.1128); // Niamey
    final destination = widget.destination ?? const LatLng(13.5678, 2.1489); // Another point in Niamey
    
    setState(() => _isLoading = true);
    
    try {
      // Get turn-by-turn navigation
      final navigation = await _directionsService!.getTurnByTurnNavigation(
        origin: origin,
        destination: destination,
              );
      
      setState(() {
        _navigation = navigation as TurnByTurnNavigation;
        _currentStepIndex = navigation.steps.length - 1; // Start with last step (will be reversed)
        _currentStep = navigation.steps[_currentStepIndex] as NavigationStep;
        _isLoading = false;
      });
      
      _updateMapOverlays();
      _startLocationTracking();
      _fitMapToRoute();
      
    } catch (e, stack) {
      Logger.error('Error initializing navigation', name: 'TurnByTurnNavigation', error: e, stackTrace: stack);
      setState(() {
        _errorMessage = 'Failed to get directions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _startLocationTracking() async {
    try {
      // Check location permissions
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }
      
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result != LocationPermission.whileInUse && result != LocationPermission.always) {
          setState(() => _errorMessage = 'Location permission denied');
          return;
        }
      }
      
      // Start position updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Update every 5 meters
        ),
      ).listen((Position position) {
        _updateCurrentPosition(position);
      });
      
      // Get initial position
      final initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _updateCurrentPosition(initialPosition);
      
    } catch (e, stack) {
      Logger.error('Error starting location tracking', name: 'TurnByTurnNavigation', error: e, stackTrace: stack);
      setState(() => _errorMessage = 'Failed to start location tracking: $e');
    }
  }

  void _updateCurrentPosition(Position position) {
    setState(() {
      _currentPosition = position;
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    
    if (_isNavigating && _navigation != null) {
      _updateNavigationProgress();
    }
  }

  void _updateNavigationProgress() {
    if (_currentLocation == null || _currentStep == null) return;
    
    // Check if we've completed the current step
    final distanceToStepEnd = _calculateDistance(
      _currentLocation!,
      _currentStep!.endLocation!,
    );
    
    if (distanceToStepEnd < 20) { // Within 20 meters of step end
      _moveToNextStep();
    } else {
      // Update distance and bearing to next turn
      _distanceToNextTurn = _calculateDistance(
        _currentLocation!,
        _currentStep!.endLocation!,
      );
      _bearingToNextTurn = _calculateBearing(
        _currentLocation!,
        _currentStep!.endLocation!,
      );
    }
    
    _updateMapOverlays();
  }

  void _moveToNextStep() {
    if (_currentStepIndex > 0) {
      setState(() {
        _currentStepIndex--;
        _currentStep = _navigation!.steps[_currentStepIndex];
      });
      
      // Announce next instruction if voice guidance is enabled
      if (_voiceGuidance && _currentStep != null) {
        _announceInstruction(_currentStep!.instruction);
      }
      
      _updateMapOverlays();
    } else {
      // Navigation complete
      _completeNavigation();
    }
  }

  void _announceInstruction(String instruction) {
    // In a real app, this would use text-to-speech
    Logger.info('Voice instruction: $instruction', name: 'TurnByTurnNavigation');
  }

  void _updateMapOverlays() {
    if (_navigation == null) return;
    
    final markers = <Marker>{};
    final polylines = <Polyline>{};
    final circles = <Circle>{};
    
    // Add current location marker
    if (_currentLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('current_location'),
        position: _currentLocation!,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        rotation: _currentPosition?.heading ?? 0,
      ));
    }
    
    // Add destination marker
    if (_navigation!.endLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _navigation!.endLocation!,
        infoWindow: const InfoWindow(title: 'Destination'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    
    // Add route polyline
    polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points: _navigation!.steps
          .expand((step) => step.polyline)
          .toList(),
      color: AppColors.primaryGreen,
      width: 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    ));
    
    // Add completed route segment
    if (_currentStepIndex < _navigation!.steps.length - 1) {
      final completedPoints = _navigation!.steps
          .skip(_currentStepIndex + 1)
          .expand((step) => step.polyline)
          .toList();
      
      if (completedPoints.isNotEmpty) {
        polylines.add(Polyline(
          polylineId: const PolylineId('completed_route'),
          points: completedPoints,
          color: Colors.grey.withOpacity(0.7),
          width: 4,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          patterns: [PatternItem.dash(5)],
        ));
      }
    }
    
    // Add current step highlight
    if (_currentStep != null && _currentLocation != null) {
      polylines.add(Polyline(
        polylineId: const PolylineId('current_step'),
        points: [_currentLocation!, _currentStep!.endLocation!],
        color: Colors.orange,
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ));
      
      // Add circle around next turn point
      circles.add(Circle(
        circleId: const CircleId('next_turn'),
        center: _currentStep!.endLocation!,
        radius: 30,
        strokeWidth: 3,
        strokeColor: Colors.orange.withOpacity(0.8),
        fillColor: Colors.orange.withOpacity(0.1),
      ));
    }
    
    setState(() {
      _markers = markers;
      _polylines = polylines;
      _circles = circles;
    });
  }

  void _fitMapToRoute() {
    if (_mapController == null || _navigation == null) return;
    
    // Calculate bounds for the entire route
    final allPoints = _navigation!.steps
        .expand((step) => [step.startLocation, step.endLocation])
        .toList();
    
    if (allPoints.isEmpty) return;
    
    final firstPoint = allPoints.first!;
    double minLat = firstPoint.latitude;
    double maxLat = firstPoint.latitude;
    double minLng = firstPoint.longitude;
    double maxLng = firstPoint.longitude;
    
    for (final point in allPoints) {
      final latLng = point!;
      minLat = math.min(minLat, latLng.latitude);
      maxLat = math.max(maxLat, latLng.latitude);
      minLng = math.min(minLng, latLng.longitude);
      maxLng = math.max(maxLng, latLng.longitude);
    }
    
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double lat1Rad = point1.latitude * math.pi / 180;
    final double lat2Rad = point2.latitude * math.pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * math.pi / 180;
    final double deltaLngRad = (point2.longitude - point1.longitude) * math.pi / 180;
    
    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _calculateBearing(LatLng from, LatLng to) {
    final double lat1 = from.latitude * math.pi / 180;
    final double lat2 = to.latitude * math.pi / 180;
    final double deltaLng = (to.longitude - from.longitude) * math.pi / 180;
    
    final double y = math.sin(deltaLng) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLng);
    
    final double bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
    });
    
    if (_currentStep != null && _voiceGuidance) {
      _announceInstruction(_currentStep!.instruction);
    }
  }

  void _stopNavigation() {
    setState(() {
      _isNavigating = false;
    });
  }

  void _completeNavigation() {
    setState(() {
      _isNavigating = false;
    });
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Navigation Complete'),
          content: const Text('You have arrived at your destination!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Turn-by-Turn Navigation'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showInstructions ? Icons.view_list : Icons.map),
            onPressed: () {
              setState(() {
                _showInstructions = !_showInstructions;
              });
            },
            tooltip: _showInstructions ? 'Hide Instructions' : 'Show Instructions',
          ),
          IconButton(
            icon: Icon(_voiceGuidance ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() {
                _voiceGuidance = !_voiceGuidance;
              });
            },
            tooltip: _voiceGuidance ? 'Mute Voice' : 'Enable Voice',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(13.5127, 2.1128),
              zoom: 15.0,
            ),
            markers: _markers,
            polylines: _polylines,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            trafficEnabled: true,
            buildingsEnabled: true,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_navigation != null) {
                _fitMapToRoute();
              }
            },
          ),
          
          // Loading overlay
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Getting directions...'),
                ],
              ),
            ),
          
          // Error overlay
          if (_errorMessage != null)
            Container(
              color: Colors.red.withOpacity(0.9),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _errorMessage = null);
                          _initializeNavigation();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Navigation instructions overlay
          if (_showInstructions && _currentStep != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: _buildNavigationInstructions(),
            ),
          
          // Navigation controls
          Positioned(
            top: 16,
            right: 16,
            child: _buildNavigationControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current instruction
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentStep!.instruction,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Distance and time info
          Row(
            children: [
              Icon(
                Icons.straighten,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                '${(_distanceToNextTurn / 1000).toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 24),
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_currentStep!.duration),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          // Progress bar
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_navigation!.steps.length - _currentStepIndex) / _navigation!.steps.length,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
          ),
          const SizedBox(height: 4),
          Text(
            'Step ${_navigation!.steps.length - _currentStepIndex} of ${_navigation!.steps.length}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _fitMapToRoute,
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Fit Route',
          ),
          const Divider(height: 1),
          IconButton(
            onPressed: _isNavigating ? _stopNavigation : _startNavigation,
            icon: Icon(
              _isNavigating ? Icons.stop : Icons.play_arrow,
              color: _isNavigating ? Colors.red : Colors.green,
            ),
            tooltip: _isNavigating ? 'Stop Navigation' : 'Start Navigation',
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// Navigation view modes
enum NavigationView {
  map,
  instructions,
  split,
}
