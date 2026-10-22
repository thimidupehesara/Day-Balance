import { Router } from 'express';
import { TimerController } from './timer.controller';
import { authenticate } from '../../middleware/authenticate';

const router = Router();

// All timer operations require authentication
router.use(authenticate);

router.post('/start', TimerController.start);
router.post('/pause', TimerController.pause);
router.post('/resume', TimerController.resume);
router.get('/status', TimerController.getStatus);

export { router as timerRouter };
