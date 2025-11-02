import { inject } from '@angular/core';
import { Router, Routes } from '@angular/router';

export const routes: Routes = [
  {
    path: "", pathMatch: 'full', redirectTo: (snapshot) => {
      const router = inject(Router);
      return router.createUrlTree(["options"], { queryParams: snapshot.queryParams })
    }
  },
  { path: "options", loadComponent: () => import("./pages/options/options-page.component").then(c => c.OptionsPageComponent) },
  { path: "packages", loadComponent: () => import("./pages/packages/packages-page.component").then(c => c.PackagesPageComponent) }
];
