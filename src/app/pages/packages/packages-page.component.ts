import { ChangeDetectionStrategy, Component } from '@angular/core';
import { TITLE } from '../../core/config.domain';
import { PackagesSearchComponent } from '../../core/components/search/search.component';
import { PackagesService } from '../../core/data/packages.service';
import { PackageComponent } from "../../core/components/package/package.component";

@Component({
  selector: 'app-packages-page.component',
  imports: [
    PackageComponent,
    PackagesSearchComponent,
  ],
  templateUrl: './packages-page.component.html',
  styleUrl: './packages-page.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class PackagesPageComponent {

  protected readonly title = TITLE;

  constructor(
    protected readonly searchService: PackagesService
  ) { }
}
