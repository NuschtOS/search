import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import __wbg_init, { Index } from '@nuschtos/fixx';
import { BehaviorSubject, Observable, from, map, of, switchMap, tap } from 'rxjs';

export interface SearchedOption {
  idx: number;
  name: string;
}

const CHUNK_SIZE = 100;
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
    from(__wbg_init(`${document.getElementsByTagName('base')[0].href}fixx_bg.wasm`))
      .pipe(switchMap(() => this.http.get(`${document.getElementsByTagName('base')[0].href}index.ixx`, { responseType: 'arraybuffer' })))
      .subscribe(data => this.index.next(Index.read(new Uint8Array(data))));
  }

  public search(scope_id: number | undefined, query: string | null | undefined): Observable<SearchedOption[]> {
    return this.index.pipe(
      map(index => {
        return index ? (query && query.length > 0 ? index.search(scope_id ?? 0, query, MAX_SEARCH_RESULTS).map(option => {
          const opt = ({ idx: option.idx(), name: option.name() });
          //      option.free();
          return opt;
        }) : index.all(scope_id ?? 0, MAX_SEARCH_RESULTS).map((name, idx) => ({ idx, name }))) : [];
      })
    );
  }

  public getByName(name: string | undefined): Observable<Option | undefined> {
    if (typeof name === "undefined" || name.length == 0) {
      return of(undefined);
    }

    return this.index.pipe(
      switchMap(index => {
        const idx = index ? index.get_idx_by_name(name) : undefined;
        return idx ? this.getByIdx(idx) : of(undefined);
      })
    );
  }

  private getByIdx(idx: number): Observable<Option | undefined> {
    const idx_in_chunk = idx % CHUNK_SIZE;
    const chunk = (idx - idx_in_chunk) / CHUNK_SIZE;

    return this.data.pipe(
      switchMap(entries => {
        let options = entries[chunk];

        if (typeof options === "undefined") {
          return this.http.get<Option[]>(`${document.getElementsByTagName('base')[0].href}meta/${chunk}.json`)
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
}
