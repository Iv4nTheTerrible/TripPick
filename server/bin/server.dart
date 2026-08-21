import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:trip_pick_server/trip_pick_server.dart';

Future<void> main() async {
  final values = <String, String>{
    ...await _readDotEnv(File('.env')),
    ...Platform.environment,
  };
  final port = int.tryParse(values['PORT'] ?? '') ?? 8080;
  final allowedOrigin = values['ALLOWED_ORIGIN'] ?? 'http://localhost:3000';
  final useFakeApis =
      (values['USE_FAKE_APIS'] ?? 'false').toLowerCase() == 'true';

  final RecommendationEngine engine;
  if (useFakeApis) {
    engine = const FakeRecommendationEngine();
  } else {
    final geminiKey = values['GEMINI_API_KEY'] ?? '';
    if (geminiKey.isEmpty) {
      stderr.writeln('GEMINI_API_KEY is required when USE_FAKE_APIS is false.');
      exitCode = 64;
      return;
    }
    engine = LiveRecommendationEngine(
      generator: GeminiCandidateGenerator(
        apiKey: geminiKey,
        model: values['GEMINI_MODEL'] ?? 'gemini-3.5-flash-lite',
      ),
    );
  }

  final api = TripPickApi(engine: engine, allowedOrigin: allowedOrigin);
  final server = await shelf_io.serve(
    api.handler,
    InternetAddress.loopbackIPv4,
    port,
  );
  stdout.writeln(
    'TripPick server listening on http://${server.address.host}:${server.port} (${useFakeApis ? 'fake' : 'live'} mode)',
  );
}

Future<Map<String, String>> _readDotEnv(File file) async {
  if (!await file.exists()) return const {};
  final values = <String, String>{};
  for (final rawLine in await file.readAsLines()) {
    final line = rawLine.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final separator = line.indexOf('=');
    if (separator <= 0) continue;
    final key = line.substring(0, separator).trim();
    var value = line.substring(separator + 1).trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      value = value.substring(1, value.length - 1);
    }
    values[key] = value;
  }
  return values;
}
