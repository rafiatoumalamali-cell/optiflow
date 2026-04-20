import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../utils/app_colors.dart';
import '../../utils/logger.dart';
import '../../services/marker_clustering_service.dart';
import '../../widgets/common/loading_widget.dart';
import '../../models/delivery_point.dart';

class DeliveryPointsMapScreen extends StatefulWidget {
  const DeliveryPointsMapScreen({super.key});

  @override
  State<DeliveryPointsMapScreen> createState() => _DeliveryPointsMapScreenState();
}

class _DeliveryPointsMapScreenState extends State<DeliveryPointsMapScreen> {
  GoogleMapController? _mapController;
  MarkerClusterService? _clusterService;
  
  // Map state
  double _currentZoom = 12.0;
  Set<Marker> _markers = {};
  List<DeliveryPoint> _deliveryPoints = [];
  bool _isLoading = true;
  
  // Filters
  DeliveryPointType? _selectedType;
  DeliveryStatus? _selectedStatus;
  bool _showClusters = true;
  
  // Sample data generation
  final List<String> _streetNames = [
    'Avenue des Banques', 'Rue du Commerce', 'Boulevard de la Liberté',
    'Avenue Moussa Tavele', 'Rue de la Mairie', 'Boulevard du 15 Avril',
    'Avenue de l\'Indépendance', 'Rue du Marché', 'Boulevard du Niger',
    'Avenue du Peuple', 'Rue du Palais', 'Boulevard de la République',
  ];
  
  final List<String> _businessNames = [
    'Tech Solutions Ltd', 'Global Trading Co', 'Fast Logistics', 'Smart Delivery',
    'Express Services', 'Quick Transport', 'Modern Logistics', 'Speedy Delivery',
    'Global Express', 'Rapid Transport', 'Smart Logistics', 'Fast Services',
  ];

  @override
  void initState() {
    super.initState();
    _clusterService = MarkerClusterService();
    _generateSampleData();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _generateSampleData() async {
    setState(() => _isLoading = true);
    
    try {
      // Generate sample delivery points around Niamey
      final baseLocation = const LatLng(13.5127, 2.1128); // Niamey center
      final random = math.Random();
      
      final points = <DeliveryPoint>[];
      
      for (int i = 0; i < 50; i++) {
        // Generate random location within ~10km radius
        final angle = random.nextDouble() * 2 * math.pi;
        final distance = random.nextDouble() * 0.1; // ~10km in degrees
        
        final location = LatLng(
          baseLocation.latitude + distance * math.cos(angle),
          baseLocation.longitude + distance * math.sin(angle),
        );
        
        final point = DeliveryPoint(
          id: 'delivery_$i',
          name: _businessNames[random.nextInt(_businessNames.length)],
          address: '${_streetNames[random.nextInt(_streetNames.length)]}, Niamey',
          location: location,
          type: DeliveryPointType.values[random.nextInt(DeliveryPointType.values.length)],
          status: _getRandomStatus(random),
          metadata: {
            'priority': ['high', 'medium', 'low'][random.nextInt(3)],
            'estimatedTime': random.nextInt(120) + 15, // 15-135 minutes
            'packageCount': random.nextInt(10) + 1,
          },
        );
        
        points.add(point);
      }
      
      setState(() {
        _deliveryPoints = points;
        _isLoading = false;
      });
      
      _updateMarkers();
      
    } catch (e, stack) {
      Logger.error('Error generating sample data', name: 'DeliveryPointsMap', error: e, stackTrace: stack);
      setState(() => _isLoading = false);
    }
  }

  DeliveryStatus _getRandomStatus(math.Random random) {
    final weights = [0.3, 0.2, 0.3, 0.1, 0.1]; // Weighted probabilities
    final cumulative = weights.fold(0.0, (sum, weight) => sum + weight);
    final randomValue = random.nextDouble() * cumulative;
    
    double currentSum = 0.0;
    for (int i = 0; i < weights.length; i++) {
      currentSum += weights[i];
      if (randomValue <= currentSum) {
        return DeliveryStatus.values[i];
      }
    }
    
    return DeliveryStatus.pending;
  }

  void _updateMarkers() {
    if (_clusterService == null) return;
    
    final filteredPoints = _getFilteredPoints();
    final markers = _clusterService!.clusterMarkers(filteredPoints, _currentZoom);
    
    setState(() {
      _markers = markers.toSet();
    });
  }

  List<DeliveryPoint> _getFilteredPoints() {
    var points = _deliveryPoints;
    
    if (_selectedType != null) {
      points = points.where((p) => p.type == _selectedType).toList();
    }
    
    if (_selectedStatus != null) {
      points = points.where((p) => p.status == _selectedStatus).toList();
    }
    
    return points;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    // Fit map to show all points
    if (_deliveryPoints.isNotEmpty) {
      final bounds = _calculateBounds(_deliveryPoints.map((p) => p.location).toList());
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  void _onCameraMove(CameraPosition position) {
    final previousZoom = _currentZoom;
    _currentZoom = position.zoom;
    
    // Update markers when zoom level changes significantly
    if ((_currentZoom - previousZoom).abs() > 0.5) {
      _updateMarkers();
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    if (points.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    
    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }
    
    // Add padding
    const double padding = 0.02;
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;
    
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Points Map'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showClusters ? Icons.filter_list : Icons.filter_list_off),
            onPressed: _showFilterBottomSheet,
            tooltip: 'Filter Points',
          ),
          IconButton(
            icon: Icon(_showClusters ? Icons.layers : Icons.layers_clear),
            onPressed: () {
              setState(() {
                _showClusters = !_showClusters;
              });
              _updateMarkers();
            },
            tooltip: _showClusters ? 'Disable Clustering' : 'Enable Clustering',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(13.5127, 2.1128), // Niamey
              zoom: 12.0,
            ),
            markers: _markers,
            onMapCreated: _onMapCreated,
            onCameraMove: _onCameraMove,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            mapType: MapType.normal,
            trafficEnabled: true,
            buildingsEnabled: true,
          ),
          
          // Loading overlay
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading delivery points...'),
                ],
              ),
            ),
          
