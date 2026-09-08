package io.github.rustnomicon.sourceinstaller.scrape

/**
 * JavaScript payloads injected into WebViews by the scrapers.
 * Ported from the Dart sources; JS template literals were rewritten as
 * string concatenation to avoid clashing with Kotlin string interpolation.
 */
object ScraperScripts {

    val BUNKR_ALBUM_CANDIDATES = """
        (() => {
          const entries = [];
          const seen = new Set();
          const normalize = (value) => String(value || '')
            .replace(/\\u002F/g, '/')
            .replace(/\\\//g, '/')
            .trim();
          const extensionOf = (...values) => {
            for (const value of values) {
              const text = normalize(value).toLowerCase();
              const type = text.match(/video\/(mp4|webm)/);
              if (type) return type[1];
              const ext = text.match(/\.([a-z0-9]+)(?:[?#]|$)/);
              if (ext && ['mp4', 'webm', 'jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext[1])) {
                return ext[1];
              }
              if (text === 'video') return 'mp4';
              if (text === 'image') return 'jpg';
            }
            return null;
          };
          const add = (value, meta = {}) => {
            if (!value) return;
            try {
              const url = new URL(normalize(value), location.href);
              if (!/\/(f|i|v|d)\/[A-Za-z0-9_-]+/.test(url.pathname)) return;
              if (seen.has(url.href)) return;
              seen.add(url.href);
              entries.push({
                url: url.href,
                extension: meta.extension || null,
                name: meta.name || null,
                size: meta.size !== undefined && meta.size !== null ? meta.size : null,
                directUrl: meta.directUrl || null,
              });
            } catch (_) {}
          };

          const directUrlFor = (file) => {
            const endpoint = normalize(file.cdnEndpoint || file.url || '');
            if (!/\.(mp4|webm)(?:[?#]|$)/i.test(endpoint)) return null;
            if (/^https?:\/\//i.test(endpoint)) return endpoint;
            try {
              const thumbnail = new URL(file.thumbnail || location.href);
              const host = thumbnail.host.replace(/^i-/, '');
              return thumbnail.protocol + '//' + host + (endpoint.startsWith('/') ? endpoint : '/' + endpoint);
            } catch (_) {
              return null;
            }
          };

          if (Array.isArray(window.albumFiles)) {
            for (const file of window.albumFiles) {
              const extension = extensionOf(
                file.type,
                file.extension,
                file.original,
                file.name,
                file.cdnEndpoint,
                file.url
              );
              const name = normalize(file.original || file.name || file.cdnEndpoint);
              add('/f/' + file.slug, {
                extension,
                name,
                size: file.size || file.filesize || file.fileSize || file.sizeBytes || file.size_bytes,
                directUrl: directUrlFor(file),
              });
            }
          }

          for (const anchor of document.querySelectorAll('a[href]')) {
            add(anchor.getAttribute('href'));
            add(anchor.href);
          }

          const html = document.documentElement.innerHTML;
          const albumFilesMatch = html.match(/window\.albumFiles\s*=\s*(\[[\s\S]*?\]);/);
          if (albumFilesMatch) {
            for (const match of albumFilesMatch[1].matchAll(/slug:\s*["']([^"']+)["']/g)) {
              add('/f/' + match[1]);
            }
          }

          return JSON.stringify(entries);
        })();
    """.trimIndent()

