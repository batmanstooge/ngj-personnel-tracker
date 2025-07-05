import jwt from 'jsonwebtoken';

import User from "../models/user.module.js"

const authMiddleware = async (req, res, next) => {
    let token;
    // Check if Authorization header exists and starts with 'Bearer'
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            token = req.headers.authorization.split(' ')[1];
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            req.user = await User.findById(decoded.id).select('-otp -otpExpires');
            if (!req.user) {
                return res.status(401).json({ message: 'Not authorized, user not found.' });
            }
            next();
        } catch (error) {
            console.error('Token verification failed:', error.message);
            return res.status(401).json({ message: 'Not authorized, token failed.' });
        }
    }
    if (!token) {
        return res.status(401).json({ message: 'Not authorized, no token.' });
    }
};

export default authMiddleware;