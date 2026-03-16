import { ChangeDetectionStrategy, Component, Inject, LOCALE_ID, OnDestroy } from '@angular/core';
import { CONFIG } from '../../core/config.domain';
import { OptionComponent } from '../../core/components/option/option.component';
import { OptionsService } from '../../core/data/options.service';
import { OptionsSearchComponent } from '../../core/components/search/search.component';
import { RouterLink } from '@angular/router';
import { AsyncPipe, DecimalPipe, formatNumber } from '@angular/common';
import { Subject } from 'rxjs/internal/Subject';
import { BehaviorSubject } from 'rxjs/internal/BehaviorSubject';
import { takeUntil } from 'rxjs/internal/operators/takeUntil';

@Component({
  selector: 'app-options',
  imports: [
    OptionComponent,
    OptionsSearchComponent,
    RouterLink,
    AsyncPipe,
  ],
  templateUrl: './options-page.component.html',
  styleUrl: './options-page.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OptionsPageComponent implements OnDestroy {

  protected readonly searchLabel$ = new BehaviorSubject<string>("Search .... options");
  private readonly destroy$ = new Subject<void>();


  constructor(
    protected readonly searchService: OptionsService,
    @Inject(LOCALE_ID) private readonly locale: string
  ) {
    this.searchService.getIndexSize()
      .pipe(takeUntil(this.destroy$))
      .subscribe(size => {
        this.searchLabel$.next(`Search ${formatNumber(size ?? 0, this.locale)} options`);
      });
  }
  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
