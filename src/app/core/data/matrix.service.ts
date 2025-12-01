import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { catchError, EMPTY, map, Observable, of, switchMap, tap } from 'rxjs';

interface MatrixProfile {
  displayname: string,
  // this field is omitted if the user has no avatar
  avatar_url: string | null,
}

@Injectable({
  providedIn: 'root'
})
export class MatrixService {

  private cache = new Map<string, string | null>();

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
          catchError((error) => {
            console.error(`Failed to fetch Matrix profile for handle: ${handle}`, error);
            return EMPTY;
          }),
          map(({ avatar_url }) => avatar_url),
          tap(avatarUrl => {
            if (avatarUrl === null) {
              console.warn(`No avatar URL found for Matrix handle: ${handle}`);
            }
            this.cache.set(handle, avatarUrl);
        }),
        );
    }

    return profile.pipe(
      switchMap(avatarUrl => {
        if (!avatarUrl) {
          return EMPTY;
        }

        if (typeof avatarUrl !== 'string' || !avatarUrl.startsWith('mxc://')) {
          console.warn(`Invalid avatar URL for Matrix handle: ${handle}`);
          return EMPTY;
        }

        return of(`https://matrix.org/_matrix/media/r0/thumbnail/${avatarUrl.replace('mxc://', '')}?width=${width}&height=${height}&method=crop`);
      }),
    );
  }
}
