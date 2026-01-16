import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { SearchService } from './search.service';

export interface Package {
  attrName: string,
  broken?: boolean,
  changelogs?: string[],
  cpe?: string,
  declaration?: string,
  description?: string,
  disabled?: boolean,
  downloadPage?: string,
  evalError?: boolean,
  homepages?: string[],
  knownVulnerabilities?: string[],
  licenses?: string[],
  longDescription?: string,
  maintainers?: number[],
  name?: string,
  outputs: string[],
  pname?: string,
  possibleCpes?: string[],
  purl: string,
  teams?: string[],
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
