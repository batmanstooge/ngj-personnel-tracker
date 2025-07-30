import User from '../models/user.model.js';
import twilio from 'twilio';
import jwt from 'jsonwebtoken';

// Twilio configuration (optional - you can use other SMS services)
const client = twilio(
  process.env.TWILIO_ACCOUNT_SID,
  process.env.TWILIO_AUTH_TOKEN
);

// Generate OTP
const generateOTP = () => {
  return Math.floor(100000 + Math.random() * 900000).toString();
};

// Send OTP
const sendOTP = async (req, res) => {
  try {
    const { phoneNumber } = req.body;
    
    // Validate phone number format
    if (!phoneNumber || phoneNumber.length < 10) {
      return res.status(400).json({ message: 'Invalid phone number' });
    }

    const otp = generateOTP();
    const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Find or create user
    let user = await User.findOne({ phoneNumber });
    
    if (!user) {
      user = new User({ phoneNumber });
    }

    user.otp = otp;
    user.otpExpiry = otpExpiry;
    await user.save();

    // Send OTP via SMS (using Twilio or any SMS service)
    // For testing, you might want to skip this or use console.log
    if (process.env.NODE_ENV === 'production') {
      await client.messages.create({
        body: `Your OTP for Location Tracker is: ${otp}`,
        from: process.env.TWILIO_PHONE_NUMBER,
        to: phoneNumber
      });
    } else {
      console.log(`OTP for ${phoneNumber}: ${otp}`); // For development
    }

    res.json({ 
      message: 'OTP sent successfully',
      // Don't send actual OTP in production - this is for testing
      testOtp: process.env.NODE_ENV === 'development' ? otp : undefined
    });

  } catch (error) {
    console.error('Send OTP error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Verify OTP
const verifyOTP = async (req, res) => {
  try {
    const { phoneNumber, otp } = req.body;

    const user = await User.findOne({ phoneNumber });
    
    if (!user) {
      return res.status(400).json({ message: 'User not found' });
    }

    // Check if OTP is valid and not expired
    if (user.otp !== otp || user.otpExpiry < new Date()) {
      return res.status(400).json({ message: 'Invalid or expired OTP' });
    }

    // Clear OTP after successful verification
    user.otp = undefined;
    user.otpExpiry = undefined;
    user.lastLogin = new Date();
    await user.save();

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET || 'your_jwt_secret',
      { expiresIn: '30d' }
    );

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        phoneNumber: user.phoneNumber
      }
    });

  } catch (error) {
    console.error('Verify OTP error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Logout
const logout = async (req, res) => {
  try {
    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Server error' });
  }
};

export { sendOTP, verifyOTP, logout };