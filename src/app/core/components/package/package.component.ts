import { ChangeDetectionStrategy, Component, OnDestroy } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { BehaviorSubject, map, merge, of, Subject, switchMap, takeUntil, tap } from 'rxjs';
import { PackagesService } from '../../data/packages.service';
import { AsyncPipe } from '@angular/common';
import { LoadingIndicatorComponent } from "../loading-indicator/loading-indicator.component";
import { NoticeComponent } from "../notice/notice.component";
import { MaintainerComponent } from "../maintainer/maintainer.component";
import { LicenseComponent } from "../license/license.component";
import { TeamComponent } from "../team/team.component";
import { CONFIG } from '../../config.domain';

@Component({
  selector: 'app-package',
  imports: [AsyncPipe, RouterLink, LoadingIndicatorComponent, NoticeComponent, MaintainerComponent, LicenseComponent, TeamComponent],
  templateUrl: './package.component.html',
  styleUrl: './package.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class PackageComponent implements OnDestroy {

  protected readonly loading = new BehaviorSubject(false);
  protected readonly destroy$ = new Subject<void>();
  protected readonly package$;
  protected readonly scopes = CONFIG.scopes
    .filter(scope => scope.packagesEnabled)
    .map((scope, idx) => Object.assign({ id: idx }, scope));

  constructor(
    private readonly activatedRoute: ActivatedRoute,
    private readonly searchService: PackagesService,
  ) {
    this.package$ = this.activatedRoute.queryParams.pipe(
      takeUntil(this.destroy$),
      tap(() => this.loading.next(true)),
      switchMap(({ scope_id: scopeId, name }) => merge(of(null), this.searchService.getByName(Number(scopeId), name))),
      tap(() => this.loading.next(false)),
    );
  }

  public ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  protected getScope(id: number): (typeof CONFIG.scopes)[number] | undefined {
    return this.scopes.find(scope => scope.id === id);
  }
}
