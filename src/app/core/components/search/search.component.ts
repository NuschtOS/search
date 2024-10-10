import { AfterViewInit, ChangeDetectionStrategy, Component } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { Observable, map, of, switchMap } from 'rxjs';
import { MAX_SEARCH_RESULTS, SearchService, SearchedOption } from '../../data/search.service';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { TextFieldComponent } from "@feel/form";
import { AsyncPipe, NgFor, NgIf } from '@angular/common';

function getQuery(): string | null {
  return new URL(location.href).searchParams.get("query");
}

@Component({
  selector: 'app-search',
  standalone: true,
  imports: [ReactiveFormsModule, TextFieldComponent, NgIf, AsyncPipe, NgFor, RouterLink],
  templateUrl: './search.component.html',
  styleUrl: './search.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class SearchComponent implements AfterViewInit {

  protected readonly search = new FormControl();
  protected readonly results = this.search.valueChanges.pipe(
    switchMap(query => {
      const q = query?.trim();
      if (q !== getQuery()) {
        this.router.navigate([], { queryParams: { query: q }, queryParamsHandling: 'merge' });
      }
      return this.searchService.search(q);
    }),
  );

  protected readonly selectedOption = this.activatedRoute.queryParams.pipe(map(({ option }) => option));
  protected readonly maxSearchResults = MAX_SEARCH_RESULTS;

  constructor(
    private readonly searchService: SearchService,
    private readonly router: Router,
    private readonly activatedRoute: ActivatedRoute,
  ) {
  }

  public ngAfterViewInit(): void {
    this.search.setValue(getQuery());
  }

  protected trackBy(_idx: number, option: SearchedOption): number {
    return option.idx;
  }

  protected isActive(opt: SearchedOption): Observable<boolean> {
    return this.selectedOption.pipe(map(option => option === opt.name));
  }
}

