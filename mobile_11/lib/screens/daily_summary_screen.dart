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
      final locations = await LocationService().getLocationsForDate(widget.date);
      setState(() {
        _locations = locations;
      });
    } catch (e) {
      print('Error loading locations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Summary'),
      ),
      body: _isLoading
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
                      Colors.green
                    ),
                    
                    SizedBox(height: 16),
                    
                    _buildLocationCard(
                      'Last Location', 
                      _locations.last,
                      Icons.arrow_downward,
                      Colors.blue
                    ),
                    
                    SizedBox(height: 24),
                    
                    // All Locations Section
                    Text(
                      'All Locations (${_locations.length})',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    
                    ..._locations.map((location) => 
                      _buildLocationListItem(location)
                    ).toList(),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildLocationCard(String title, dynamic location, IconData icon, Color color) {
    final timestamp = location is OfflineLocation 
        ? location.timestamp 
        : DateTime.parse(location['timestamp'] as String);
        
    final placeName = location is OfflineLocation 
        ? location.address 
        : location.address as String?;
        
    final latitude = location is OfflineLocation 
        ? location.latitude 
        : (location['latitude'] as num).toDouble();
        
    final longitude = location is OfflineLocation 
        ? location.longitude 
        : (location['longitude'] as num).toDouble();

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
                    color: color
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              placeName ?? 'Unknown Location',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 4),
            Text(
              '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 4),
            // Text(
            //   DateFormat('h:mm a').format(timestamp),
            //   style: Theme.of(context).textTheme.bodySmall,
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationListItem(dynamic location) {
    final timestamp = location is OfflineLocation 
        ? location.timestamp 
        : DateTime.parse(location['timestamp'] as String);
        
    final placeName = location is OfflineLocation 
        ? location.placeName 
        : location.address as String?;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          Icons.location_on,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          placeName! ,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Text(
          DateFormat('h:mm a').format(timestamp),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Show location details
        },
      ),
    );
  }
}