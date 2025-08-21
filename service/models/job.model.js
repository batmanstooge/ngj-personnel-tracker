// job.model.js
import mongoose from 'mongoose';

const jobSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true
    },
    startTime: {
        type: Date,
        default: Date.now
    },
    endTime: {
        type: Date
    },
    loginPhoto: {
        type: String, // URL or base64 encoded image
        required: true
    },
    logoutPhoto: {
        type: String // URL or base64 encoded image
    },
    deviceId: {
        type: String, // IMEI or device identifier
        required: true
    },
    isActive: {
        type: Boolean,
        default: true
    },
    locations: [{
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Location'
    }]
});

// Check if the model already exists, if so, use the existing one
// Otherwise, create the model
const Job = mongoose.models.Job || mongoose.model('Job', jobSchema);

export default Job; // Export the model correctly