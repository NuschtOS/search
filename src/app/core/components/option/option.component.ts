import { ChangeDetectionStrategy, Component } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { switchMap, map, merge, of, BehaviorSubject, tap } from 'rxjs';
import { AsyncPipe } from '@angular/common';
import { LoadingIndicatorComponent } from "../loading-indicator/loading-indicator.component";
import { OptionsService } from '../../data/options.service';

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
    private readonly searchService: OptionsService,
  ) {
    this.option = this.activatedRoute.queryParams.pipe(
      tap(() => this.loading.next(true)),
      switchMap(({ scope_id, name }) => merge(of(null), this.searchService.getByName(Number(scope_id), name))),
      tap(() => this.loading.next(false)),
    );

    this.scope = this.activatedRoute.queryParams.pipe(
      switchMap(({ scope_id }) => merge(of(null), this.searchService.getScopes().pipe(map(scopes => scopes[Number(scope_id)])))),
    );
  }

  protected getPackageName(html: string): string {
    const tmp = document.createElement("div");
    tmp.innerHTML = html;
    const match = tmp.innerText.trim().match(/pkgs\.(\w+)(\.override.*)?/);
    return match ? match[1] : '';
  }
}
