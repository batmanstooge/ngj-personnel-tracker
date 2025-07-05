import LocationData from "../models/location.module.js";


/**
 * @desc Receives and stores a single location point for the authenticated user.
 * @access Private (requires JWT via authMiddleware)
 */
export const trackLocation = async (req, res) => {
    const { latitude, longitude, timestamp } = req.body;

   
    const userId = req.user._id;

    if (latitude == null || longitude == null) {
        return res.status(400).json({ message: 'Latitude and longitude are required.' });
    }

    try {
        const newLocation = new LocationData({
            userId: userId,
            latitude,
            longitude,
            timestamp: timestamp ? new Date(timestamp) : undefined
        });

        await newLocation.save();
        res.status(201).json({ message: 'Location data saved successfully.', location: newLocation });
    } catch (error) {
        console.error('Error saving location data:', error);
        res.status(500).json({ message: 'Failed to save location data.' });
    }
};

/**
 * @desc Retrieves all raw location points for a specific day for the authenticated user.
 * @access Private (requires JWT via authMiddleware)
 * @queryParam date - YYYY-MM-DD format (optional, defaults to today)
 */
export const getDailySummary = async (req, res) => {
    const userId = req.user._id; 
    const dateParam = req.query.date;

    let startOfDay, endOfDay;

    try {
        if (dateParam) {
            const date = new Date(dateParam);
            if (isNaN(date.getTime())) {
                return res.status(400).json({ message: 'Invalid date format. Use YYYY-MM-DD.' });
            }
            startOfDay = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0));
            endOfDay = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate() + 1, 0, 0, 0));
        } else {
            const today = new Date();
            startOfDay = new Date(Date.UTC(today.getFullYear(), today.getMonth(), today.getDate(), 0, 0, 0));
            endOfDay = new Date(Date.UTC(today.getFullYear(), today.getMonth(), today.getDate() + 1, 0, 0, 0));
        }

        const locations = await LocationData.find({
            userId: userId,
            timestamp: {
                $gte: startOfDay,
                $lt: endOfDay
            }
        }).sort({ timestamp: 1 });

        res.status(200).json({
            date: dateParam || startOfDay.toISOString().split('T')[0],
            locations: locations.map(loc => ({
                latitude: loc.latitude,
                longitude: loc.longitude,
                timestamp: loc.timestamp.toISOString()
            }))
        });

    } catch (error) {
        console.error('Error retrieving daily location summary:', error);
        res.status(500).json({ message: 'Failed to retrieve daily location summary.' });
    }
};
