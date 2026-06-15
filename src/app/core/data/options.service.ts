import { Injectable } from '@angular/core';
import { SearchService } from './search.service';
import { HttpClient } from '@angular/common/http';

export interface Option {
  declarations?: string[]
  default?: string
  description: string
  example?: string
  read_only: boolean
  type: string
  name: string
}

@Injectable({
  providedIn: 'root'
})
export class OptionsService extends SearchService<Option> {

  constructor(http: HttpClient) {
    super(http, "options");
  }
}
