import { Component } from '@angular/core';
import { SearchService } from '../../core/search.service';
import { ActivatedRoute } from '@angular/router';
import { switchMap } from 'rxjs';
import { AsyncPipe, NgFor, NgIf } from '@angular/common';

@Component({
  selector: 'app-option',
  standalone: true,
  imports: [NgIf, NgFor, AsyncPipe],
  templateUrl: './option.component.html',
  styleUrl: './option.component.scss'
})
export class OptionComponent {

  protected readonly option = this.activatedRoute.params.pipe(
    switchMap(({option}) => this.searchService.getByName(option)),
  );

  constructor(
    private readonly activatedRoute: ActivatedRoute,
    private readonly searchService: SearchService,
  ) { }
}
