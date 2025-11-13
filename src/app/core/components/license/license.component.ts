import { ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { BehaviorSubject, filter, mergeMap, Subject, switchMap, takeUntil, tap } from 'rxjs';
import { License, MetaService } from '../../data/meta.service';
import { AsyncPipe } from '@angular/common';

@Component({
  selector: 'app-license',
  imports: [AsyncPipe],
  templateUrl: './license.component.html',
  styleUrl: './license.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class LicenseComponent implements OnInit, OnDestroy {

  protected shortName$ = new BehaviorSubject<{ scopeId: number, shortName: string } | null>(null);
  protected license$ = new BehaviorSubject<License | null>(null);
  private destroy$ = new Subject<null>();

  constructor(
    private readonly metaService: MetaService,
  ) { }

  public ngOnInit(): void {
    this.shortName$
      .pipe(
        takeUntil(this.destroy$),
        filter(value => !!value),
        mergeMap(({ scopeId, shortName }) => this.metaService.getLicense(scopeId, shortName)),
      )
      .subscribe(this.license$);
  }

  public ngOnDestroy(): void {
    this.destroy$.next(null);
    this.destroy$.complete();
  }

  @Input()
  set shortName(value: { scopeId: number, shortName: string }) {
    this.shortName$.next(value);
  }
}
