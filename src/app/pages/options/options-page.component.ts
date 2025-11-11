import { ChangeDetectionStrategy, Component } from '@angular/core';
import { CONFIG } from '../../core/config.domain';
import { OptionComponent } from '../../core/components/option/option.component';
import { OptionsService } from '../../core/data/options.service';
import { OptionsSearchComponent } from '../../core/components/search/search.component';
import { RouterLink } from '@angular/router';
import { AsyncPipe, DecimalPipe } from '@angular/common';

@Component({
  selector: 'app-options',
  imports: [
    OptionComponent,
    OptionsSearchComponent,
    RouterLink,
    AsyncPipe,
    DecimalPipe,
  ],
  templateUrl: './options-page.component.html',
  styleUrl: './options-page.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OptionsPageComponent {

  protected readonly title = CONFIG.title;

  constructor(
    protected readonly searchService: OptionsService
  ) { }
}
