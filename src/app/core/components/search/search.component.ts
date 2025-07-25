import { AfterViewInit, ChangeDetectionStrategy, Component, OnDestroy, OnInit } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { Observable, Subject, combineLatest, debounceTime, filter, map, switchMap, takeUntil } from 'rxjs';
import { MAX_SEARCH_RESULTS, SearchService, SearchedOption } from '../../data/search.service';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { DropdownComponent, TextFieldComponent } from "@feel/form";
import { AsyncPipe } from '@angular/common';

function getQuery(route: ActivatedRoute): { query: string | null, scope: string | null } {
  const params = route.snapshot.queryParamMap;
  const query = (params.get("query") ?? '').trim();
  const scope = (params.get("scope") ?? '').trim();
  return { query: query.length > 0 ? query : null, scope: scope.length > 0 ? scope : null };
}

/**
 * @see <https://stackoverflow.com/a/68703218>
 */
function prefix(options: SearchedOption[]): string {
  // check border cases size 1 array and empty first word)
  if (!options[0] || options.length == 1) return options[0].name || "";
  let i = 0;
  // while all words have the same character at position i, increment i
  while (options[0].name[i] && options.every(option => option.name[i] === options[0].name[i]))
    i++;

  // prefix is the substring from the beginning to the last successfully checked i
  return options[0].name.slice(0, i);
}

@Component({
  selector: 'app-search',
  imports: [ReactiveFormsModule, TextFieldComponent, AsyncPipe, RouterLink, DropdownComponent],
  templateUrl: './search.component.html',
  styleUrl: './search.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SearchComponent implements OnInit, AfterViewInit, OnDestroy {

  protected readonly search = new FormGroup({
    query: new FormControl<string>(""),
    scope: new FormControl<string>("-1"),
  });

  private readonly formValue = new Subject<{ query: string | null, scope: number | null }>();

  protected readonly scopes;
  protected readonly results = this.formValue.pipe(
    switchMap(formValue => this.searchService.search(
      formValue.scope === null ? undefined : formValue.scope,
      formValue.query ?? ''
    )),
    map(options => {
      if (!(options?.length > 0)) {
        return [];
      }

      const commonPrefix0 = prefix(options);
      const idx = commonPrefix0.lastIndexOf('.');
      const commonPrefix = commonPrefix0.substring(0, idx).split(".");

      const prr = commonPrefix.map(d => d.substring(0, 1)).join(".");

      return options.map(option => ({ ...option, displayName: prr + option.name.substring(idx) }));
    })
  );

  protected readonly selectedOption;
  protected readonly maxSearchResults = MAX_SEARCH_RESULTS;

  private readonly destroy = new Subject<void>();

  constructor(
    private readonly searchService: SearchService,
    private readonly router: Router,
    private readonly activatedRoute: ActivatedRoute,
  ) {
    this.scopes = this.searchService.getScopes();
    this.selectedOption = this.activatedRoute.queryParams.pipe(
      map(({ option_scope, option }) => ({
        scope_id: Number(option_scope),
        name: option
      }))
    );
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

    combineLatest({ form: this.formValue, scopes: this.scopes })
      .pipe(takeUntil(this.destroy), debounceTime(500))
      .subscribe(({ form, scopes }) => {
        const formValue = {
          query: form.query,
          scope: form.scope === null ? null : scopes[form.scope]
        };

        const urlValue = getQuery(this.activatedRoute);
        if (form !== urlValue) {
          this.router.navigate([], {
            queryParams: formValue,
            queryParamsHandling: 'merge'
          });
        }
      });
  }

  public ngAfterViewInit(): void {
    const { query, scope } = getQuery(this.activatedRoute);
    this.scopes.pipe(takeUntil(this.destroy), filter(scopes => scopes.length > 0))
      .subscribe(scopes => {
        const idx = scopes.findIndex(s => s === scope);
        this.search.setValue({ query, scope: idx.toString() })
      })
  }

  public ngOnDestroy(): void {
    this.destroy.next(void 0);
    this.destroy.complete();
  }

  protected trackBy(_idx: number, option: SearchedOption): number {
    return option.idx;
  }

  protected isActive(opt: SearchedOption): Observable<boolean> {
    return this.selectedOption.pipe(map(option => option.scope_id === opt.scope_id && option.name === opt.name));
  }
}

