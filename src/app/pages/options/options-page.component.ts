import { ChangeDetectionStrategy, Component } from '@angular/core';
import { TITLE } from '../../core/config.domain';
import { OptionComponent } from '../../core/components/option/option.component';
import { OptionsService } from '../../core/data/options.service';
import { OptionsSearchComponent } from '../../core/components/search/search.component';

@Component({
  selector: 'app-options',
  imports: [
    OptionComponent,
    OptionsSearchComponent,
  ],
  templateUrl: './options-page.component.html',
  styleUrl: './options-page.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OptionsPageComponent {

  protected readonly title = TITLE;

  constructor(
    protected readonly searchService: OptionsService
  ) { }
}
