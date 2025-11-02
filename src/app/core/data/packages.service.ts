import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { SearchService } from './search.service';

export interface Package {
  attr_name: string,
  eval_error?: boolean,
  broken: boolean,
  description?: string,
  homepages: string[],
  outputs: string[],
  insecure?: boolean,
  name?: string,
  pname?: string,
  unfree?: boolean,
  version?: string,
}

@Injectable({
  providedIn: 'root'
})
export class PackagesService extends SearchService<Package> {

  constructor(http: HttpClient) {
    super(http, "packages");
  }
}
