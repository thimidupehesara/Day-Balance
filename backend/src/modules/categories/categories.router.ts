import { Router } from 'express';
import { CategoriesController } from './categories.controller';
import { authenticate } from '../../middleware/authenticate';

const router = Router();

// Public: list all 7 system categories
router.get('/', CategoriesController.getAll);

// Authenticated: manage current user's selected categories
router.get('/mine', authenticate, CategoriesController.getMine);
router.get('/available', authenticate, CategoriesController.getAvailable);
router.post('/custom', authenticate, CategoriesController.create);
router.put('/mine', authenticate, CategoriesController.setMine);

export { router as categoriesRouter };
