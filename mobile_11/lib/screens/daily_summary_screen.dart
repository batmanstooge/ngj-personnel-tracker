import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_tracker/models/offline_location.dart';
import '../services/location_service.dart';

class DailySummaryScreen extends StatefulWidget {
  final DateTime date;

  const DailySummaryScreen({super.key, required this.date});

  @override
  State<DailySummaryScreen> createState() {
    return _DailySummaryScreenState();
  }
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  List<dynamic> _locations = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDailyLocations();
  }

  _loadDailyLocations() async {
    setState(() => _isLoading = true);
    try {
      final locations = await LocationService().getLocationsForDate(
        widget.date,
      );
      setState(() {
        _locations = locations;
      });
    } catch (e) {
      print('Error loading locations: $e');
      // Optionally show an error message to the user
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daily Summary')),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Header
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('EEEE').format(widget.date),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            DateFormat('MMMM d, yyyy').format(widget.date),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${_locations.length} locations recorded',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // First and Last Locations
                    if (_locations.isNotEmpty) ...[
                      _buildLocationCard(
                        'First Location',
                        _locations.first,
                        Icons.arrow_upward,
                        Colors.green,
                      ),

                      SizedBox(height: 16),

                      _buildLocationCard(
                        'Last Location',
                        _locations.last,
                        Icons.arrow_downward,
                        Colors.blue,
                      ),

                      SizedBox(height: 24),

                      // All Locations Section
                      Text(
                        'All Locations (${_locations.length})',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 16),

                      ..._locations
                          .map((location) => _buildLocationListItem(location))
                          .toList(),
                    ],
                  ],
                ),
              ),
    );
  }

  // Helper method to get a displayable name/address for a location
  String _getLocationDisplayName(dynamic location) {
    String? name;

    if (location is OfflineLocation) {
      // Check placeName first, then address for OfflineLocation
      name = location.placeName ?? location.address;
    } else if (location is Map<String, dynamic>) {
      // Check placeName first, then address for Map (API data)
      name = location['placeName'] as String? ?? location['address'] as String?;
    }

    // Fallback to coordinates if no name/address found
    if (name == null || name.isEmpty) {
      double? lat, lng;
      if (location is OfflineLocation) {
        lat = location.latitude;
        lng = location.longitude;
      } else if (location is Map<String, dynamic>) {
        lat = (location['latitude'] as num?)?.toDouble();
        lng = (location['longitude'] as num?)?.toDouble();
      }
      if (lat != null && lng != null) {
        name = '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
      } else {
        name = 'Unknown Location';
      }
    }

    return name;
  }

  Widget _buildLocationCard(
    String title,
    dynamic location,
    IconData icon,
    Color color,
  ) {
    final timestamp =
        location is OfflineLocation
            ? location.timestamp
            : DateTime.parse(location['timestamp'] as String);

    // Use the helper method to get the display name
    final displayName = _getLocationDisplayName(location);

    // Get coordinates for display
    double latitude, longitude;
    if (location is OfflineLocation) {
      latitude = location.latitude;
      longitude = location.longitude;
    } else {
      latitude = (location['latitude'] as num).toDouble();
      longitude = (location['longitude'] as num).toDouble();
    }

    // Format time to local
    String _formatToLocalTime(DateTime utcTime) {
      final localTime = utcTime.toLocal();
      return DateFormat('h:mm a').format(localTime);
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              displayName, // Use the resolved display name
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 4),
            Text(
              '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 4),
            Text(
              _formatToLocalTime(timestamp), // Display local time
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationListItem(dynamic location) {
    final timestamp =
        location is OfflineLocation
            ? location.timestamp
            : DateTime.parse(location['timestamp'] as String);

    // Use the helper method to get the display name
    final displayName = _getLocationDisplayName(location);

    // Format time to local
    String _formatToLocalDateTime(DateTime utcTime) {
      final localTime = utcTime.toLocal();
      return DateFormat('MMM d, h:mm a').format(localTime);
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(Icons.location_on, color: Theme.of(context).primaryColor),
        title: Text(
          displayName,
          style: Theme.of(context).textTheme.bodyLarge,
        ), // Use display name
        subtitle: Text(
          _formatToLocalDateTime(timestamp),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
