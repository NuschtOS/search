import { ChangeDetectionStrategy, Component, OnDestroy } from '@angular/core';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { switchMap, merge, of, BehaviorSubject, tap, Subject, takeUntil } from 'rxjs';
import { AsyncPipe } from '@angular/common';
import { LoadingIndicatorComponent } from "../loading-indicator/loading-indicator.component";
import { OptionsService } from '../../data/options.service';
import { CONFIG } from '../../config.domain';

@Component({
  selector: 'app-option',
  imports: [AsyncPipe, RouterLink, LoadingIndicatorComponent],
  templateUrl: './option.component.html',
  styleUrl: './option.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class OptionComponent implements OnDestroy {

  protected readonly loading = new BehaviorSubject(false);
  protected readonly option;
  protected readonly scopes = CONFIG.scopes
    .map((scope, idx) => Object.assign({ id: idx }, scope))
    .filter(scope => scope.optionsEnabled);
  private readonly destroy$ = new Subject<void>();

  constructor(
    private readonly activatedRoute: ActivatedRoute,
    private readonly searchService: OptionsService,
  ) {
    this.option = this.activatedRoute.queryParams.pipe(
      takeUntil(this.destroy$),
      tap(() => this.loading.next(true)),
      switchMap(({ scope_id, name }) => merge(of(null), this.searchService.getByName(Number(scope_id), name))),
      tap(() => this.loading.next(false)),
    );
  }

  public ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  protected getPackageName(html: string): string {
    const tmp = document.createElement("div");
    tmp.innerHTML = html;
    const match = tmp.innerText.trim().match(/pkgs\.(.+?)(\.override.*)?$/);
    return match ? match[1] : '';
  }

  protected getScope(id: number): (typeof CONFIG.scopes)[number] | undefined {
    return this.scopes.find(scope => scope.id === id);
  }
}
