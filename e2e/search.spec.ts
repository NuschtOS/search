import { test, expect } from '@playwright/test';

test('typing a query returns search option results', async ({ page }) => {
  await page.goto('/');

  const searchInput = page.getByRole('textbox', { name: /Search .* options/ });
  await searchInput.fill('fire*ox*able');

  const searchResultEntry = page.getByRole('link', { name: 'programs.firefox.enable', exact: true });
  await expect(searchResultEntry).toBeVisible()
  await searchResultEntry.click()

  await expect(page.getByRole('cell', { name: 'Whether to enable the Firefox web browser.', exact: true })).toBeVisible()
});

test('typing a query returns search package results', async ({ page }) => {
  await page.goto('/');

  const pkgSearchBtn = page.getByRole('link', { name: 'Packages Search', exact: true });
  await expect(pkgSearchBtn).toBeVisible();
  await pkgSearchBtn.click();

  const searchInput = page.getByRole('textbox', { name: /Search .* packages/, });
  await searchInput.fill('fire*ox');

  const searchResultEntry = page.getByRole('link', { name: 'firefox', exact: true });
  await expect(searchResultEntry).toBeVisible()
  await searchResultEntry.click()

  await expect(page.getByRole('cell', { name: 'Web browser built from Firefox source tree', exact: true })).toBeVisible()
});

