import Location from '../models/location.model.js';
import User from '../models/user.model.js';
import mongoose from 'mongoose';

// Save location
const saveLocation = async (req, res) => {
    try {
        const { latitude, longitude, placeName, address, accuracy } = req.body;
        const userId = req.userId;

        const location = new Location({
            userId,
            latitude,
            longitude,
            placeName,
            address,
            accuracy
        });

        await location.save();

        res.status(201).json({
            message: 'Location saved successfully',
            location
        });

    } catch (error) {
        console.error('Save location error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Get daily locations
const getDailyLocations = async (req, res) => {
    try {
        const { date } = req.query;
        const userId = req.userId;

        const targetDate = date ? new Date(date) : new Date();
        const startOfDay = new Date(targetDate.setHours(0, 0, 0, 0));
        const endOfDay = new Date(targetDate.setHours(23, 59, 59, 999));

        const locations = await Location``.find({
            userId,
            timestamp: {
                $gte: startOfDay,
                $lte: endOfDay
            }
        }).sort({ timestamp: 1 });

        res.json(locations);

    } catch (error) {
        console.error('Get daily locations error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Get date range locations
const getDateRangeLocations = async (req, res) => {
    try {
        const { start, end } = req.query;
        const userId = req.userId;

        const locations = await Location.find({
            userId,
            timestamp: {
                $gte: new Date(start),
                $lte: new Date(end)
            }
        }).sort({ timestamp: 1 });

        res.json(locations);

    } catch (error) {
        console.error('Get date range locations error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Get calendar data (summary of locations per day)
const getCalendarData = async (req, res) => {
    try {
        const userId = req.userId;

        const calendarData = await Location.aggregate([
            {
                $match: {
                    userId: new mongoose.Types.ObjectId(userId)
                }
            },
            {
                $group: {
                    _id: {
                        year: { $year: "$timestamp" },
                        month: { $month: "$timestamp" },
                        day: { $dayOfMonth: "$timestamp" }
                    },
                    count: { $sum: 1 },
                    date: { $first: "$timestamp" }
                }
            },
            {
                $sort: { date: -1 }
            }
        ]);

        res.json(calendarData);

    } catch (error) {
        console.error('Get calendar data error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Get daily summary
const getDailySummary = async (req, res) => {
    try {
        const { date } = req.query;
        const userId = req.userId;

        const targetDate = date ? new Date(date) : new Date();
        const startOfDay = new Date(targetDate.setHours(0, 0, 0, 0));
        const endOfDay = new Date(targetDate.setHours(23, 59, 59, 999));

        const locations = await Location.find({
            userId,
            timestamp: {
                $gte: startOfDay,
                $lte: endOfDay
            }
        }).sort({ timestamp: 1 });

        // Create summary
        const summary = {
            date: startOfDay,
            totalLocations: locations.length,
            firstLocation: locations[0] || null,
            lastLocation: locations[locations.length - 1] || null,
            locations: locations
        };

        res.json(summary);

    } catch (error) {
        console.error('Get daily summary error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

export { saveLocation, getDailyLocations, getDateRangeLocations, getCalendarData, getDailySummary };