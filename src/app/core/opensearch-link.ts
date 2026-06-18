import { CONFIG } from './config.domain';

export type OpenSearchType = 'options' | 'packages';

export function setOpenSearchLink(document: Document, type: OpenSearchType): void {
  const existing = document.head.querySelector<HTMLLinkElement>('link[data-nuschtos-opensearch]');
  const link = existing ?? document.head.appendChild(document.createElement('link'));

  link.rel = 'search';
  link.type = 'application/opensearchdescription+xml';
  link.dataset['nuschtosOpensearch'] = 'true';
  link.title = `${CONFIG.title} ${type === 'options' ? 'Options' : 'Packages'} Search`;
  link.href = `${CONFIG.baseHref}opensearch-${type}.xml`;
}

export function clearOpenSearchLink(document: Document): void {
  document.head.querySelector<HTMLLinkElement>('link[data-nuschtos-opensearch]')?.remove();
}
