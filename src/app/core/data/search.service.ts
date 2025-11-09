import { HttpClient } from '@angular/common/http';
import __wbg_init, { Index } from '@nuschtos/fixx';
import { BehaviorSubject, forkJoin, from, map, Observable, of, switchMap, tap } from 'rxjs';
import { CONFIG } from '../config.domain';

export interface SearchedResult {
  idx: number;
  scope_id: number;
  name: string;
}

export const MAX_SEARCH_RESULTS = 500;

export abstract class SearchService<T> {

  private readonly index = new BehaviorSubject<Index | null>(null);
  private readonly data = new BehaviorSubject<Record<number, T[]>>({});

  constructor(
    private readonly http: HttpClient,
    private readonly kind: string,
  ) {
    forkJoin({
      wasm: this.http.get(`${CONFIG.baseHref}fixx_bg.wasm`, { responseType: 'arraybuffer' }).pipe(switchMap(data => from(__wbg_init(data)))),
      index: this.http.get(`${CONFIG.baseHref}${this.kind}/index.ixx`, { responseType: 'arraybuffer' })
    })
      .subscribe({
        next: ({ index }) => this.index.next(Index.read(new Uint8Array(index))),
        error: error => console.error(`Failed to load ${kind} index:`, error),
      });
  }

  public search(scopeId: number | undefined, query: string): Observable<SearchedResult[]> {
    return this.index.pipe(
      map(index => {
        return index ? index.search(scopeId, query, MAX_SEARCH_RESULTS).map(entry => {
          const opt = ({ idx: entry.idx(), scope_id: entry.scope_id(), name: entry.name() });
          //      option.free();
          return opt;
        }) : [];
      })
    );
  }

  public getByName(scopeId: number, name: string | undefined): Observable<T | undefined> {
    if (typeof name === "undefined" || name.length == 0) {
      return of(undefined);
    }

    return this.index.pipe(
      switchMap(index => {
        const idx = index?.get_idx_by_name(scopeId, name);
        return typeof idx === "number" ? this.getByIdx(idx, index!.chunk_size()) : of(undefined);
      })
    );
  }

  private getByIdx(idx: number, chunkSize: number): Observable<T | undefined> {
    const idx_in_chunk = idx % chunkSize;
    const chunk = (idx - idx_in_chunk) / chunkSize;

    return this.data.pipe(
      switchMap(entries => {
        let options = entries[chunk];

        if (typeof options === "undefined") {
          return this.http.get<T[]>(`${CONFIG.baseHref}${this.kind}/meta/${chunk}.json`)
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
