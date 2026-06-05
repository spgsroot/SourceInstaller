import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/scrape_exception.dart';
import '../l10n/app_localizations.dart';
import '../models/download_task.dart';
import '../models/filter_settings.dart';
import '../models/media_item.dart';
import '../providers/app_providers.dart';

const _desktopUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/120.0.0.0 Safari/537.36';

const _bunkrPreviewExtensions = {
  'mp4',
  'webm',
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
};

class InputScreen extends ConsumerStatefulWidget {
  const InputScreen({super.key});

  @override
  ConsumerState<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends ConsumerState<InputScreen> {
  final _urlController = TextEditingController();
  String _lastAnalysisUrl = '';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = ref.watch(filterSettingsProvider);
    final analysis = ref.watch(analysisControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _urlController,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: l10n.urlFieldLabel,
            hintText: l10n.urlFieldHint,
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _startAnalysis(),
        ),
        const SizedBox(height: 12),
        _FilterPanel(filters: filters),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: analysis.isLoading ? null : _startAnalysis,
          icon: analysis.isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.search),
          label: Text(l10n.startAnalysisButton),
        ),
        const SizedBox(height: 16),
        switch (analysis) {
          AsyncData(:final value) => _ResultsList(items: value),
          AsyncError(:final error) => _ErrorCard(
            error: error,
            analysisUrl: _lastAnalysisUrl,
          ),
          _ => const LinearProgressIndicator(),
        },
      ],
    );
  }

  void _startAnalysis() {
    final url = _urlController.text.trim();
    _lastAnalysisUrl = url;
    ref.read(analysisControllerProvider.notifier).analyze(url);
  }
}

class _FilterPanel extends ConsumerWidget {
  const _FilterPanel({required this.filters});

  final FilterSettings filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              value: filters.onlyVideo,
              title: Text(l10n.onlyVideoFilter),
              dense: true,
              onChanged: (value) {
                ref
                    .read(filterSettingsProvider.notifier)
                    .setOnlyVideo(value ?? true);
              },
            ),
            CheckboxListTile(
              value: filters.ignoreSmallFiles,
              title: Text(l10n.ignoreSmallFilesFilter),
              dense: true,
              onChanged: (value) {
                ref
                    .read(filterSettingsProvider.notifier)
                    .setIgnoreSmallFiles(value ?? false);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<int>(
                initialValue: filters.downloadLimit ?? 0,
                decoration: InputDecoration(
                  labelText: l10n.downloadLimitLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [0, 5, 10, 25, 50, 100]
                    .map(
                      (limit) => DropdownMenuItem<int>(
                        value: limit,
                        child: Text(
                          limit == 0
                              ? l10n.downloadLimitUnlimited
                              : l10n.downloadLimitFiles(limit),
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  ref
                      .read(filterSettingsProvider.notifier)
                      .setDownloadLimit(value == 0 ? null : value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultsList extends ConsumerWidget {
  const _ResultsList({required this.items});

  final List<MediaItem> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final queuedTasks = ref.watch(downloadQueueProvider);

    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.noMediaFound),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.foundFiles(items.length),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: () =>
                  ref.read(downloadQueueProvider.notifier).enqueueAll(items),
              icon: const Icon(Icons.download_for_offline),
              label: Text(_downloadAllLabel(l10n, ref, items.length)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final item in items)
          _ResultItemCard(item: item, tasks: queuedTasks),
      ],
    );
  }

  String _downloadAllLabel(
    AppLocalizations l10n,
    WidgetRef ref,
    int totalCount,
  ) {
    final limit = ref.watch(filterSettingsProvider).downloadLimit;
    if (limit == null || limit >= totalCount) return l10n.downloadAllButton;
    return l10n.downloadLimitedButton(limit);
  }
}

void _showPreview(BuildContext context, MediaItem item) {
  final l10n = AppLocalizations.of(context);

  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(l10n.previewTitle),
        content: SizedBox(
          width: 720,
          height: 420,
          child: _MediaPreview(item: item),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(l10n.closeButton),
          ),
        ],
      );
    },
  );
}

class _ResultItemCard extends ConsumerWidget {
  const _ResultItemCard({required this.item, required this.tasks});

  final MediaItem item;
  final List<DownloadTask> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final existingTask = _taskForItem(tasks, item);
    final disabled =
        existingTask != null &&
        existingTask.state != DownloadState.failed &&
        existingTask.state != DownloadState.canceled;

