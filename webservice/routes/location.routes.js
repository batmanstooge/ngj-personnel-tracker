
import express from "express";
import authMiddleware from "../middleware/auth_middleware.js";
import { getDailySummary, trackLocation } from "../controller/location.controller.js";

const router = express.Router();


router.post("/track", authMiddleware, trackLocation); 
router.get("/daily-summary/:date", authMiddleware, getDailySummary); 


export default router;