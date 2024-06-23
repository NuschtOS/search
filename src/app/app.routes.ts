import { Routes } from '@angular/router';
import { OptionComponent } from './pages/option/option.component';
import { EmptyComponent } from './pages/empty/empty.component';

export const routes: Routes = [
  {path: '', component: EmptyComponent},
  {path: ':option', component: OptionComponent},
];
