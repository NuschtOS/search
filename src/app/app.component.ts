import { ChangeDetectionStrategy, Component } from '@angular/core';
import { SearchComponent } from './core/components/search/search.component';
import { OptionComponent } from './core/components/option/option.component';
import { TITLE } from './core/config.domain';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [SearchComponent, OptionComponent],
  templateUrl: './app.component.html',
  styleUrl: './app.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class AppComponent {

  protected readonly title = TITLE;
}
