import { RenderMode, ServerRoute } from '@angular/ssr';

export const serverRoutes: ServerRoute[] = [
  {
    path: '**',
    // TODO: Prerender, currently broken when using base href
    renderMode: RenderMode.Client
  }
];
