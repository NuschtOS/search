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

  public getAvatar(handle: string, width: number, height: number): Observable<string | null> {
    const cached = this.cache.get(handle);
    if (cached) {
      return of(`https://matrix.org/_matrix/media/r0/thumbnail/${cached.replace('mxc://', '')}?width=${width}&height=${height}&method=crop`);
    }

    return this.http.get<MatrixProfile>(
      `https://matrix.org/_matrix/client/r0/profile/${handle}`
    ).pipe(
      catchError(error => {
        console.error(`Failed to fetch Matrix profile for handle: ${handle}`, error);
        return of(null);
      }),
      map(result => result ? result.avatar_url : null),
      tap(avatarUrl => {
        this.cache.set(handle, avatarUrl);
      }),
      switchMap(avatarUrl => {
        if (!avatarUrl || typeof avatarUrl !== 'string' || !avatarUrl.startsWith('mxc://')) {
          console.warn(`No or invalid avatar URL for Matrix handle: ${handle}`);
          return of(null);
        }
        return of(`https://matrix.org/_matrix/media/r0/thumbnail/${avatarUrl.replace('mxc://', '')}?width=${width}&height=${height}&method=crop`);
      })
    );
  }
}
