import { ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { Maintainer } from '../../data/meta.service';
import { BehaviorSubject, catchError, EMPTY, filter, map, Subject, switchMap, takeUntil } from 'rxjs';
import { AsyncPipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { MatrixService } from '../../data/matrix.service';

@Component({
  selector: 'app-maintainer',
  imports: [AsyncPipe],
  templateUrl: './maintainer.component.html',
  styleUrl: './maintainer.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class MaintainerComponent implements OnInit, OnDestroy {

  protected maintainer$ = new BehaviorSubject<(Maintainer & { githubId: number }) | null>(null);
  protected matrixAvatar$ = new BehaviorSubject<string | null>(null);
  private destroy$ = new Subject<null>();

  constructor(
    private readonly matrix: MatrixService,
  ) { }

  public ngOnInit(): void {
    this.maintainer$.pipe(
      takeUntil(this.destroy$),
      map(maintainer => maintainer?.matrix),
      filter(matrix => !!matrix),
      switchMap(matrix => this.matrix.getAvatar(matrix!, 24, 24)),
    )
      .subscribe(this.matrixAvatar$);
  }

  public ngOnDestroy(): void {
    this.destroy$.next(null);
    this.destroy$.complete();
  }

  @Input()
  set maintainer(value: Maintainer & { githubId: number }) {
    this.maintainer$.next(value);
  }
}