    val BUNKR_FILE_MEDIA = """
        (async () => {
          const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
          const normalize = (value) => String(value || '')
            .replace(/\\u002F/g, '/')
            .replace(/\\\//g, '/')
            .trim();

          const collect = () => {
            const urls = new Set();
            const add = (value) => {
              const text = normalize(value);
              if (!text) return;
              try {
                const url = new URL(text, location.href).href;
                if (/\.(mp4|webm)(\?|$)/i.test(url)) urls.add(url);
              } catch (_) {}
            };
            const addFromSignUrl = (value, cdnValue) => {
              const text = normalize(value);
              if (!text || !/glb-apisign\.cdn\.cr\/sign/i.test(text)) return;
              try {
                const signUrl = new URL(text, location.href);
                const path = signUrl.searchParams.get('path');
                if (!path || !/\.(mp4|webm)${'$'}/i.test(path)) return;
                if (cdnValue) {
                  const cdnUrl = new URL(cdnValue, location.href);
                  add(cdnUrl.origin + path);
                  return;
                }
                const cover = normalize(window.videoCoverUrl || '');
                if (cover) {
                  const coverUrl = new URL(cover, location.href);
                  const host = coverUrl.host.replace(/^i-/, '');
                  add(coverUrl.protocol + '//' + host + path);
                  return;
                }
                add(signUrl.href);
              } catch (_) {}
            };

            for (const element of document.querySelectorAll('video, source')) {
              add(element.currentSrc);
              add(element.src);
              add(element.getAttribute('src'));
            }

            for (const anchor of document.querySelectorAll('a[href]')) {
              add(anchor.href);
              add(anchor.getAttribute('href'));
            }

            const html = document.documentElement.innerHTML;
            for (const match of html.matchAll(/https?:\/\/[^"'<>\s]+\.(mp4|webm)[^"'<>\s]*/gi)) {
              add(match[0]);
            }

            const cdn = html.match(/var\s+jsCDN\s*=\s*["']([^"']+)["']/);
            const slug = html.match(/var\s+jsSlug\s*=\s*["']([^"']+)["']/);
            const cdnValue = normalize(window.jsCDN || (cdn && cdn[1]) || '');
            if (cdnValue) {
              if (/\.(mp4|webm)(\?|$)/i.test(cdnValue)) {
                add(cdnValue);
              } else if (slug) {
                add(cdnValue.replace(/\/${'$'}/, '') + '/storage/media/' + normalize(slug[1]));
              }
            }

            const signUrl = normalize(window.signUrl || '');
            if (signUrl && cdnValue) {
              try {
                const path = new URL(cdnValue, location.href).pathname;
                addFromSignUrl(signUrl + '?path=' + encodeURIComponent(path), cdnValue);
              } catch (_) {}
            }
            for (const entry of performance.getEntriesByType('resource')) {
              add(entry.name);
              addFromSignUrl(entry.name, cdnValue);
            }
            for (const match of html.matchAll(/https?:\/\/glb-apisign\.cdn\.cr\/sign\?path=[^"'<>\s]+/gi)) {
              addFromSignUrl(match[0], cdnValue);
            }

            return Array.from(urls);
          };

          for (let attempt = 0; attempt < 40; attempt++) {
            const urls = collect();
            if (urls.length > 0) return urls;
            await sleep(500);
          }

          return collect();
        })();
    """.trimIndent()

    val REDGIFS_MEDIA = """
        (() => {
          const normalize = (value) => String(value || '')
            .replace(/\\u002F/g, '/')
            .replace(/\\\//g, '/')
            .trim();
          const mediaPattern = /\.(mp4|webm)([?#]|$)/i;

          const collect = () => {
            const urls = new Set();
            const add = (value) => {
              const text = normalize(value);
              if (!text || text.startsWith('blob:')) return;
              try {
                const absoluteUrl = new URL(text, location.href).href;
                if (mediaPattern.test(absoluteUrl)) urls.add(absoluteUrl);
              } catch (_) {}
            };

            for (const element of document.querySelectorAll('video, source')) {
              for (const attr of [
                'currentSrc',
                'src',
                'data-src',
                'data-video-src',
                'data-hd',
                'data-sd',
              ]) {
                add(element[attr]);
                add(element.getAttribute(attr));
              }

              if (element.tagName.toLowerCase() === 'video') {
                try {
                  element.muted = true;
                  element.preload = 'auto';
                  element.setAttribute('playsinline', '');
                  if (element.load) element.load();
                  const promise = element.play ? element.play() : null;
                  if (promise && typeof promise.catch === 'function') {
                    promise.catch(() => {});
                  }
                } catch (_) {}
              }
            }

            for (const element of document.querySelectorAll('[src], [href]')) {
              add(element.getAttribute('src'));
              add(element.getAttribute('href'));
              add(element.src);
              add(element.href);
            }

            for (const entry of performance.getEntriesByType('resource')) {
              add(entry.name);
            }

            const html = document.documentElement.innerHTML;
            for (const match of html.matchAll(/https?:\/\/[^"'<>\s]+\.(mp4|webm)[^"'<>\s]*/gi)) {
              add(match[0]);
            }

            return Array.from(urls);
          };

          try { window.scrollBy(0, Math.max(1, window.innerHeight / 2)); } catch (_) {}
          return collect();
        })();
    """.trimIndent()

