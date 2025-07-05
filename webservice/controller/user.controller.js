import dotenv from "dotenv";
dotenv.config();

import otpGenerator from 'otp-generator';
import jwt from 'jsonwebtoken';
import { parsePhoneNumberFromString } from 'libphonenumber-js';

import twilio from 'twilio';
const twilioClient = new twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);

import User from '../models/user.module.js';

const OTP_EXPIRY_MINUTES = 5;
const JWT_EXPIRY_HOURS = '1h';

async function sendOtpSms(phoneNumber, otp) {
    try {
        const appHash = '<YOUR_APP_HASH>'; 
        await twilioClient.messages.create({
            body: `Your OTP for app login is: ${otp}. It expires in ${OTP_EXPIRY_MINUTES} minutes.\n\n${appHash}`,
            to: phoneNumber,
            from: process.env.TWILIO_PHONE_NUMBER
        });
        console.log(`OTP ${otp} sent to ${phoneNumber} via Twilio.`);
        return true;
    } catch (error) {
        console.error(`Error sending OTP to ${phoneNumber} via Twilio:`, error);
        if (error.code) {
            console.error('Twilio error code:', error.code);
            console.error('Twilio error message:', error.message);
            console.error('Twilio error more info:', error.moreInfo);
        }

        throw new Error('Failed to send OTP SMS.');
    }
}

/**
 * @route POST /api/auth/send-otp
 * @desc Sends an OTP to the provided phone number.
 * @access Public
 */
export const sendOtp = async (req, res) => {
    const { phoneNumber } = req.body; // phoneNumber from client will be in E.164 format (+CCNNNNNNNN)

    if (!phoneNumber) {
        return res.status(400).json({ message: 'Phone number is required.' });
    }

    try {
        
        const parsedNumber = parsePhoneNumberFromString(phoneNumber);

        if (!parsedNumber || !parsedNumber.isValid()) {
            return res.status(400).json({ message: 'Invalid phone number format or country code.' });
        }

        const formattedPhoneNumber = parsedNumber.format('E.164'); 
        const otp = otpGenerator.generate(6, {
            upperCaseAlphabets: false,
            specialChars: false,
            lowerCaseAlphabets: false
        });
        const otpExpires = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

        let user = await User.findOne({ phoneNumber: formattedPhoneNumber });

        if (!user) {
            user = new User({ phoneNumber: formattedPhoneNumber });
        }
        user.otp = otp;
        user.otpExpires = otpExpires;
        await user.save();

        await sendOtpSms(formattedPhoneNumber, otp);

        res.status(201).json({ message: 'OTP sent successfully.' });

    } catch (error) {
        console.error('Error in /api/auth/send-otp:', error);
        res.status(500).json({ message: error.message || 'Error sending OTP. Please try again.' });
    }
};

/**
 * @route POST /api/auth/verify-otp
 * @desc Verifies the provided OTP and logs in the user.
 * @access Public
 */
export const verifyOtp = async (req, res) => {
    const { phoneNumber, otp } = req.body;

    if (!phoneNumber || !otp) {
        return res.status(400).json({ message: 'Phone number and OTP are required.' });
    }

    try {
        const parsedNumber = parsePhoneNumberFromString(phoneNumber);

        if (!parsedNumber || !parsedNumber.isValid()) {
            return res.status(400).json({ message: 'Invalid phone number format or country code.' });
        }

        const formattedPhoneNumber = parsedNumber.format('E.164');

        const user = await User.findOne({ phoneNumber: formattedPhoneNumber });

        if (!user) {
            return res.status(404).json({ message: 'User not found.' });
        }

        if (user.otp !== otp || user.otpExpires < Date.now()) {
            return res.status(401).json({ message: 'Invalid OTP or OTP expired.' });
        }

        user.isVerified = true;
        user.otp = undefined;
        user.otpExpires = undefined;
        await user.save();

        const token = jwt.sign({ id: user._id, phoneNumber: user.phoneNumber }, process.env.JWT_SECRET, { expiresIn: JWT_EXPIRY_HOURS });

        res.status(200).json({
            message: 'OTP verified successfully.',
            token: token,
            user: {
                id: user._id,
                phoneNumber: user.phoneNumber,
                isVerified: user.isVerified
            }
        });

    } catch (error) {
        console.error('Error in /api/auth/verify-otp:', error);
        res.status(500).json({ message: error.message || 'Error verifying OTP. Please try again.' });
    }
};

/**
 * @route POST /api/auth/resend-otp
 * @desc Resends an OTP to the provided phone number.
 * @access Public
 */
export const resendOtp = async (req, res) => {
    const { phoneNumber } = req.body;

    if (!phoneNumber) {
        return res.status(400).json({ message: 'Phone number is required.' });
    }

    try {
        const parsedNumber = parsePhoneNumberFromString(phoneNumber);

        if (!parsedNumber || !parsedNumber.isValid()) {
            return res.status(400).json({ message: 'Invalid phone number format or country code.' });
        }
        const formattedPhoneNumber = parsedNumber.format('E.164');

        let user = await User.findOne({ phoneNumber: formattedPhoneNumber });

        if (!user) {
            return res.status(404).json({ message: 'User not found. Please register first.' });
        }

        const otp = otpGenerator.generate(6, { upperCaseAlphabets: false, specialChars: false, lowerCaseAlphabets: false });
        const otpExpires = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

        user.otp = otp;
        user.otpExpires = otpExpires;
        await user.save();

        await sendOtpSms(formattedPhoneNumber, otp);

        res.status(200).json({ message: 'OTP resent successfully.' });

    } catch (error) {
        console.error('Error in /api/auth/resend-otp:', error);
        res.status(500).json({ message: error.message || 'Error resending OTP. Please try again.' });
    }
};

/**
 * @desc Handler for validating a JWT. Used by clients for persistent login checks.
 * @access Private (via authMiddleware)
 */
export const validateTokenHandler = (req, res) => {
   
    res.status(200).json({
        message: 'Token is valid.',
        user: {
            id: req.user._id,
            phoneNumber: req.user.phoneNumber,
            isVerified: req.user.isVerified
        }
    });
};
