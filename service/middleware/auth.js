import jwt from 'jsonwebtoken';
import Job from '../models/job.model.js';

const auth = async (req, res, next) => {
    try {
        const token = req.header('Authorization')?.replace('Bearer ', '');

        if (!token) {
            return res.status(401).json({ message: 'No token, authorization denied' });
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your_jwt_secret');
        req.userId = decoded.userId;
        req.jobId = decoded.jobId;

        // Verify job exists and is active
        if (req.jobId) {
            const job = await Job.findById(req.jobId);
            if (!job || !job.isActive) {
                return res.status(401).json({ message: 'Job not found or inactive' });
            }
        }

        next();
    } catch (error) {
        res.status(401).json({ message: 'Token is not valid' });
    }
};

export default auth;