    /** Card link collector used by the headless Bunkr album flow. */
    val BUNKR_ALBUM_LINKS = """
        (async () => {
          const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
          const collect = () => {
            const urls = new Set();
            const add = (value) => {
              if (!value) return;
              try {
                const url = new URL(value, location.href);
                if (/\/(f|i|v|d)\/[A-Za-z0-9_-]+/.test(url.pathname)) {
                  urls.add(url.href);
                }
              } catch (_) {}
            };

            for (const anchor of document.querySelectorAll('a[href]')) {
              add(anchor.getAttribute('href'));
              add(anchor.href);
            }

            const html = document.documentElement.innerHTML;
            const albumFilesMatch = html.match(/window\.albumFiles\s*=\s*(\[[\s\S]*?\]);/);
            if (albumFilesMatch) {
              for (const match of albumFilesMatch[1].matchAll(/slug:\s*["']([^"']+)["']/g)) {
                add('/f/' + match[1]);
              }
            }

            return Array.from(urls);
          };

          for (let attempt = 0; attempt < 40; attempt++) {
            const urls = collect();
            if (urls.length > 0) return urls;
            await sleep(500);
          }

          return collect();
        })();
    """.trimIndent()

    /** Direct media collector used by the headless Bunkr file flow. */
    val BUNKR_HEADLESS_FILE_MEDIA = """
        (async () => {
          const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
          const normalize = (value) => String(value || '')
            .replace(/\\u002F/g, '/')
            .replace(/\\\//g, '/')
            .trim();

          const collect = () => {
            const urls = new Set();
            const add = (value) => {
              const text = normalize(value);
              if (!text) return;
              try {
                const url = new URL(text, location.href).href;
                if (/\.(mp4|webm)(\?|$)/i.test(url)) urls.add(url);
              } catch (_) {}
            };

            for (const element of document.querySelectorAll('video, source')) {
              add(element.currentSrc);
              add(element.src);
              add(element.getAttribute('src'));
            }

            for (const anchor of document.querySelectorAll('a[href]')) {
              add(anchor.href);
              add(anchor.getAttribute('href'));
            }

            const html = document.documentElement.innerHTML;
            for (const match of html.matchAll(/https?:\/\/[^"'<>\s]+\.(mp4|webm)[^"'<>\s]*/gi)) {
              add(match[0]);
            }

            const cdn = html.match(/var\s+jsCDN\s*=\s*["']([^"']+)["']/);
            const slug = html.match(/var\s+jsSlug\s*=\s*["']([^"']+)["']/);
            if (cdn) {
              const cdnValue = normalize(cdn[1]);
              if (/\.(mp4|webm)(\?|$)/i.test(cdnValue)) {
                add(cdnValue);
              } else if (slug) {
                add(cdnValue.replace(/\/${'$'}/, '') + '/storage/media/' + normalize(slug[1]));
              }
            }

            return Array.from(urls);
          };

          for (let attempt = 0; attempt < 40; attempt++) {
            const urls = collect();
            if (urls.length > 0) return urls;
            await sleep(500);
          }

          return collect();
        })();
    """.trimIndent()

    val REDDIT_WEBVIEW_COLLECTOR = """
        (() => {
          const urls = new Set();
          const normalize = (value) => String(value || '')
            .replace(/&amp;/g, '&')
            .replace(/\\u0026/g, '&')
            .replace(/\\u003[dD]/g, '=')
            .replace(/\\u002F/g, '/')
            .replace(/\\\//g, '/')
            .trim();
          const add = (value) => {
            const text = normalize(value);
            if (!text) return;
            try {
              const url = new URL(text, location.href).href;
              if (/https?:\/\/(i|preview|v|packaged-media)\.redd\.it\//i.test(url)) {
                urls.add(url);
              }
            } catch (_) {}
          };
          const scanRoot = (root) => {
            if (!root || !root.querySelectorAll) return;
            for (const el of root.querySelectorAll('video, source, img, a, shreddit-post, shreddit-player-2')) {
              for (const attr of ['src', 'href', 'currentSrc', 'poster', 'content', 'data-src']) {
                add(el[attr]);
                add(el.getAttribute ? el.getAttribute(attr) : null);
              }
              if (el.shadowRoot) scanRoot(el.shadowRoot);
            }
          };
          scanRoot(document);
          for (const entry of performance.getEntriesByType('resource')) add(entry.name);
          const html = document.documentElement ? document.documentElement.innerHTML : '';
          for (const match of html.matchAll(/https?:\/\/(?:i|preview|v|packaged-media)\.redd\.it\/[^"'<>\\\s)]+/gi)) add(match[0]);
          for (const match of html.matchAll(/https%3A%2F%2F(?:i|preview|v|packaged-media)\.redd\.it%2F[^"'<>\\\s)]+/gi)) {
            try { add(decodeURIComponent(match[0])); } catch (_) {}
          }
          return JSON.stringify(Array.from(urls));
        })();
    """.trimIndent()

    val REDDIT_HTML_READER =
        """(function() { var el = document.documentElement; return el ? el.innerHTML : ''; })();"""

