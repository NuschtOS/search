import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export interface Maintainer {
  name: string;
  github: string;
  githubId: string;
  email?: string;
  matrix?: string;
}

@Injectable({
  providedIn: 'root'
})
export class MaintainerService {

  private readonly maintainers;

  constructor(
    private readonly http: HttpClient,
  ) {
    this.maintainers = this.http.get<Maintainer[]>(`${this.getBaseHref()}maintainers.json`);
  }

  public getLicenses(): Observable<Maintainer[]> {
    return this.maintainers;
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
