import express from 'express';
import auth from '../middleware/auth.js';
import {
  saveLocation,
  getJobLocations,
  getDailyJobSummary,
  getStationaryLocations
} from '../controller/location.controller.js';

const router = express.Router();

router.post('/', auth, saveLocation);
router.get('/job', auth, getJobLocations);
router.get('/daily-summary', auth, getDailyJobSummary);
router.get('/stationary', auth, getStationaryLocations);

export default router;