import Location from '../models/location.model.js';
import Job from '../models/job.model.js';
// Save location with stationary detection
const saveLocation = async (req, res) => {
    try {
        const { latitude, longitude, placeName, address, accuracy, isStationary, stationaryDuration } = req.body;
        const userId = req.userId;
        const jobId = req.jobId;

        // Verify job exists and is active
        const job = await Job.findById(jobId);
        if (!job || !job.isActive) {
            return res.status(400).json({ message: 'Job not found or inactive' });
        }

        const location = new Location({
            jobId,
            userId,
            latitude,
            longitude,
            placeName,
            address,
            accuracy,
            isStationary,
            stationaryDuration
        });

        await location.save();

        // Add location to job
        job.locations.push(location._id);
        await job.save();

        res.status(201).json({
            message: 'Location saved successfully',
            location
        });

    } catch (error) {
        console.error('Save location error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Get job locations
const getJobLocations = async (req, res) => {
    try {
        const jobId = req.jobId;

        const locations = await Location.find({
            jobId
        }).sort({ timestamp: 1 });

        res.json(locations);

    } catch (error) {
        console.error('Get job locations error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Get daily job summary
const getDailyJobSummary = async (req, res) => {
    try {
        const userId = req.userId;
        const { date } = req.query;

        const targetDate = date ? new Date(date) : new Date();
        const startOfDay = new Date(targetDate.setHours(0, 0, 0, 0));
        const endOfDay = new Date(targetDate.setHours(23, 59, 59, 999));

        // Find jobs for the user on the specified date
        const jobs = await Job.find({
            userId,
            startTime: {
                $gte: startOfDay,
                $lte: endOfDay
            }
        }).populate('locations');

        // Create summary
        const summary = {
            date: startOfDay,
            totalJobs: jobs.length,
            jobs: jobs.map(job => ({
                id: job._id,
                startTime: job.startTime,
                endTime: job.endTime,
                deviceId: job.deviceId,
                totalLocations: job.locations.length,
                firstLocation: job.locations[0] || null,
                lastLocation: job.locations[job.locations.length - 1] || null,
                locations: job.locations
            }))
        };

        res.json(summary);

    } catch (error) {
        console.error('Get daily job summary error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

// Get stationary locations
const getStationaryLocations = async (req, res) => {
    try {
        const jobId = req.jobId;

        const locations = await Location.find({
            jobId,
            isStationary: true
        }).sort({ timestamp: 1 });

        res.json(locations);

    } catch (error) {
        console.error('Get stationary locations error:', error);
        res.status(500).json({ message: 'Server error' });
    }
};

export { saveLocation, getJobLocations, getDailyJobSummary, getStationaryLocations };