    return Card(
      child: ListTile(
        leading: _MediaPreviewLeading(item: item),
        title: Text(
          item.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _mediaItemSubtitle(item),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: l10n.previewTooltip,
              icon: const Icon(Icons.visibility),
              onPressed: () => _showPreview(context, item),
            ),
            IconButton(
              tooltip: _downloadTooltip(l10n, existingTask),
              icon: Icon(_downloadIcon(existingTask)),
              onPressed: disabled
                  ? null
                  : () =>
                        ref.read(downloadQueueProvider.notifier).enqueue(item),
            ),
          ],
        ),
      ),
    );
  }

  DownloadTask? _taskForItem(List<DownloadTask> tasks, MediaItem item) {
    for (final task in tasks.reversed) {
      if (task.mediaItem.url == item.url ||
          task.mediaItem.fileName == item.fileName) {
        return task;
      }
    }
    return null;
  }

  IconData _downloadIcon(DownloadTask? task) {
    return switch (task?.state) {
      DownloadState.completed => Icons.check_circle,
      DownloadState.running => Icons.downloading,
      DownloadState.queued => Icons.hourglass_empty,
      DownloadState.paused => Icons.pause_circle,
      _ => Icons.download,
    };
  }

  String _downloadTooltip(AppLocalizations l10n, DownloadTask? task) {
    return switch (task?.state) {
      DownloadState.completed => l10n.alreadyDownloadedTooltip,
      DownloadState.running ||
      DownloadState.queued ||
      DownloadState.paused => l10n.downloadInProgressTooltip,
      _ => l10n.downloadTooltip,
    };
  }
}

String _mediaItemSubtitle(MediaItem item) {
  final size = _formatBytes(item.sizeBytes);
  if (size == null) return item.url;
  return '$size • ${item.url}';
}

String? _formatBytes(int? bytes) {
  if (bytes == null || bytes < 0) return null;
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }

  final decimals = value >= 10 || unitIndex == 0 ? 0 : 1;
  return '${value.toStringAsFixed(decimals)} ${units[unitIndex]}';
}

class _MediaPreviewLeading extends StatelessWidget {
  const _MediaPreviewLeading({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    if (_isImage(item.extension)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          item.url,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
        ),
      );
    }

    return const SizedBox(width: 56, height: 56, child: Icon(Icons.movie));
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    if (_isBunkrItem(item)) {
      return _BunkrMediaPreview(item: item);
    }

    if (_isImage(item.extension)) {
      return InteractiveViewer(
        child: Center(
          child: Image.network(
            item.url,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Text(item.url),
          ),
        ),
      );
    }

    return _VideoPreviewWebView(url: item.url, baseUrl: item.sourceUrl);
  }
}

class _BunkrMediaPreview extends StatefulWidget {
  const _BunkrMediaPreview({required this.item});

  final MediaItem item;

  @override
  State<_BunkrMediaPreview> createState() => _BunkrMediaPreviewState();
}

class _BunkrMediaPreviewState extends State<_BunkrMediaPreview> {
  late final Future<String> _previewUrl = _freshBunkrPreviewUrl(widget.item);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _previewUrl,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Preview failed: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final previewUrl = snapshot.data!;
        if (_isImage(widget.item.extension)) {
          return InteractiveViewer(
            child: Center(
              child: Image.network(
                previewUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Text(previewUrl),
              ),
            ),
          );
        }

        return _VideoPreviewWebView(
          url: previewUrl,
          baseUrl: _previewBaseUrlFor(widget.item),
        );
      },
    );
  }
}

class _VideoPreviewWebView extends StatelessWidget {
  const _VideoPreviewWebView({required this.url, this.baseUrl});

  final String url;
  final String? baseUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: InAppWebView(
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
          userAgent: _desktopUserAgent,
        ),
        initialData: InAppWebViewInitialData(
          data: _videoPreviewHtml(url),
          baseUrl: _webUriOrNull(baseUrl),
          historyUrl: _webUriOrNull(baseUrl),
        ),
      ),
    );
  }
}

bool _isImage(String extension) {
  return {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  }.contains(extension.toLowerCase());
}

bool _isBunkrItem(MediaItem item) {
  return _isBunkrRelatedUrl(item.url) || _isBunkrRelatedUrl(item.sourceUrl);
}

bool _isBunkrRelatedUrl(String value) {
  final host = Uri.tryParse(value)?.host.toLowerCase() ?? '';
  return host.contains('bunkr') ||
      host.endsWith('.cdn.cr') ||
      host.contains('gigachad-cdn') ||
      host == 'bnkr.b-cdn.net';
}

