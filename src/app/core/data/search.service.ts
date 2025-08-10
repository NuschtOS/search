import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import __wbg_init, { Index } from '@nuschtos/fixx';
import { BehaviorSubject, forkJoin, from, map, Observable, of, switchMap, tap } from 'rxjs';
import { LocationStrategy } from '@angular/common';

export interface SearchedOption {
  idx: number;
  scope_id: number;
  name: string;
}

export const MAX_SEARCH_RESULTS = 500;

// https://transform.tools/json-to-typescript
export interface Option {
  declarations: string[]
  default?: string
  description: string
  example?: string
  readOnly: boolean
  type: string
  name: string
}

@Injectable({
  providedIn: 'root'
})
export class SearchService {

  private readonly index = new BehaviorSubject<Index | null>(null);
  private readonly data = new BehaviorSubject<Record<number, Option[]>>({});

  constructor(
    private readonly http: HttpClient,
  ) {
    forkJoin({
      wasm: this.http.get(`${this.getBaseHref()}fixx_bg.wasm`, { responseType: 'arraybuffer' }).pipe(switchMap(data => from(__wbg_init(data)))),
      index: this.http.get(`${this.getBaseHref()}index.ixx`, { responseType: 'arraybuffer' })
    })
      .subscribe(({ index }) => this.index.next(Index.read(new Uint8Array(index))));
  }


  // NOTE: Can not use Angulars LocationStrategy, because its broken on SSR, because for some reason SSR does not respect base href's.
  private getBaseHref(): string {
    if (typeof document !== "undefined") {
      return document.getElementsByTagName('base')[0].href;
    } else {
      return "/";
    }
  }

  public search(scope_id: number | undefined, query: string): Observable<SearchedOption[]> {
    return this.index.pipe(
      map(index => {
        return index ? index.search(scope_id, query, MAX_SEARCH_RESULTS).map(option => {
          const opt = ({ idx: option.idx(), scope_id: option.scope_id(), name: option.name() });
          //      option.free();
          return opt;
        }) : [];
      })
    );
  }

  public getByName(scope_id: number, name: string | undefined): Observable<Option | undefined> {
    if (typeof name === "undefined" || name.length == 0) {
      return of(undefined);
    }

    return this.index.pipe(
      switchMap(index => {
        const idx = index?.get_idx_by_name(scope_id, name);
        return typeof idx === "number" ? this.getByIdx(idx, index!.chunk_size()) : of(undefined);
      })
    );
  }

  private getByIdx(idx: number, chunk_size: number): Observable<Option | undefined> {
    const idx_in_chunk = idx % chunk_size;
    const chunk = (idx - idx_in_chunk) / chunk_size;

    return this.data.pipe(
      switchMap(entries => {
        let options = entries[chunk];

        if (typeof options === "undefined") {
          return this.http.get<Option[]>(`${this.getBaseHref()}meta/${chunk}.json`)
            .pipe(tap(options => {
              entries[chunk] = options;
              return this.data.next(entries);
            }));
        }

        return of(options);
      }),
      map(options => options[idx_in_chunk]),
    );
  }

  public getScopes(): Observable<string[]> {
    return this.index.pipe(map(index => index ? index.scopes() : []));
  }
}
