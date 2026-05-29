export const SITE = {
  name: 'Tickle',
  url: 'https://tickle.maskedsyntax.com',
  title: 'Tickle — Count what matters. Build better habits.',
  description:
    'Tickle is a minimal habit counter for iOS. Track daily goals, build consistency, and watch your progress grow — fast, calm, and offline-first.',
  tagline: 'Count what matters. Build better habits.',
  locale: 'en_US',
  twitterHandle: '@maskedsyntax',
  appStoreUrl: 'https://apps.apple.com/us/app/tickle-count-anything/id6772946890',
  kofiUrl: 'https://ko-fi.com/aftaabsiddiqui',
  ogImage: '/og-image.jpg',
  themeColor: '#7b5ea7',
} as const;

export function absoluteUrl(path: string): string {
  return new URL(path, SITE.url).href;
}

export function pageCanonical(pathname: string): string {
  if (pathname === '/' || pathname === '/index.html') {
    return SITE.url + '/';
  }

  return absoluteUrl(pathname);
}
