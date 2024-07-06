import { AfterViewInit, ChangeDetectionStrategy, Component } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { Observable, map, switchMap } from 'rxjs';
import { SearchService, Option } from '../../data/search.service';
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
      if (q !== getQuery()) this.router.navigate([], { queryParams: { query: q }, queryParamsHandling: 'merge' });
      if (q && q.length > 0) {
        return this.searchService.search(q);
      } else {
        return this.searchService.all();
      }
    }),
  );
  protected readonly selectedOption = this.activatedRoute.queryParams.pipe(map(({ option }) => option));

  constructor(
    private readonly searchService: SearchService,
    private readonly router: Router,
    private readonly activatedRoute: ActivatedRoute,
  ) {
  }

  public ngAfterViewInit(): void {
    this.search.setValue(getQuery());
  }

  protected trackBy(_idx: number, { name }: Option): string {
    return name;
  }

  protected isActive({ name }: Option): Observable<boolean> {
    return this.selectedOption.pipe(map(option => option === name));
  }
}

