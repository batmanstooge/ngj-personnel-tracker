import mongoose from 'mongoose';

const locationSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    latitude: {
        type: Number,
        required: true,
    },
    longitude: {
        type: Number,
        required: true,
    },
    timestamp: {
        type: Date,
        default: Date.now,
    },
    placeName: {
        type: String,
    },
    address: {
        type: String,
    },
    accuracy: {
        type: Number,
    }
});

// Index for faster queries
locationSchema.index({ userId: 1, timestamp: -1 });
locationSchema.index({ userId: 1, timestamp: 1 });

export default mongoose.model('Location', locationSchema);