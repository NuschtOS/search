import { ChangeDetectionStrategy, Component } from '@angular/core';
import { TITLE } from '../../core/config.domain';
import { SearchComponent } from '../../core/components/search/search.component';
import { OptionComponent } from '../../core/components/option/option.component';

@Component({
  selector: 'app-options',
  imports: [
    SearchComponent,
    OptionComponent
  ],
  templateUrl: './options-page.component.html',
  styleUrl: './options-page.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class OptionsPageComponent {

  protected readonly title = TITLE;

}
