import { TestBed } from '@angular/core/testing';

import { MaintainerService } from './maintainer.service';

describe('MaintainerService', () => {
  let service: MaintainerService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(MaintainerService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
