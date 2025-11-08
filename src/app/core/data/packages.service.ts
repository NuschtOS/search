import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { SearchService } from './search.service';

export interface Package {
  attrName: string,
  broken?: boolean,
  declaration?: string,
  description?: string,
  eval_error?: boolean,
  homepages: string[],
  knownVulnerabilities: string[],
  licenses: string[],
  maintainers: string[],
  name?: string,
  outputs: string[],
  pname?: string,
  teams: string[],
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
