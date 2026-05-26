import { ComponentFixture, TestBed } from '@angular/core/testing';

import { MaintainerComponent } from './maintainer.component';

describe('MaintainerComponent', () => {
  let component: MaintainerComponent;
  let fixture: ComponentFixture<MaintainerComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [MaintainerComponent]
    })
    .compileComponents();

    fixture = TestBed.createComponent(MaintainerComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
