import { ChangeDetectionStrategy, Component } from '@angular/core';
import { RouterLink, RouterOutlet } from '@angular/router';
import { CONFIG } from './core/config.domain';

@Component({
  selector: 'app-root',
  imports: [RouterOutlet, RouterLink],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AppComponent {

  protected readonly title = CONFIG.title;

  protected readonly OPTIONS_ENABLED = CONFIG.scopes.findIndex(scope => scope.optionsEnabled) != -1;
  protected readonly PACKAGES_ENABLED = CONFIG.scopes.findIndex(scope => scope.packagesEnabled) != -1;

}
