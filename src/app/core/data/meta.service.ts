import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { map, Observable } from 'rxjs';

export interface Meta {
  scopes: Record<string, ScopeMeta>;
}

export interface ScopeMeta {
  licenses: Record<string, License>,
  maintainers: Record<string, Maintainer>,
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

  private readonly meta;

  constructor(
    private readonly http: HttpClient,
  ) {
    this.meta = this.http.get<Meta>(`${this.getBaseHref()}meta.json`);
  }

  public getLicense(scopeId: number, shortName: string): Observable<License> {
    return this.meta.pipe(map(meta => meta.scopes[scopeId].licenses[shortName]));
  }

  public getMaintainer(scopeId: number, githubId: number): Observable<Maintainer> {
    return this.meta.pipe(map(meta => meta.scopes[scopeId].maintainers[githubId]));
  }

  // NOTE: Can not use Angulars LocationStrategy, because its broken on SSR, because for some reason SSR does not respect base href's.
  private getBaseHref(): string {
    if (typeof document !== "undefined") {
      return document.getElementsByTagName('base')[0].href;
    } else {
      return "/";
    }
  }
}
