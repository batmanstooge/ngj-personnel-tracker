import mongoose from 'mongoose'; 

const userSchema = new mongoose.Schema({
    phoneNumber: {
        type: String,
        required: true,
        unique: true,
        trim: true,
        match: /^\+[1-9]\d{1,14}$/
    },
    otp: {
        type: String,
        required: false
    },
    otpExpires: {
        type: Date,
        required: false
    },
    isVerified: {
        type: Boolean,
        default: false
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

export default mongoose.model('User', userSchema); 