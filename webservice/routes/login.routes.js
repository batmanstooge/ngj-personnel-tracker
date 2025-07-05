import express from "express";
import { resendOtp, sendOtp, validateTokenHandler, verifyOtp } from "../controller/user.controller.js";
import authMiddleware from "../middleware/auth_middleware.js";
const router = express.Router();

router.post ("/auth/send-otp", sendOtp);
router.post("/auth/verify-otp", verifyOtp);
router.post("/auth/resend-otp", resendOtp);

router.post ("/auth/validate-token", authMiddleware, validateTokenHandler);

export default router;