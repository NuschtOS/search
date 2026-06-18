import { ChangeDetectionStrategy, Component, Inject, LOCALE_ID, OnDestroy } from '@angular/core';
import { DOCUMENT } from '@angular/common';
import { OptionComponent } from '../../core/components/option/option.component';
import { OptionsService } from '../../core/data/options.service';
import { OptionsSearchComponent } from '../../core/components/search/search.component';
import { RouterLink } from '@angular/router';
import { AsyncPipe, formatNumber } from '@angular/common';
import { BehaviorSubject, Subject, takeUntil } from 'rxjs';
import { clearOpenSearchLink, setOpenSearchLink } from '../../core/opensearch-link';

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
    @Inject(DOCUMENT) private readonly document: Document,
    @Inject(LOCALE_ID) private readonly locale: string
  ) {
    setOpenSearchLink(this.document, 'options');
    this.searchService.getIndexSize()
      .pipe(takeUntil(this.destroy$))
      .subscribe(size => {
        this.searchLabel$.next(`Search ${formatNumber(size ?? 0, this.locale)} options`);
      });
  }
  ngOnDestroy(): void {
    clearOpenSearchLink(this.document);
    this.destroy$.next();
    this.destroy$.complete();
  }
}