String? _previewBaseUrlFor(MediaItem item) {
  final sourceUri = Uri.tryParse(item.sourceUrl);
  if (sourceUri != null && sourceUri.hasScheme && sourceUri.host.isNotEmpty) {
    return sourceUri.toString();
  }

  final itemUri = Uri.tryParse(item.url);
  if (itemUri != null && itemUri.hasScheme && itemUri.host.isNotEmpty) {
    return '${itemUri.scheme}://${itemUri.host}/';
  }

  return null;
}

WebUri? _webUriOrNull(String? value) {
  if (value == null || value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
  return WebUri(uri.toString());
}

Future<String> _freshBunkrPreviewUrl(MediaItem item) async {
  final normalized = _normalizeEscapedUrl(item.url);
  final uri = Uri.tryParse(normalized);
  final extension = item.extension.toLowerCase();
  if (uri == null ||
      !_isBunkrRelatedUrl(normalized) ||
      !_bunkrPreviewExtensions.contains(extension)) {
    return normalized;
  }

  final sourcePageUrl = await _freshBunkrPreviewUrlFromSourcePage(item);
  if (sourcePageUrl != null) return sourcePageUrl;

  return _signBunkrPreviewUrl(normalized);
}

Future<String?> _freshBunkrPreviewUrlFromSourcePage(MediaItem item) async {
  final sourceUri = Uri.tryParse(item.sourceUrl);
  if (sourceUri == null || !_isBunkrFilePageUrl(sourceUri)) return null;

  try {
    final response =
        await Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ).get<String>(
          item.sourceUrl,
          options: Options(
            responseType: ResponseType.plain,
            headers: _bunkrPageHeadersFor(item.sourceUrl),
            validateStatus: (status) =>
                status != null && status >= 200 && status < 400,
          ),
        );

    final jsCdn = _extractBunkrJsCdn(response.data ?? '');
    if (jsCdn == null) return null;

    final signedJsCdn = await _signBunkrPreviewUrl(jsCdn);
    if (_hasBunkrSignature(jsCdn) || _hasBunkrSignature(signedJsCdn)) {
      return signedJsCdn;
    }

    return null;
  } catch (_) {
    return null;
  }
}

Future<String> _signBunkrPreviewUrl(String rawUrl) async {
  final normalized = _normalizeEscapedUrl(rawUrl);
  final uri = Uri.tryParse(normalized);
  if (uri == null || !_isBunkrRelatedUrl(normalized)) return normalized;

  try {
    final response =
        await Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {'user-agent': _desktopUserAgent},
          ),
        ).getUri<Map<String, dynamic>>(
          Uri.https('glb-apisign.cdn.cr', '/sign', {'path': uri.path}),
        );

    final token = response.data?['token']?.toString();
    final ex = response.data?['ex']?.toString();
    if (token == null || token.isEmpty || ex == null || ex.isEmpty) {
      return normalized;
    }

    final nextQuery = Map<String, String>.from(uri.queryParameters);
    nextQuery['token'] = token;
    nextQuery['ex'] = ex;
    return uri.replace(queryParameters: nextQuery).toString();
  } catch (_) {
    return normalized;
  }
}

bool _isBunkrFilePageUrl(Uri uri) {
  final host = uri.host.toLowerCase();
  if (!host.contains('bunkr')) return false;
  final segments = uri.pathSegments;
  if (segments.isEmpty) return false;
  return {'f', 'v', 'i', 'd'}.contains(segments.first.toLowerCase());
}

Map<String, String> _bunkrPageHeadersFor(String sourceUrl) {
  final sourceUri = Uri.tryParse(sourceUrl);
  final origin = sourceUri != null && sourceUri.hasScheme
      ? '${sourceUri.scheme}://${sourceUri.host}'
      : 'https://bunkr.cr';

  return {
    'user-agent': _desktopUserAgent,
    'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'referer': origin,
    'origin': origin,
  };
}

String? _extractBunkrJsCdn(String html) {
  final match = RegExp(
    r'''var\s+jsCDN\s*=\s*(["'])(.*?)\1''',
    dotAll: true,
  ).firstMatch(html);
  final raw = match?.group(2);
  if (raw == null || raw.isEmpty) return null;

  final normalized = _normalizeEscapedUrl(raw).replaceAll('&amp;', '&');
  final uri = Uri.tryParse(normalized);
  if (uri == null || !_isBunkrRelatedUrl(normalized)) return null;

  final extension = _previewExtensionFromUrl(uri);
  if (extension == null || !_bunkrPreviewExtensions.contains(extension)) {
    return null;
  }

  return normalized;
}

String? _previewExtensionFromUrl(Uri uri) {
  final match = RegExp(
    r'\.([a-z0-9]+)$',
    caseSensitive: false,
  ).firstMatch(uri.path);
  return match?.group(1)?.toLowerCase();
}

