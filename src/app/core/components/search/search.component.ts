import { afterNextRender, AfterViewInit, ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { FormControl, FormGroup, ReactiveFormsModule } from '@angular/forms';
import { BehaviorSubject, Observable, Subject, combineLatest, debounceTime, filter, map, switchMap, takeUntil } from 'rxjs';
import { MAX_SEARCH_RESULTS, SearchService, SearchedResult } from '../../data/search.service';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { DropdownComponent, TextFieldComponent } from "@feel/form";
import { AsyncPipe } from '@angular/common';
import { OptionsService, Option } from '../../data/options.service';
import { Package, PackagesService } from '../../data/packages.service';
import { CONFIG } from '../../config.domain';

function getQuery(route: ActivatedRoute): { query: string | null, scope: string | null } {
  const params = route.snapshot.queryParamMap;
  const query = (params.get("query") ?? '').trim();
  const scope = (params.get("scope") ?? '').trim();
  return { query: query.length > 0 ? query : null, scope: scope.length > 0 ? scope : null };
}

/**
 * @see https://stackoverflow.com/a/68703218
 */
function prefix(options: SearchedResult[]): string {
  // check border cases size 1 array and empty first word
  if (!options[0] || options.length == 1) return options[0].name || "";
  let i = 0;
  // while all words have the same character at position i, increment i
  while (options[0].name[i] && options.every(option => option.name[i] === options[0].name[i]))
    i++;

  // prefix is the substring from the beginning to the last successfully checked i
  return options[0].name.slice(0, i);
}

export class SearchComponent<T> {

  protected readonly search = new FormGroup({
    query: new FormControl<string>(""),
    scope: new FormControl<string>("-1"),
  });

  private readonly formValue = new Subject<{ query: string | null, scope: number | null }>();

  protected readonly scopes = CONFIG.scopes;
  protected readonly results = this.formValue.pipe(
    switchMap(formValue => this.searchService.search(
      formValue.scope === null ? undefined : formValue.scope,
      formValue.query ?? ''
    )),
    map(entries => {
      if (!(entries?.length > 0)) {
        return [];
      }

      if (this.collapse) {
        const commonPrefix0 = prefix(entries);
        const idx = commonPrefix0.lastIndexOf('.');
        const commonPrefix = commonPrefix0.substring(0, idx).split(".");

        const prr = commonPrefix.map(d => d.substring(0, 1)).join(".");

        return entries.map(entry => ({ ...entry, displayName: prr + entry.name.substring(idx) }));
      } else {
        return entries.map(entry => ({ ...entry, displayName: null }));
      }
    })
  );

  protected readonly selectedEntry;
  protected readonly maxSearchResults = MAX_SEARCH_RESULTS;
  protected readonly searchLabel$ = new BehaviorSubject<string>("Search");

  private readonly destroy = new Subject<void>();

  constructor(
    private readonly router: Router,
    private readonly activatedRoute: ActivatedRoute,
    private readonly searchService: SearchService<T>,
    private readonly collapse: boolean,
  ) {
    this.selectedEntry = this.activatedRoute.queryParams.pipe(
      map(({ scope_id, name }) => ({
        scope_id: Number(scope_id),
        name
      }))
    );

    afterNextRender(() => {
      // HACK: setTimeout is needs because hydration? somehow updates the view
      //       after the item was scrolled into view
      setTimeout(() => {
        const element = document.querySelector("a.active");
        element?.scrollIntoView({ behavior: "smooth" });
      }, 300);
    });
  }

  protected ngOnInit0(): void {
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
      .pipe(takeUntil(this.destroy), debounceTime(300))
      .subscribe((form) => {
        const formValue = {
          query: form.query,
          scope: form.scope === null ? null : form.scope
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

  protected ngAfterViewInit0(): void {
    const { query, scope } = getQuery(this.activatedRoute);
    const idx = this.scopes.findIndex(s => s === scope);
    this.search.setValue({ query, scope: idx.toString() })
  }

  protected ngOnDestroy0(): void {
    this.destroy.next(void 0);
    this.destroy.complete();
  }

  protected isActive(opt: SearchedResult): Observable<boolean> {
    return this.selectedEntry.pipe(map(option => option.scope_id === opt.scope_id && option.name === opt.name));
  }

  set searchString(value: string) {
    this.searchLabel$.next(value);
  }
}

@Component({
  selector: 'app-options-search',
  imports: [ReactiveFormsModule, TextFieldComponent, AsyncPipe, RouterLink, DropdownComponent],
  templateUrl: './search.component.html',
  styleUrl: './search.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class OptionsSearchComponent extends SearchComponent<Option> implements OnInit, AfterViewInit, OnDestroy {

  constructor(router: Router, activatedRoute: ActivatedRoute, searchService: OptionsService) {
    super(router, activatedRoute, searchService, true);
  }

  public ngOnInit(): void {
    this.ngOnInit0();
  }

  public ngAfterViewInit(): void {
    this.ngAfterViewInit0();
  }

  public ngOnDestroy(): void {
    this.ngOnDestroy0();
  }

  @Input()
  override set searchString(value: string) {
    super.searchString = value;
  }
}

@Component({
  selector: 'app-packages-search',
  imports: [ReactiveFormsModule, TextFieldComponent, AsyncPipe, RouterLink, DropdownComponent],
  templateUrl: './search.component.html',
  styleUrl: './search.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class PackagesSearchComponent extends SearchComponent<Package> implements OnInit, AfterViewInit, OnDestroy {

  constructor(router: Router, activatedRoute: ActivatedRoute, searchService: PackagesService) {
    super(router, activatedRoute, searchService, false);
  }

  public ngOnInit(): void {
    this.ngOnInit0();
  }

  public ngAfterViewInit(): void {
    this.ngAfterViewInit0();
  }

  public ngOnDestroy(): void {
    this.ngOnDestroy0();
  }

  @Input()
  override set searchString(value: string) {
    super.searchString = value;
  }
}
