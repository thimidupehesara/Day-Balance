// Custom IDs encode their immutable owner in the existing text primary key.
// Never accept a client-supplied ID when creating a category.
export const customCategoryPrefix = (userId: string): string => `custom:${userId}:`;

export function canUseCategory(userId: string, categoryId: string): boolean {
  return !categoryId.startsWith('custom:') || categoryId.startsWith(customCategoryPrefix(userId));
}
