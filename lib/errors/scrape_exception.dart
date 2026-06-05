class ScrapeException implements Exception {
  const ScrapeException(this.message, {this.source, this.cause});

  final String message;
  final String? source;
  final Object? cause;

  @override
  String toString() {
    final prefix = source == null
        ? 'ScrapeException'
        : 'ScrapeException[$source]';
    return '$prefix: $message';
  }
}

class CaptchaRequiredException extends ScrapeException {
  const CaptchaRequiredException(super.message, {super.source, super.cause});
}

class ScrapeTimeoutException extends ScrapeException {
  const ScrapeTimeoutException(super.message, {super.source, super.cause});
}
