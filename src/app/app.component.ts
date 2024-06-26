import { AfterViewInit, ChangeDetectionStrategy, Component, OnInit } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterLink, RouterOutlet } from '@angular/router';
import { SearchService } from './core/search.service';
import { of, switchMap } from 'rxjs';
import { AsyncPipe, NgFor } from '@angular/common';
import { TextFieldComponent } from "@feel/form";
import { OptionComponent } from './pages/option/option.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, AsyncPipe, NgFor, ReactiveFormsModule, TextFieldComponent, RouterLink, OptionComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AppComponent implements AfterViewInit {

  protected readonly search = new FormControl();
  protected readonly results = this.search.valueChanges.pipe(
    switchMap(query => {
      const q = query?.trim();
      if (q !== AppComponent.getQuery()) this.router.navigate([], { queryParams: { query: q }, queryParamsHandling: 'merge' });
      if (q && q.length > 0) {
        return this.searchService.search(q);
      } else {
        return of([]);
      }
    }),
  );

  constructor(
    private readonly searchService: SearchService,
    private readonly router: Router,
  ) {
  }

  ngAfterViewInit(): void {
    this.search.setValue(AppComponent.getQuery());
  }
  private static getQuery(): string | null {
    return new URL(location.href).searchParams.get("query");
  }
}
