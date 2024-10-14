import { AfterViewInit, ChangeDetectionStrategy, Component, OnDestroy, OnInit } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { Observable, Subject, debounceTime, map, switchMap, takeUntil } from 'rxjs';
import { MAX_SEARCH_RESULTS, SearchService, SearchedOption } from '../../data/search.service';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { DropdownComponent, TextFieldComponent } from "@feel/form";
import { AsyncPipe, NgFor, NgIf } from '@angular/common';

function getQuery(): { query: string | null, scope: number | null } {
  const params = new URL(location.href).searchParams;
  const query = (params.get("query") ?? '').trim();
  const scope = params.has("scope") ? Number(params.get("scope")) : -1;
  return { query: query.length > 0 ? query : null, scope: scope >= 0 ? scope : null };
}

@Component({
  selector: 'app-search',
  standalone: true,
  imports: [ReactiveFormsModule, TextFieldComponent, NgIf, AsyncPipe, NgFor, RouterLink, DropdownComponent],
  templateUrl: './search.component.html',
  styleUrl: './search.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SearchComponent implements OnInit, AfterViewInit, OnDestroy {

  protected readonly search = new FormGroup({
    query: new FormControl<string>(""),
    scope: new FormControl<string>("-1"),
  });

  private readonly formValue = new Subject<{ query: string | null, scope: number | null }>();

  protected readonly scopes = this.searchService.getScopes();
  protected readonly results = this.formValue.pipe(
    switchMap(formValue => this.searchService.search(
      formValue.scope === null ? undefined : formValue.scope,
      formValue.query ?? ''
    )),
  );

  protected readonly selectedOption = this.activatedRoute.queryParams.pipe(map(({ option }) => option));
  protected readonly maxSearchResults = MAX_SEARCH_RESULTS;

  private readonly destroy = new Subject<void>();

  constructor(
    private readonly searchService: SearchService,
    private readonly router: Router,
    private readonly activatedRoute: ActivatedRoute,
  ) {
  }

  public ngOnInit(): void {
    this.search.valueChanges
      .pipe(takeUntil(this.destroy))
      .subscribe(({ query: formQuery, scope: formScope }) => {
        const query = (formQuery ?? '').trim();
        const scope = Number(formScope);

        this.formValue.next({
          query: query.length > 0 ? query : null,
          scope: scope >= 0 ? scope : null
        });
      });

    this.formValue
      .pipe(takeUntil(this.destroy), debounceTime(500))
      .subscribe(formValue => {
        const urlValue = getQuery();
        if (formValue !== urlValue) {
          this.router.navigate([], { queryParams: formValue, queryParamsHandling: 'merge' });
        }
      });
  }

  public ngAfterViewInit(): void {
    const { query, scope } = getQuery();
    this.search.setValue({ query, scope: scope === null ? "-1" : scope.toString() })
  }

  public ngOnDestroy(): void {
    this.destroy.next(void 0);
    this.destroy.complete();
  }

  protected trackBy(_idx: number, option: SearchedOption): number {
    return option.idx;
  }

  protected isActive(opt: SearchedOption): Observable<boolean> {
    return this.selectedOption.pipe(map(option => option === opt.name));
  }
}

