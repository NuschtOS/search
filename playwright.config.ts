import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  reporter: 'list',

  use: {
    baseURL: 'http://localhost:4200',
  },

  projects: [
    {
      name: 'chromium',
      use: {
        ...devices['Desktop Chrome'],
      },
    },
    {
      name: 'safari',
      use: {
        ...devices['Desktop Safari'],
      },
    },
    {
      name: 'firefox',
      use: {
        ...devices['Desktop Firefox'],
      },
    },

  ],

  webServer: {
    command: 'pnpm exec http-server ./result -p 4200 -c-1',
    url: 'http://localhost:4200',
  },
});