          // Stats overlay
          Positioned(
            top: 16,
            left: 16,
            child: _buildStatsCard(),
          ),
          
          // Legend
          Positioned(
            bottom: 16,
            left: 16,
            child: _buildLegend(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generateSampleData,
        backgroundColor: Colors.green,
        child: const Icon(Icons.refresh),
        tooltip: 'Regenerate Data',
      ),
    );
  }

  Widget _buildStatsCard() {
    final filteredPoints = _getFilteredPoints();
    final statusCounts = <DeliveryStatus, int>{};
    final typeCounts = <DeliveryPointType, int>{};
    
    for (final point in filteredPoints) {
      statusCounts[point.status] = (statusCounts[point.status] ?? 0) + 1;
      typeCounts[point.type] = (typeCounts[point.type] ?? 0) + 1;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Points',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${filteredPoints.length} points shown',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          if (_selectedType != null || _selectedStatus != null) ...[
            const SizedBox(height: 4),
            Text(
              'Filters applied',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Status colors
          ...DeliveryStatus.values.map((status) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusText(status),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }),
          
          const Divider(height: 16),
          
          // Type indicators
          ...DeliveryPointType.values.map((type) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    _getTypeIcon(type),
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getTypeText(type),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.orange;
      case DeliveryStatus.inProgress:
        return Colors.blue;
      case DeliveryStatus.completed:
        return Colors.green;
      case DeliveryStatus.failed:
        return Colors.red;
      case DeliveryStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusText(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.inProgress:
        return 'In Progress';
      case DeliveryStatus.completed:
        return 'Completed';
      case DeliveryStatus.failed:
        return 'Failed';
      case DeliveryStatus.cancelled:
        return 'Cancelled';
    }
  }

  IconData _getTypeIcon(DeliveryPointType type) {
    switch (type) {
      case DeliveryPointType.pickup:
        return Icons.inventory_2;
      case DeliveryPointType.delivery:
        return Icons.local_shipping;
      case DeliveryPointType.warehouse:
        return Icons.warehouse;
      case DeliveryPointType.distribution:
        return Icons.hub;
    }
  }

  String _getTypeText(DeliveryPointType type) {
    switch (type) {
      case DeliveryPointType.pickup:
        return 'Pickup';
      case DeliveryPointType.delivery:
        return 'Delivery';
      case DeliveryPointType.warehouse:
        return 'Warehouse';
      case DeliveryPointType.distribution:
        return 'Distribution';
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Delivery Points',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Type filter
                  const Text(
                    'Point Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedType == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? null : _selectedType;
                          });
                          setModalState(() {});
                          _updateMarkers();
                        },
                      ),
                      ...DeliveryPointType.values.map((type) {
                        return FilterChip(
                          label: Text(_getTypeText(type)),
                          selected: _selectedType == type,
                          onSelected: (selected) {
                            setState(() {
                              _selectedType = selected ? type : null;
                            });
                            setModalState(() {});
                            _updateMarkers();
                          },
                        );
                      }),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Status filter
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedStatus == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = selected ? null : _selectedStatus;
                          });
                          setModalState(() {});
                          _updateMarkers();
                        },
                      ),
                      ...DeliveryStatus.values.map((status) {
                        return FilterChip(
                          label: Text(_getStatusText(status)),
                          selected: _selectedStatus == status,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = selected ? status : null;
                            });
                            setModalState(() {});
                            _updateMarkers();
                          },
                        );
                      }),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Clear filters button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedType = null;
                          _selectedStatus = null;
                        });
                        setModalState(() {});
                        _updateMarkers();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Clear Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _regenerateData() async {
    await _generateSampleData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery points regenerated'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }
}
