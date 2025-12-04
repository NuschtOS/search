import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, filter, map, Observable } from 'rxjs';
import { CONFIG } from '../config.domain';

export interface Meta {
  scopes: Record<string, ScopeMeta>;
}

export interface ScopeMeta {
  licenses: Record<string, License>,
  maintainers: Record<string, Maintainer>,
  teams: Record<string, { members: number[], scope: string }>,
}

export interface License {
  free: boolean;
  spdxId?: string;
  url?: string;
  fullName: string;
  redistributable: boolean;
}

export interface Maintainer {
  name: string;
  github: string;
  email?: string;
  matrix?: string;
}

@Injectable({
  providedIn: 'root'
})
export class MetaService {

  private readonly meta = new BehaviorSubject<Meta | null>(null);

  constructor(
    private readonly http: HttpClient,
  ) {
    this.http.get<Meta>(`${CONFIG.dataBase}meta.json`)
      .subscribe({next: meta => this.meta.next(meta)});
  }

  public getLicense(scopeId: number, shortName: string): Observable<License | null> {
    return this.meta.pipe(
      filter(meta => !!meta),
      map(meta => meta?.scopes[String(scopeId)]?.licenses[shortName] ?? null)
    );
  }

  public getMaintainer(scopeId: number, githubId: number): Observable<Maintainer | null> {
    return this.meta.pipe(
      filter(meta => !!meta),
      map(meta => meta?.scopes[String(scopeId)]?.maintainers[String(githubId)] ?? null)
    );
  }

  public getTeamMemberIds(scopeId: number, teamName: string): Observable<{ members: number[], scope: string } | null> {
    return this.meta.pipe(
      filter(meta => !!meta),
      map(meta => meta!.scopes[String(scopeId)]?.teams[String(teamName)])
    );
  }
}
