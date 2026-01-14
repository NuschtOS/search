import { Component, OnDestroy } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { BehaviorSubject, merge, of, Subject, switchMap, takeUntil, tap } from 'rxjs';
import { PackagesService } from '../../data/packages.service';
import { AsyncPipe } from '@angular/common';
import { LoadingIndicatorComponent } from "../loading-indicator/loading-indicator.component";
import { NoticeComponent } from "../notice/notice.component";
import { MaintainerComponent } from "../maintainer/maintainer.component";
import { LicenseComponent } from "../license/license.component";
import { TeamComponent } from "../team/team.component";

@Component({
  selector: 'app-package',
  imports: [AsyncPipe, RouterLink, LoadingIndicatorComponent, NoticeComponent, MaintainerComponent, LicenseComponent, TeamComponent],
  templateUrl: './package.component.html',
  styleUrl: './package.component.scss'
})
export class PackageComponent implements OnDestroy {

  protected readonly loading = new BehaviorSubject(false);
  protected readonly destroy$ = new Subject<null>();
  protected readonly scopes$;
  protected readonly package$;

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

    this.scopes$ = this.searchService.getScopes()
      .pipe(takeUntil(this.destroy$));
  }

  public ngOnDestroy(): void {
    this.destroy$.next(null);
    this.destroy$.complete();
  }
}
