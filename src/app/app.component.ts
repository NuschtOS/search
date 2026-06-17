import { ChangeDetectionStrategy, Component, DestroyRef, inject } from '@angular/core';
import { DOCUMENT } from '@angular/common';
import { NavigationEnd, Router, RouterLink, RouterOutlet } from '@angular/router';
import { CONFIG } from './core/config.domain';
import { filter } from 'rxjs';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

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

  private readonly router = inject(Router);
  private readonly document = inject(DOCUMENT);
  private readonly destroyRef = inject(DestroyRef);

  constructor() {
    this.syncSearchLink(this.router.url);

    this.router.events
      .pipe(
        filter((event): event is NavigationEnd => event instanceof NavigationEnd),
        takeUntilDestroyed(this.destroyRef),
      )
      .subscribe(() => this.syncSearchLink(this.router.url));
  }

  private syncSearchLink(url: string): void {
    const type = url.startsWith('/packages') ? 'packages' : url.startsWith('/options') ? 'options' : null;
    const existing = this.document.head.querySelector<HTMLLinkElement>('link[data-nuschtos-opensearch]');

    if (!type) {
      existing?.remove();
      return;
    }

    const link = existing ?? this.document.head.appendChild(this.document.createElement('link'));
    link.rel = 'search';
    link.type = 'application/opensearchdescription+xml';
    link.dataset.nuschtosOpensearch = 'true';
    link.title = `${CONFIG.title} ${type === 'options' ? 'Options' : 'Packages'} Search`;
    link.href = `${CONFIG.baseHref}opensearch-${type}.xml`;
  }

}
