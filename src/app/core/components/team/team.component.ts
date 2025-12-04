import { ChangeDetectionStrategy, Component, Input, OnDestroy, OnInit } from '@angular/core';
import { MetaService } from '../../data/meta.service';
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
  protected teamData$ = new BehaviorSubject<{ members: number[], scope: string} | null>(null);
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
      )
      .subscribe(value => {
        this.scopeId$.next(value!.scopeId);
      });

    this.teamName$
      .pipe(
        takeUntil(this.destroy$),
        filter(value => !!value),
        switchMap(value =>
          this.metaService.getTeamMemberIds(value.scopeId!, value.teamName!)
            .pipe(
              filter(teamData => !!teamData),
            )
        ),
      )
      .subscribe(teamData => this.teamData$.next(teamData));
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
