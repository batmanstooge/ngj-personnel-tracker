import User from "../models/user.model.js"
import Job from "../models/job.model.js";

import jwt from 'jsonwebtoken';
import nodemailer from 'nodemailer';
import crypto from 'crypto';

// Configure nodemailer with correct method name
const createTransporter = () => {
  // Check if environment variables exist
  if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
    console.error('Email credentials not found in environment variables');
    return null;
  }

  // Correct method name is createTransport (not createTransporter)
  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS
    }
  });
};

// Generate verification token
const generateVerificationToken = () => {
  return crypto.randomBytes(32).toString('hex');
};

// Register user
const register = async (req, res) => {
  try {
    const { email } = req.body;

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ message: 'Invalid email format' });
    }

    // Check if user already exists
    let user = await User.findOne({ email });

    if (user) {
      if (user.emailVerified) {
        return res.status(400).json({ message: 'Email already registered and verified' });
      }
    } else {
      // Create new user
      user = new User({ email });
    }

    // Generate verification token
    const token = generateVerificationToken();
    user.emailVerificationToken = token;
    user.emailVerificationExpiry = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24 hours

    await user.save();

    // Try to send verification email
    const transporter = createTransporter();

    if (transporter) {
      try {
        await sendVerificationEmail(email, token, transporter);
        res.json({
          message: 'Verification email sent. Please check your inbox.',
          email: email
        });
      } catch (emailError) {
        console.error('Email sending failed:', emailError);
        // Still register the user but inform them about email issue
        res.json({
          message: 'User registered successfully, but email verification failed. Please contact support.',
          email: email,
          emailSent: false
        });
      }
    } else {
      // Register user without email (for development)
      console.log(`=== EMAIL VERIFICATION (Development) ===`);
      console.log(`Email: ${email}`);
      console.log(`Verification Token: ${token}`);
      console.log(`====================================`);

      res.json({
        message: 'User registered successfully (email verification disabled in development)',
        email: email,
        emailSent: false,
        verificationToken: token // Only for development
      });
    }

  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Send verification email with transporter parameter
const sendVerificationEmail = async (email, token, transporter) => {
  const verificationUrl = `${process.env.FRONTEND_URL || 'http://localhost:3000'}/auth/verify-email?token=${token}`;
  console.log("verification sent to: ", verificationUrl);
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: 'Verify your email address',
    html: `
      <h2>Email Verification</h2>
      <p>Please click the link below to verify your email address:</p>
      <a href="${verificationUrl}">Verify Email</a>
      <p>This link will expire in 24 hours.</p>
      <p>If the button doesn't work, copy and paste this link into your browser:</p>
      <p>${verificationUrl}</p>
    `
  };

  await transporter.sendMail(mailOptions);
};

// Verify email

const verifyEmail = async (req, res) => {
  try {
    const { token } = req.query;

    const user = await User.findOne({
      emailVerificationToken: token,
      emailVerificationExpiry: { $gt: Date.now() }
    });

    if (!user) {
      return res.status(400).send(`
        <!DOCTYPE html>
        <html>
        <head>
          <title>Email Verification</title>
          <style>
            body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background-color: #f5f5f5; }
            .container { background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 500px; margin: 0 auto; }
            .error { color: #d32f2f; background-color: #ffebee; padding: 15px; border-radius: 5px; margin: 20px 0; }
          </style>
        </head>
        <body>
          <div class="container">
            <h1>Email Verification Failed</h1>
            <div class="error">
              <h3>Invalid or Expired Link</h3>
              <p>The verification link is invalid or has expired.</p>
            </div>
            <p>Please try registering again.</p>
          </div>
        </body>
        </html>
      `);
    }

    // Verify user
    user.emailVerified = true;
    user.emailVerificationToken = undefined;
    user.emailVerificationExpiry = undefined;
    await user.save();

    // Show success page with login instructions
    res.send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Email Verified</title>
        <style>
          body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background-color: #f5f5f5; }
          .container { background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); max-width: 500px; margin: 0 auto; }
          .success { color: #388e3c; background-color: #e8f5e9; padding: 15px; border-radius: 5px; margin: 20px 0; }
          .btn { display: inline-block; background-color: #4caf50; color: white; padding: 12px 24px; border-radius: 5px; text-decoration: none; margin: 10px 0; font-weight: bold; }
          .btn:hover { background-color: #45a049; }
        </style>
      </head>
      <body>
        <div class="container">
          <h1>✓ Email Verified Successfully!</h1>
          <div class="success">
            <h3>Congratulations!</h3>
            <p>Your email address has been verified.</p>
          </div>
          <p>You can now login to continue your progress.</p>
          <p><small>You can close this window and open the Personnel Tracker app to login.</small></p>
        </div>
      </body>
      </html>
    `);

  } catch (error) {
    console.error('Verify email error:', error);
    res.status(500).send(`
      <!DOCTYPE html>
      <html>
      <head>
        <title>Email Verification</title>
      </head>
      <body>
        <h1>Server Error</h1>
        <p>An error occurred during verification. Please try again later.</p>
      </body>
      </html>
    `);
  }
};

// Login user and start job
// Login user and start job
const login = async (req, res) => {
  try {
    const { email, deviceId, loginPhoto } = req.body;

    // Check if user exists and is verified
    const user = await User.findOne({ email });

    if (!user) {
      return res.status(400).json({ message: 'User not found. Please register first.' });
    }

    if (!user.emailVerified) {
      return res.status(400).json({ message: 'Email not verified. Please check your email and click the verification link.' });
    }

    // Create new job
    const job = new Job({
      userId: user._id,
      deviceId: deviceId,
      loginPhoto: loginPhoto
    });

    await job.save();

    // Update user with current job
    user.currentJob = job._id;
    user.lastLogin = new Date();
    await user.save();

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id, jobId: job._id },
      process.env.JWT_SECRET || 'your_jwt_secret',
      { expiresIn: '24h' }
    );

    res.json({
      message: 'Login successful and job started',
      token,
      user: {
        id: user._id,
        email: user.email
      },
      job: {
        id: job._id,
        startTime: job.startTime
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

// Logout user and end job
const logout = async (req, res) => {
  try {
    const { logoutPhoto } = req.body;
    const userId = req.userId;
    const jobId = req.jobId;

    // Find user and job
    const user = await User.findById(userId);
    const job = await Job.findById(jobId);

    if (!user || !job) {
      return res.status(400).json({ message: 'User or job not found' });
    }

    // Update job
    job.endTime = new Date();
    job.logoutPhoto = logoutPhoto;
    job.isActive = false;
    await job.save();

    // Clear current job from user
    user.currentJob = null;
    await user.save();

    res.json({ message: 'Logout successful and job ended' });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ message: 'Server error' });
  }
};

export { register, verifyEmail, login, logout };