import { Component } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { BehaviorSubject, catchError, forkJoin, map, merge, of, switchMap, tap } from 'rxjs';
import { PackagesService } from '../../data/packages.service';
import { AsyncPipe } from '@angular/common';
import { LoadingIndicatorComponent } from "../loading-indicator/loading-indicator.component";
import { NoticeComponent } from "../notice/notice.component";
import { License, Maintainer, MetaService } from '../../data/meta.service';
import { MaintainerComponent } from "../maintainer/maintainer.component";

@Component({
  selector: 'app-package',
  imports: [AsyncPipe, RouterLink, LoadingIndicatorComponent, NoticeComponent, MaintainerComponent],
  templateUrl: './package.component.html',
  styleUrl: './package.component.scss'
})
export class PackageComponent {

  protected readonly loading = new BehaviorSubject(false);
  protected readonly data;
  protected readonly scope;

  constructor(
    private readonly activatedRoute: ActivatedRoute,
    private readonly metaService: MetaService,
    private readonly searchService: PackagesService,
  ) {
    this.data = this.activatedRoute.queryParams.pipe(
      tap(() => this.loading.next(true)),
      switchMap(({ scope_id: scopeId, name }) => merge(of(null), this.searchService.getByName(Number(scopeId), name))),
      switchMap(package_ => {
        if (!package_) {
          return of(null);
        }

        const licenses = package_.licenses.length > 0
          ? forkJoin(package_.licenses.map(shortName => this.metaService.getLicense(0, shortName)))
          : of([]);

        const maintainers = package_.maintainers.length > 0
          ? forkJoin(package_.maintainers.map(githubId => this.metaService.getMaintainer(0, githubId).pipe(
            switchMap((maintainer: Maintainer | null) => {
              if (!maintainer) {
                return of(null);
              }

              return of({ ...maintainer, githubId });
            })
          )))
          : of([]);

        return forkJoin({
          licenses,
          maintainers
        })
          .pipe(
            map(({ licenses, maintainers }) => ({
              package: package_,
              licenses: licenses as License[],
              maintainers: maintainers as (Maintainer & { githubId: number })[],
            }))
          );
      }),
      tap(() => this.loading.next(false)),
    );

    this.scope = this.activatedRoute.queryParams.pipe(
      switchMap(({ scope_id }) => merge(of(null), this.searchService.getScopes().pipe(map(scopes => scopes[Number(scope_id)])))),
    );
  }
}
