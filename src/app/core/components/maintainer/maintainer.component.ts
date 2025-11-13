import { ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { Maintainer, MetaService } from '../../data/meta.service';
import { BehaviorSubject, filter, map, Subject, switchMap, takeUntil } from 'rxjs';
import { AsyncPipe } from '@angular/common';
import { MatrixService } from '../../data/matrix.service';

@Component({
  selector: 'app-maintainer',
  imports: [AsyncPipe],
  templateUrl: './maintainer.component.html',
  styleUrl: './maintainer.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MaintainerComponent implements OnInit, OnDestroy {

  protected githubId$ = new BehaviorSubject<{ scopeId: number, githubId: number } | null>(null);
  protected maintainer$ = new BehaviorSubject<(Maintainer & { githubId: number }) | null>(null);
  protected matrixAvatar$ = new BehaviorSubject<string | null>(null);
  private destroy$ = new Subject<null>();

  constructor(
    private readonly metaService: MetaService,
    private readonly matrixService: MatrixService,
  ) { }

  public ngOnInit(): void {
    this.githubId$
      .pipe(
        takeUntil(this.destroy$),
        filter(value => !!value),
        switchMap(value =>
          this.metaService.getMaintainer(value.scopeId!, value.githubId!)
            .pipe(
              filter(maintainer => !!maintainer),
              map(maintainer => ({ ...maintainer, githubId: value.githubId! }))
            )
        ),
      )
      .subscribe(this.maintainer$);

    this.maintainer$
      .pipe(
        takeUntil(this.destroy$),
        map(maintainer => maintainer?.matrix),
        filter(matrix => !!matrix),
        switchMap(matrix => this.matrixService.getAvatar(matrix!, 24, 24)),
      )
      .subscribe(this.matrixAvatar$);
  }

  public ngOnDestroy(): void {
    this.destroy$.next(null);
    this.destroy$.complete();
  }

  @Input()
  set githubId(value: { scopeId: number, githubId: number }) {
    this.githubId$.next(value);
  }
}
