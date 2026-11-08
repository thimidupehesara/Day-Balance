import { z } from 'zod';

export const createCategorySchema = z.object({
  name: z.string().trim().min(1, 'Enter a category name').max(40),
  description: z.string().trim().max(100).default(''),
  color: z.enum(['#B9D0DA', '#DEC2A5', '#C7BADA', '#C2D1AE', '#A9CEC6', '#DBB9B2']).default('#A9CEC6'),
}).strict();
export type CreateCategoryInput = z.infer<typeof createCategorySchema>;

export const updateUserCategoriesSchema = z.object({
  categoryIds: z
    .array(z.string().min(1))
    .min(1, 'At least one category must be selected'),
});

export type UpdateUserCategoriesInput = z.infer<
  typeof updateUserCategoriesSchema
>;
