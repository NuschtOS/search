import { AfterViewInit, ChangeDetectionStrategy, Component } from '@angular/core';
import { FormControl, ReactiveFormsModule } from '@angular/forms';
import { Router, RouterLink, RouterOutlet } from '@angular/router';
import { Option, SearchService } from './core/search.service';
import { switchMap } from 'rxjs';
import { AsyncPipe, NgFor, NgIf } from '@angular/common';
import { TextFieldComponent } from "@feel/form";
import { OptionComponent } from './pages/option/option.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, AsyncPipe, NgFor, ReactiveFormsModule, TextFieldComponent, RouterLink, OptionComponent, NgIf],
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
        return this.searchService.all();
      }
    }),
  );

  constructor(
    private readonly searchService: SearchService,
    private readonly router: Router,
  ) {
  }

  public ngAfterViewInit(): void {
    this.search.setValue(AppComponent.getQuery());
  }

  private static getQuery(): string | null {
    return new URL(location.href).searchParams.get("query");
  }

  protected trackBy(_idx: number, { name }: Option): string {
    return name;
  }
}
