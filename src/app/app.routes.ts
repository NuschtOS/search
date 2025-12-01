import { inject } from '@angular/core';
import { Router, Routes } from '@angular/router';
import { CONFIG } from './core/config.domain';

export const routes: Routes = [
  {
    path: "", pathMatch: 'full', redirectTo: (snapshot) => {
      const router = inject(Router);
      if (CONFIG.optionsEnabled) {
        return router.createUrlTree(["options"], { queryParams: snapshot.queryParams });
      } else if (CONFIG.packagesEnabled) {
        return router.createUrlTree(["packages"], { queryParams: snapshot.queryParams });
      } else {
        // No enabled routes; redirect to a not-found or fallback route if desired
        return router.createUrlTree([], { queryParams: snapshot.queryParams });
      }
    }
  },
  ...(CONFIG.optionsEnabled
    ? [{ path: "options", loadComponent: () => import("./pages/options/options-page.component").then(c => c.OptionsPageComponent) }]
    : []),
  ...(CONFIG.packagesEnabled ?
    [{ path: "packages", loadComponent: () => import("./pages/packages/packages-page.component").then(c => c.PackagesPageComponent) }]
    : []),
];
