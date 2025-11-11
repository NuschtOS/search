import { ChangeDetectionStrategy, Component } from '@angular/core';
import { CONFIG } from '../../core/config.domain';
import { PackagesSearchComponent } from '../../core/components/search/search.component';
import { PackagesService } from '../../core/data/packages.service';
import { PackageComponent } from "../../core/components/package/package.component";
import { RouterLink } from '@angular/router';
import { AsyncPipe, DecimalPipe } from '@angular/common';

@Component({
  selector: 'app-packages-page.component',
  imports: [
    PackageComponent,
    PackagesSearchComponent,
    RouterLink,
    AsyncPipe,
    DecimalPipe,
  ],
  templateUrl: './packages-page.component.html',
  styleUrl: './packages-page.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PackagesPageComponent {

  protected readonly title = CONFIG.title;

  constructor(
    protected readonly searchService: PackagesService
  ) { }
}
