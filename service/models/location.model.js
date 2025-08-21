import mongoose from 'mongoose';

const locationSchema = new mongoose.Schema({
    jobId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Job',
        required: true
    },
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    latitude: {
        type: Number,
        required: true
    },
    longitude: {
        type: Number,
        required: true
    },
    timestamp: {
        type: Date,
        default: Date.now
    },
    placeName: {
        type: String
    },
    address: {
        type: String
    },
    accuracy: {
        type: Number
    },
    isStationary: {
        type: Boolean,
        default: false
    },
    stationaryDuration: {
        type: Number // in seconds
    }
});

// Index for faster queries
locationSchema.index({ jobId: 1, timestamp: -1 });
locationSchema.index({ jobId: 1, timestamp: 1 });

export default mongoose.model('Location', locationSchema);