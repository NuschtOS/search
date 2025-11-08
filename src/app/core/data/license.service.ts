import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

export interface License {
  free: boolean;
  spdxId: string;
  url: string;
  fullName: string;
  redistributable: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class LicenseService {

  private readonly licenses;

  constructor(
    private readonly http: HttpClient,
  ) {
    this.licenses = this.http.get<License[]>(`${this.getBaseHref()}licenses.json`);
  }

  public getLicenses(): Observable<License[]> {
    return this.licenses;
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
