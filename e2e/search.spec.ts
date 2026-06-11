import { test, expect } from '@playwright/test';

test('typing a query returns search option results', async ({ page }) => {
  await page.goto('./');

  const searchInput = page.getByRole('textbox', { name: 'Search', exact: true });
  await searchInput.fill('fire*ox*able');

  const searchResultEntry = page.getByRole('link', { name: 'programs.firefox.enable', exact: true });
  await expect(searchResultEntry).toBeVisible()
  await searchResultEntry.click()

  await expect(page.getByRole('cell', { name: 'Whether to enable the Firefox web browser.', exact: true })).toBeVisible()
});

