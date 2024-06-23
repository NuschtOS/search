import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, map } from 'rxjs';

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
      this.http.get<Record<string, Omit<Option, "name">>>("/options.json")
        .subscribe(data => this.data.next(Object.entries(data).map(([name, data]) => ({ name, ...data }))));
    }
  }

  public search(query: string): Observable<Option[]> {
    this.update();
    return this.data.pipe(map(options => options.filter(option => {
      return option.name.includes(query)
    })));
  }
  public getByName(name: string): Observable<Option | undefined> {
    this.update();
    return this.data.pipe(map(options => options.find(option => option.name === name)));
  }
}
