import { HttpClient } from '@angular/common/http';
import __wbg_init, { Index } from '@nuschtos/fixx';
import { BehaviorSubject, forkJoin, from, map, Observable, of, switchMap, tap } from 'rxjs';

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
      wasm: this.http.get(`${this.getBaseHref()}fixx_bg.wasm`, { responseType: 'arraybuffer' }).pipe(switchMap(data => from(__wbg_init(data)))),
      index: this.http.get(`${this.getBaseHref()}${this.kind}/index.ixx`, { responseType: 'arraybuffer' })
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

  public search(scope_id: number | undefined, query: string): Observable<SearchedResult[]> {
    return this.index.pipe(
      map(index => {
        return index ? index.search(scope_id, query, MAX_SEARCH_RESULTS).map(entry => {
          const opt = ({ idx: entry.idx(), scope_id: entry.scope_id(), name: entry.name() });
          //      option.free();
          return opt;
        }) : [];
      })
    );
  }

  public getByName(scope_id: number, name: string | undefined): Observable<T | undefined> {
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

  private getByIdx(idx: number, chunk_size: number): Observable<T | undefined> {
    const idx_in_chunk = idx % chunk_size;
    const chunk = (idx - idx_in_chunk) / chunk_size;

    return this.data.pipe(
      switchMap(entries => {
        let options = entries[chunk];

        if (typeof options === "undefined") {
          return this.http.get<T[]>(`${this.getBaseHref()}${this.kind}/meta/${chunk}.json`)
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
