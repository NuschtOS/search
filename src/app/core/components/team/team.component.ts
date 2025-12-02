import { ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { Maintainer, MetaService } from '../../data/meta.service';
import { BehaviorSubject, filter, map, Subject, switchMap, takeUntil } from 'rxjs';
import { AsyncPipe } from '@angular/common';
import { MaintainerComponent } from '../maintainer/maintainer.component';

@Component({
  selector: 'app-team',
  imports: [AsyncPipe, MaintainerComponent],
  templateUrl: './team.component.html',
  styleUrl: './team.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class TeamComponent implements OnInit, OnDestroy {
  protected maintainerIds$ = new BehaviorSubject<number[]>([]);
  protected readonly scopeId$ = new BehaviorSubject<number | null>(null);
  protected teamName$ = new BehaviorSubject<{ scopeId: number, teamName: string} | null>(null);
  private destroy$ = new Subject<null>();

  constructor(
    private readonly metaService: MetaService,
  ) { }

  public ngOnInit(): void {
    this.teamName$
      .pipe(
        takeUntil(this.destroy$),
        filter(value => !!value),
        switchMap(value =>
          this.metaService.getTeamMemberIds(value.scopeId!, value.teamName!)
            .pipe(
              filter(maintainerIds => !!maintainerIds),
              map(maintainerIds => maintainerIds)
            )
        ),
      )
      .subscribe(this.maintainerIds$);

    this.scopeId$
      .pipe(
        takeUntil(this.destroy$),
        filter(value => !!value),
        map(scopeId => scopeId!)
      )
      .subscribe(this.scopeId$);
  }

  public ngOnDestroy(): void {
    this.destroy$.next(null);
    this.destroy$.complete();
  }

  @Input()
  set teamName(value: { scopeId: number, teamName: string }) {
    this.teamName$.next(value);
  }
}
