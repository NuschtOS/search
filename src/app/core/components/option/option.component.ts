import { ChangeDetectionStrategy, Component } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { switchMap, map } from 'rxjs';
import { AsyncPipe, NgFor, NgIf } from '@angular/common';
import { SearchService } from '../../data/search.service';

@Component({
    selector: 'app-option',
    imports: [NgIf, NgFor, AsyncPipe, RouterLink],
    templateUrl: './option.component.html',
    styleUrl: './option.component.scss',
    changeDetection: ChangeDetectionStrategy.OnPush
})
export class OptionComponent {

  protected readonly option = this.activatedRoute.queryParams.pipe(
    switchMap(({ option_scope, option }) => this.searchService.getByName(Number(option_scope), option)),
  );

  protected readonly scope = this.activatedRoute.queryParams.pipe(
    switchMap(({ option_scope }) => this.searchService.getScopes().pipe(map(scopes => scopes[Number(option_scope)]))),
  );

  constructor(
    private readonly activatedRoute: ActivatedRoute,
    private readonly searchService: SearchService,
  ) { }
}
