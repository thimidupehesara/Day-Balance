import { Router } from 'express';
import { PlansController } from './plans.controller';
import { authenticate } from '../../middleware/authenticate';

const router = Router();

// All plan routes require authentication
router.use(authenticate);

router.post('/', PlansController.createPlan);
router.get('/today', PlansController.getToday);
router.get('/summary', PlansController.getSummary);
router.get('/:id/summary', PlansController.getSummaryById);
router.get('/:id', PlansController.getById);
router.patch('/:id', PlansController.updatePlan);

export { router as plansRouter };