    /** Challenge/media readiness probe used while waiting for the Bunkr player. */
    val BUNKR_PLAYER_READY_PROBE = """
        (() => {
          const html = document.documentElement ? document.documentElement.innerHTML : '';
          const resources = performance.getEntriesByType('resource')
            .map((entry) => String(entry.name || ''));
          const hasMediaUrl = Boolean(
            document.querySelector('video[src], source[src]') ||
            /glb-apisign\.cdn\.cr\/sign\?path=/i.test(html) ||
            /\.(mp4|webm)(\?|["'\s<]|$)/i.test(html) ||
            resources.some((url) =>
              /glb-apisign\.cdn\.cr\/sign\?path=/i.test(url) ||
              /\.(mp4|webm)(\?|$)/i.test(url)
            )
          );
          const hasHints = Boolean(
            window.jsCDN ||
            window.videoCoverUrl ||
            /var\s+jsCDN\s*=/.test(html) ||
            /https?:\/\/i-[^"'<\s]+\/thumbs\//i.test(html)
          );

          return JSON.stringify({
            ready: document.readyState === 'complete' || document.readyState === 'interactive',
            hasMediaUrl,
            hasHints,
          });
        })();
    """.trimIndent()

    val BUNKR_PAGE_HINTS = """
        (() => {
          const normalize = (value) => String(value || '')
            .replace(/\\u002F/g, '/')
            .replace(/\\\//g, '/')
            .trim();
          const html = document.documentElement ? document.documentElement.innerHTML : '';
          const cdnMatch = html.match(/var\s+jsCDN\s*=\s*["']([^"']+)["']/);
          const coverMatch = html.match(/https?:\/\/i-[^"'<\s]+\/thumbs\/[^"'<\s]+/i);
          const poster = document.querySelector('video[poster], img[src*="/thumbs/"]');
          return JSON.stringify({
            cdn: normalize(window.jsCDN || (cdnMatch && cdnMatch[1]) || ''),
            cover: normalize(window.videoCoverUrl || (poster ? (poster.poster || poster.src) : '') || (coverMatch && coverMatch[0]) || ''),
          });
        })();
    """.trimIndent()

    val BUNKR_FILE_SIZE_TEXT = """
        (() => {
          const text = document.body ? (document.body.innerText || '') : '';
          const html = document.documentElement ? document.documentElement.innerHTML : '';
          const source = text + '\n' + html;
          const patterns = [
            /(?:size|file size|filesize)\s*[:\-]?\s*([0-9]+(?:[\.,][0-9]+)?\s*(?:b|kb|mb|gb|tb|kib|mib|gib|tib))/i,
            /([0-9]+(?:[\.,][0-9]+)?\s*(?:kb|mb|gb|tb|kib|mib|gib|tib))/i
          ];
          for (const pattern of patterns) {
            const match = source.match(pattern);
            if (match) return match[1];
          }
          return '';
        })();
    """.trimIndent()

    val CAPTCHA_MARKER_PROBE =
        """(() => /captcha|cf-challenge|turnstile/i.test((document.body ? (document.body.innerText || '') : '') || document.documentElement.innerHTML))();"""

    /** Page state probe used to detect a passed challenge in the visible WebView. */
    val CHALLENGE_STATE_PROBE = """
        (() => {
          const html = document.documentElement ? (document.documentElement.innerHTML || '') : '';
          const text = document.body ? (document.body.innerText || '') : '';
          const combined = (document.title || '') + '\n' + text + '\n' + html;
          const challenge = /captcha|cf-challenge|cf-browser-verification|cf-turnstile|turnstile|checking your browser|verify you are human|just a moment|challenge-platform/i.test(combined);
          const networkError = /error code:\s*(520|521|522|523|524)|connection timed out|web server is down|origin is unreachable|host error|bad gateway|gateway timeout/i.test(combined);
          const hasMediaHints = Boolean(
            document.querySelector('video, source, img[src*="redd.it"], a[href*="redd.it"], a[href*="/f/"], a[href*="/i/"], a[href*="/v/"], a[href*="/d/"]') ||
            /\.(mp4|webm|mov|m4v|jpg|jpeg|png|gif|webp)(\?|["'\s<]|$)/i.test(html) ||
            /(?:i|preview|v|packaged-media)\.redd\.it/i.test(html)
          );

          return JSON.stringify({
            ready: document.readyState === 'complete' || document.readyState === 'interactive',
            hasBody: text.trim().length > 20 || html.length > 1000,
            hasMediaHints,
            challenge,
            networkError,
          });
        })();
    """.trimIndent()
}
