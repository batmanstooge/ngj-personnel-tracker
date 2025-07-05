import mongoose from 'mongoose';

const locationDataSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User', // Reference to the User model
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
        default: Date.now,
        required: true
    }
});

locationDataSchema.index({ userId: 1, timestamp: -1 });
const LocationData = mongoose.model('LocationData', locationDataSchema);

export default LocationData