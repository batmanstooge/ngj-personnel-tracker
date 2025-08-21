import express from 'express';
import { register,  login, logout, verifyEmail } from '../controller/auth.controller.js';

const router = express.Router();

router.post('/register', register);
router.get('/verify-email',verifyEmail );
router.post('/login', login);
router.post('/logout', logout);

export default router;