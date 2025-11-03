import { Component } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { BehaviorSubject, map, merge, of, switchMap, tap } from 'rxjs';
import { PackagesService } from '../../data/packages.service';
import { AsyncPipe } from '@angular/common';
import { LoadingIndicatorComponent } from "../loading-indicator/loading-indicator.component";

@Component({
  selector: 'app-package',
  imports: [AsyncPipe, RouterLink, LoadingIndicatorComponent],
  templateUrl: './package.component.html',
  styleUrl: './package.component.scss'
})
export class PackageComponent {

  protected readonly loading = new BehaviorSubject(false);
  protected readonly package;
  protected readonly scope;

  constructor(
    private readonly activatedRoute: ActivatedRoute,
    private readonly searchService: PackagesService,
  ) {
    this.package = this.activatedRoute.queryParams.pipe(
      tap(() => this.loading.next(true)),
      switchMap(({ scope_id, name }) => merge(of(null), this.searchService.getByName(Number(scope_id), name))),
      tap(() => this.loading.next(false)),
    );

    this.scope = this.activatedRoute.queryParams.pipe(
      switchMap(({ scope_id }) => merge(of(null), this.searchService.getScopes().pipe(map(scopes => scopes[Number(scope_id)])))),
    );
  }
}
