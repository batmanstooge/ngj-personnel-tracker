import express from 'express';
import auth from '../middleware/auth.js';
import {
  saveLocation,
  getDailyLocations,
  getDateRangeLocations,
  getCalendarData,
  getDailySummary
} from '../controller/location.controller.js';

const router = express.Router();

router.post('/', auth, saveLocation);
router.get('/daily', auth, getDailyLocations);
router.get('/date-range', auth, getDateRangeLocations);
router.get('/calendar', auth, getCalendarData);
router.get('/daily-summary', auth, getDailySummary);

export default router;