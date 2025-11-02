import { TestBed } from '@angular/core/testing';

import { OptionsService } from './options.service';

describe('OptionsService', () => {
  let service: OptionsService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(OptionsService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
