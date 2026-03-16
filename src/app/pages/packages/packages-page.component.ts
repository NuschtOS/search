import { ChangeDetectionStrategy, Component, Inject, LOCALE_ID, OnDestroy } from '@angular/core';
import { CONFIG } from '../../core/config.domain';
import { PackagesSearchComponent } from '../../core/components/search/search.component';
import { PackagesService } from '../../core/data/packages.service';
import { PackageComponent } from "../../core/components/package/package.component";
import { RouterLink } from '@angular/router';
import { AsyncPipe, formatNumber } from '@angular/common';
import { BehaviorSubject, Subject, takeUntil } from 'rxjs';

@Component({
  selector: 'app-packages-page.component',
  imports: [
    PackageComponent,
    PackagesSearchComponent,
    RouterLink,
    AsyncPipe,
  ],
  templateUrl: './packages-page.component.html',
  styleUrl: './packages-page.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PackagesPageComponent implements OnDestroy {

  protected readonly searchLabel$ = new BehaviorSubject<string>("Search .... packages");
  private readonly destroy$ = new Subject<void>();

  constructor(
    protected readonly searchService: PackagesService,
    @Inject(LOCALE_ID) private readonly locale: string
  ) {
    this.searchService.getIndexSize()
      .pipe(takeUntil(this.destroy$))
      .subscribe(size => {
        this.searchLabel$.next(`Search ${formatNumber(size ?? 0, this.locale)} packages`);
      });
  }
  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }
}
