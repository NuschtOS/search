import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: "", loadComponent: () => import("./pages/options/options-page.component").then(c => c.OptionsPageComponent) }
];
