import { Component } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { BehaviorSubject, forkJoin, map, merge, of, switchMap, tap } from 'rxjs';
import { PackagesService } from '../../data/packages.service';
import { AsyncPipe } from '@angular/common';
import { LoadingIndicatorComponent } from "../loading-indicator/loading-indicator.component";
import { NoticeComponent } from "../notice/notice.component";
import { License, Maintainer, MetaService } from '../../data/meta.service';
import { HttpClient } from '@angular/common/http';

@Component({
  selector: 'app-package',
  imports: [AsyncPipe, RouterLink, LoadingIndicatorComponent, NoticeComponent],
  templateUrl: './package.component.html',
  styleUrl: './package.component.scss'
})
export class PackageComponent {

  protected readonly loading = new BehaviorSubject(false);
  protected readonly data;
  protected readonly scope;

  constructor(
    private readonly activatedRoute: ActivatedRoute,
    private readonly http: HttpClient,
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

              if (!maintainer.matrix) {
                return of({ ...maintainer, githubId });
              }

              return this.http.get<{ displayname: string; avatar_url: string }>(
                `https://matrix.org/_matrix/client/r0/profile/${maintainer.matrix}`
              ).pipe(
                map(profile => ({
                  ...maintainer,
                  githubId,
                  matrixAvatarUrl: profile.avatar_url
                    ? profile.avatar_url.replace('mxc://', 'https://matrix.org/_matrix/media/r0/download/')
                    : ''
                }))
              );
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