bool _hasBunkrSignature(String url) {
  final query = Uri.tryParse(url)?.queryParameters;
  final token = query?['token'];
  final ex = query?['ex'];
  return token != null && token.isNotEmpty && ex != null && ex.isNotEmpty;
}

String _normalizeEscapedUrl(String url) {
  return url.replaceAll(r'\u002F', '/').replaceAll(r'\/', '/').trim();
}

String _videoPreviewHtml(String url) {
  final safeUrl = const HtmlEscape().convert(url);
  return '''
<!doctype html>
<html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
      html, body { margin: 0; height: 100%; background: #000; }
      video { width: 100%; height: 100%; object-fit: contain; }
      #error { display: none; color: #fff; padding: 16px; font: 14px sans-serif; word-break: break-all; }
    </style>
  </head>
  <body>
    <video id="preview" controls playsinline preload="metadata" src="$safeUrl"></video>
    <div id="error">Preview failed: $safeUrl</div>
    <script>
      const video = document.getElementById('preview');
      const error = document.getElementById('error');
      video.addEventListener('error', () => {
        error.style.display = 'block';
      });
    </script>
  </body>
</html>
''';
}

class _ErrorCard extends ConsumerWidget {
  const _ErrorCard({required this.error, required this.analysisUrl});

  final Object error;
  final String analysisUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (error case final CaptchaRequiredException captcha
        when captcha.source != null) {
      final retryUrl = analysisUrl.isEmpty ? captcha.source! : analysisUrl;
      return _ChallengeWebViewCard(
        challengeUrl: _visibleChallengeUrlFor(retryUrl),
        analysisUrl: retryUrl,
      );
    }

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(error.toString()),
      ),
    );
  }
}

class _ChallengeWebViewCard extends ConsumerStatefulWidget {
  const _ChallengeWebViewCard({
    required this.challengeUrl,
    required this.analysisUrl,
  });

  final String challengeUrl;
  final String analysisUrl;

  @override
  ConsumerState<_ChallengeWebViewCard> createState() =>
      _ChallengeWebViewCardState();
}

class _ChallengeWebViewCardState extends ConsumerState<_ChallengeWebViewCard> {
  InAppWebViewController? _controller;
  final _capturedMediaUrls = <String>{};
  Timer? _checkTimer;
  bool _checking = false;
  bool _continuing = false;
  bool _disposed = false;
  int _progress = 0;

