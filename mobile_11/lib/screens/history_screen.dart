import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/location_service.dart';
import '../models/offline_location.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime _selectedDate = DateTime.now();
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
      final locations = await LocationService().getLocationsForDate(_selectedDate);
      setState(() {
        _locations = locations;
      });
    } catch (e) {
      print('Error loading locations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadDailyLocations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location History'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDailyLocations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          Container(
            height: 300,
            child: CalendarDatePicker(
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(Duration(days: 1)),
              onDateChanged: _onDateSelected,
              currentDate: _selectedDate,
              initialDate: _selectedDate,
            ),
          ),
          
          // Selected Date Header
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 8),
                Text(
                  '${_locations.length} locations recorded',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          
          // Locations List
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _locations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 60,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No locations recorded for this date',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _locations.length,
                        itemBuilder: (context, index) {
                          final location = _locations[index];
                          return _buildLocationTile(location);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTile(dynamic location) {
    final timestamp = location is OfflineLocation 
        ? location.timestamp 
        : DateTime.parse(location['timestamp'] as String);
        
    final placeName = location is OfflineLocation 
        ? location.placeName 
        : location['placeName'] as String?;
        
    final latitude = location is OfflineLocation 
        ? location.latitude 
        : (location['latitude'] as num).toDouble();
        
    final longitude = location is OfflineLocation 
        ? location.longitude 
        : (location['longitude'] as num).toDouble();

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.location_on,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          placeName ?? 'Unknown Location',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              DateFormat('h:mm a').format(timestamp),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Text(
          DateFormat('h:mm a').format(timestamp),
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        onTap: () {
          // Show location details
        },
      ),
    );
  }
}