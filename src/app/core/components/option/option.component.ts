import { ChangeDetectionStrategy, Component } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { switchMap, map, merge, of, BehaviorSubject, tap } from 'rxjs';
import { AsyncPipe } from '@angular/common';
import { SearchService } from '../../data/search.service';
import { LoadingIndicatorComponent } from "../loading-indicator/loading-indicator.component";

@Component({
  selector: 'app-option',
  imports: [AsyncPipe, RouterLink, LoadingIndicatorComponent],
  templateUrl: './option.component.html',
  styleUrl: './option.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class OptionComponent {

  protected readonly loading = new BehaviorSubject(false);
  protected readonly option;
  protected readonly scope;

  constructor(
    private readonly activatedRoute: ActivatedRoute,
    private readonly searchService: SearchService,
  ) {
    this.option = this.activatedRoute.queryParams.pipe(
      tap(() => this.loading.next(true)),
      switchMap(({ option_scope, option }) => merge(of(null), this.searchService.getByName(Number(option_scope), option))),
      tap(() => this.loading.next(false)),
    );

    this.scope = this.activatedRoute.queryParams.pipe(
      switchMap(({ option_scope }) => merge(of(null), this.searchService.getScopes().pipe(map(scopes => scopes[Number(option_scope)])))),
    );
  }
}