  @override
  void dispose() {
    _disposed = true;
    _checkTimer?.cancel();
    _controller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.captchaRequiredTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.captchaRequiredMessage),
            const SizedBox(height: 12),
            if (_progress > 0 && _progress < 100) ...[
              LinearProgressIndicator(value: _progress / 100),
              const SizedBox(height: 8),
            ],
            SizedBox(
              height: 420,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(widget.challengeUrl),
                  ),
                  initialSettings: InAppWebViewSettings(
                    isInspectable: kDebugMode,
                    javaScriptEnabled: true,
                    mediaPlaybackRequiresUserGesture: false,
                    userAgent: _desktopUserAgent,
                    useOnLoadResource: true,
                    useOnDownloadStart: true,
                    useShouldInterceptRequest: true,
                    useShouldInterceptAjaxRequest: true,
                    useShouldInterceptFetchRequest: true,
                  ),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                  },
                  onLoadResource: (controller, resource) {
                    _captureMediaUrl(resource.url?.toString());
                  },
                  onDownloadStarting: (controller, downloadStartRequest) async {
                    _captureMediaUrl(downloadStartRequest.url.toString());
                    return null;
                  },
                  shouldInterceptRequest: (controller, request) async {
                    _captureMediaUrl(request.url.toString());
                    return null;
                  },
                  shouldInterceptAjaxRequest: (controller, ajaxRequest) async {
                    _captureMediaUrl(ajaxRequest.url?.toString());
                    _captureMediaUrl(ajaxRequest.responseURL?.toString());
                    return ajaxRequest;
                  },
                  shouldInterceptFetchRequest:
                      (controller, fetchRequest) async {
                        _captureMediaUrl(fetchRequest.url?.toString());
                        return fetchRequest;
                      },
                  onLoadStop: (controller, url) {
                    _scheduleChallengeCheck();
                  },
                  onProgressChanged: (controller, progress) {
                    if (mounted) {
                      setState(() => _progress = progress);
                    }
                    if (progress >= 100) {
                      _scheduleChallengeCheck();
                    }
                  },
                  onUpdateVisitedHistory: (controller, url, isReload) {
                    _scheduleChallengeCheck();
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _continuing ? null : _continueAnalysis,
              icon: _continuing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(l10n.retryAnalysisButton),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleChallengeCheck([
    Duration delay = const Duration(milliseconds: 900),
  ]) {
    if (_disposed || _continuing) return;
    _checkTimer?.cancel();
    _checkTimer = Timer(delay, () {
      final controller = _controller;
      if (controller == null || _disposed || !mounted) return;
      unawaited(_checkChallengePassed(controller));
    });
  }

  Future<void> _checkChallengePassed(InAppWebViewController controller) async {
    if (_disposed || _checking || _continuing) return;
    _checking = true;

    try {
      final pageState = await _readPageState(controller);
      if (_disposed) return;
      final hasClearanceCookie = await _hasClearanceCookie(controller);
      if (_disposed) return;
      final ready = pageState['ready'] == true;
      final hasBody = pageState['hasBody'] == true;
      final hasMediaHints = pageState['hasMediaHints'] == true;
      final hasChallenge = pageState['challenge'] == true;
      final hasNetworkError = pageState['networkError'] == true;

      final hasCapturedMedia = _capturedMediaUrls.isNotEmpty;
      final pageLooksReady = ready && hasBody && hasMediaHints;

      if (!hasNetworkError &&
          (hasCapturedMedia ||
              (!hasChallenge && (hasClearanceCookie || pageLooksReady)))) {
        await _continueAnalysis();
      }
    } catch (_) {
      // Страница может временно запрещать JS во время challenge. Пользователь
      // всё равно может нажать кнопку повтора вручную после прохождения.
    } finally {
      _checking = false;
    }
  }

  Future<Map<String, Object?>> _readPageState(
    InAppWebViewController controller,
  ) async {
    final result = await controller.evaluateJavascript(
      source: r'''
        (() => {
          const html = document.documentElement?.innerHTML || '';
          const text = document.body?.innerText || '';
          const combined = `${document.title || ''}\n${text}\n${html}`;
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
      ''',
    );

    if (result is String) {
      final decoded = jsonDecode(result);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    if (result is Map) return result.cast<String, Object?>();
    return const <String, Object?>{};
  }

  Future<bool> _hasClearanceCookie(InAppWebViewController controller) async {
    final currentUrl = await controller.getUrl();
    final urls = <String>{
      widget.challengeUrl,
      widget.analysisUrl,
      if (currentUrl != null) currentUrl.toString(),
    };

    for (final url in urls) {
      final cookie = await CookieManager.instance().getCookie(
        url: WebUri(url),
        name: 'cf_clearance',
      );
      if (cookie != null && cookie.value.isNotEmpty) return true;
    }

    return false;
  }

  void _captureMediaUrl(String? value) {
    if (value == null) return;
    final normalized = value
        .replaceAll(r'\u002F', '/')
        .replaceAll(r'\/', '/')
        .trim();
    final isDirectMedia = RegExp(
      r'\.(mp4|webm)([?#]|$)',
      caseSensitive: false,
    ).hasMatch(normalized);
    final isBunkrSignUrl = RegExp(
      r'https?://glb-apisign\.cdn\.cr/sign\?[^\s]*path=[^\s]*\.(mp4|webm)(?:[&#]|$)',
      caseSensitive: false,
    ).hasMatch(normalized);

    if (isDirectMedia || isBunkrSignUrl) {
      _capturedMediaUrls.add(normalized);
      _scheduleChallengeCheck(const Duration(milliseconds: 200));
    }
  }

  Future<void> _continueAnalysis() async {
    if (_disposed || _continuing) return;
    final controller = _controller;
    if (controller == null) return;

    if (mounted) {
      setState(() => _continuing = true);
    } else {
      _continuing = true;
    }
    try {
      await ref
          .read(analysisControllerProvider.notifier)
          .analyzeWithWebView(
            widget.analysisUrl,
            controller,
            capturedMediaUrls: Set<String>.from(_capturedMediaUrls),
          );
    } finally {
      if (!_disposed && mounted) {
        setState(() => _continuing = false);
      } else {
        _continuing = false;
      }
    }
  }
}

String _visibleChallengeUrlFor(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return url;

  final host = uri.host.toLowerCase();
  final pathSegments = uri.pathSegments;
  if (host.contains('bunkr') &&
      pathSegments.isNotEmpty &&
      pathSegments.first.toLowerCase() == 'a') {
    final nextQuery = Map<String, String>.from(uri.queryParameters);
    nextQuery['advanced'] = '1';
    return uri.replace(queryParameters: nextQuery).toString();
  }

  return url;
}
