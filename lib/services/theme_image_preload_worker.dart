import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

typedef ThemeImageDataCallback = FutureOr<void> Function(String key, Uint8List bytes);
typedef ThemeImageErrorCallback = void Function(String key, Object error);

class ThemeImagePreloadWorker {
  ThemeImagePreloadWorker({int? concurrency}) : concurrency = concurrency ?? _defaultConcurrency;

  final int concurrency;

  static int get _defaultConcurrency {
    final cpuCount = Platform.numberOfProcessors;
    if (cpuCount <= 2) return 2;
    return math.min(cpuCount, 6);
  }

  Future<void> download(
    List<MapEntry<String, String>> entries, {
    required ThemeImageDataCallback onImage,
    ThemeImageErrorCallback? onError,
  }) async {
    if (entries.isEmpty) return;
    final chunkCount = math.max(1, math.min(concurrency, entries.length));
    final chunks = _chunkEntries(entries, chunkCount);

    final receivePort = ReceivePort();
    final isolates = <Isolate>[];
    for (final chunk in chunks) {
      final isolate = await Isolate.spawn(
        _themeImagePreloadEntry,
        [receivePort.sendPort, chunk],
        errorsAreFatal: false,
      );
      isolates.add(isolate);
    }

    final pendingDecodes = <Future<void>>[];
    final completer = Completer<void>();
    var finished = 0;
    late final StreamSubscription<dynamic> subscription;
    subscription = receivePort.listen((message) {
      if (message is! Map) return;
      final type = message['type'];
      switch (type) {
        case 'data':
          final key = message['key'] as String;
          final bytesData = message['bytes'] as TransferableTypedData;
          final data = bytesData.materialize().asUint8List();
          try {
            final result = onImage(key, data);
            if (result is Future<void>) {
              pendingDecodes.add(result);
            }
          } catch (err) {
            onError?.call(key, err);
          }
          break;
        case 'error':
          final key = message['key'] as String;
          final errorMessage = message['message'] ?? 'unknown error';
          onError?.call(key, errorMessage);
          break;
        case 'done':
          finished++;
          if (finished >= isolates.length && !completer.isCompleted) {
            completer.complete();
          }
          break;
      }
    });

    await completer.future;
    await subscription.cancel();
    receivePort.close();
    if (pendingDecodes.isNotEmpty) {
      await Future.wait(pendingDecodes);
    }
    for (final isolate in isolates) {
      isolate.kill(priority: Isolate.immediate);
    }
  }
}

List<List<Map<String, String>>> _chunkEntries(List<MapEntry<String, String>> entries, int chunkCount) {
  final chunkSize = (entries.length / chunkCount).ceil();
  final chunks = <List<Map<String, String>>>[];
  for (var i = 0; i < entries.length; i += chunkSize) {
    final slice = entries.sublist(i, math.min(i + chunkSize, entries.length));
    chunks.add(
      slice
          .map(
            (entry) => {'key': entry.key, 'url': entry.value},
          )
          .toList(growable: false),
    );
  }
  return chunks;
}

Future<void> _themeImagePreloadEntry(List<dynamic> payload) async {
  final sendPort = payload[0] as SendPort;
  final rawChunk = (payload[1] as List).cast<Map<String, String>>();
  final client = HttpClient();
  for (final rawEntry in rawChunk) {
    final key = rawEntry['key']!;
    final url = rawEntry['url']!;
    try {
      final bytes = await _downloadBytes(client, Uri.parse(url));
      sendPort.send(
        {
          'type': 'data',
          'key': key,
          'bytes': TransferableTypedData.fromList([bytes]),
        },
      );
    } catch (error) {
      sendPort.send(
        {
          'type': 'error',
          'key': key,
          'message': error.toString(),
        },
      );
    }
  }
  client.close(force: true);
  sendPort.send({'type': 'done'});
}

Future<Uint8List> _downloadBytes(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri);
  final response = await request.close();
  if (response.statusCode != HttpStatus.ok) {
    await response.drain();
    throw HttpException('HTTP ${response.statusCode}', uri: uri);
  }
  final builder = BytesBuilder(copy: false);
  await for (final chunk in response) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}
