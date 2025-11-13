import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { catchError, EMPTY, map, Observable, of, tap } from 'rxjs';

interface MatrixProfile {
  displayname: string,
  avatar_url: string,
}

@Injectable({
  providedIn: 'root'
})
export class MatrixService {

  private cache = new Map<string, string>();

  constructor(
    private readonly http: HttpClient,
  ) { }

  public getAvatar(handle: string, width: number, height: number): Observable<string> {
    let profile;

    if (this.cache.has(handle)) {
      profile = of(this.cache.get(handle)!);
    } else {

      profile = this.http.get<MatrixProfile>(
        `https://matrix.org/_matrix/client/r0/profile/${handle}`
      )
        .pipe(
          catchError(() => {
            console.error(`Failed to fetch Matrix profile for ${handle}`);
            return EMPTY;
          }),
          map(({ avatar_url }) => avatar_url),
          tap(avatarUrl => this.cache.set(handle, avatarUrl)),
        );
    }

    return profile.pipe(
      map(avatarUrl =>
        `https://matrix.org/_matrix/media/r0/thumbnail/${avatarUrl.replace('mxc://', '')}?width=${width}&height=${height}&method=crop`
      ),
    );
  }
}
