import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, map, of } from 'rxjs';

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

  private nextUpdate = 0;
  private readonly data = new BehaviorSubject<Option[]>([]);

  constructor(
    private readonly http: HttpClient,
  ) { }

  private update() {
    const now = Date.now();
    if (this.nextUpdate < now) {
      this.nextUpdate = now + 1000 * 60 * 10;
      this.http.get<Record<string, Omit<Option, "name">>>(`${document.getElementsByTagName('base')[0].href}options.json`)
        .subscribe(data => this.data.next(Object.entries(data).map(([name, data]) => ({ name, ...data }))));
    }
  }

  public search(query: string): Observable<Option[]> {
    this.update();

    const search = query.toLowerCase().split('*');
    if (search.length === 0) {
      return of([]);
    }

    return this.data.pipe(map(options => {
      const result = [];

      let i = 0;

      for (const option of options) {
        let remainingName = option.name.toLowerCase();
        let idx = -1;

        outer: {
          for (const segment of search) {
            idx = remainingName.indexOf(segment);
            if (idx !== -1) {
              remainingName = remainingName.substring(idx + segment.length);
            } else {
              break outer;
            }
          }

          result.push(option);
          i++;
          // TODO: pagination
          if (i === 500) {
            return result;
          }
        }
      }
      return result;
    }));
  }

  public getByName(name: string): Observable<Option | undefined> {
    this.update();
    return this.data.pipe(map(options => options.find(option => option.name === name)));
  }

  public all(): Observable<Option[]> {
    return this.data.pipe(map(options => {
      const result = [];
      let i = 0;
      for (const option of options) {
        result.push(option);
        i++;
        // TODO: pagination
        if (i === 500) {
          return result;
        }
      }
      return result;
    }));
  }
}
