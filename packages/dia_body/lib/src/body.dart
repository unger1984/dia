import 'dart:convert';
import 'dart:io' hide BytesBuilder;
import 'dart:typed_data';

import 'package:dia/dia.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';

import 'parsed_body_mixin.dart';
import 'uploaded_file.dart';

/// Dia [Middleware] for parsing [HttpRequest] body
/// [uploadDirectory] - directory for uploading files, default = Directory.systemTemp;
Middleware<T> body<T extends ParsedBody>({Directory? uploadDirectory}) =>
    (T ctx, next) async {
      ctx.query.addAll(ctx.request.uri.queryParameters);
      final dataStream = ctx.request.cast<List<int>>();

      final media = ctx.request.headers.contentType != null
          ? MediaType.parse(ctx.request.headers.value('content-type')!)
          : null;

      uploadDirectory ??= Directory.systemTemp.createTempSync();

      Future<String> getBody() {
        return utf8.decoder.bind(dataStream).join();
      }

      if (media != null) {
        if (media.type == 'multipart' &&
            media.parameters.containsKey('boundary')) {
          await _parseMultipart(ctx, uploadDirectory!, media, dataStream);
        } else if (media.mimeType == 'application/json') {
          final body = await getBody();
          if (body.isNotEmpty) {
            ctx.parsed
                .addAll(_foldToStringDynamic(json.decode(body) as Map) ?? {});
          }
        } else if (media.mimeType == 'application/x-www-form-urlencoded') {
          final body = await getBody();
          if (body.isNotEmpty) ctx.parsed.addAll(Uri.splitQueryString(body));
        }
      }

      await next();
    };

Map<String, dynamic>? _foldToStringDynamic(Map? map) {
  return map?.keys.fold<Map<String, dynamic>>(
    <String, dynamic>{},
    (out, k) => out..[k.toString()] = map[k],
  );
}

Future<List<UploadedFile>> _saveFiles(
  Directory uploadDirectory,
  Map<String, List<MimeMultipart>> map,
) async {
  final files = <UploadedFile>[];
  for (var filename in map.keys) {
    var list = map[filename]!;
    final file = File('${uploadDirectory.path}/${Uuid().v4()}');
    for (var part in list) {
      if (!file.existsSync()) file.createSync(recursive: true);
      final fileSink = file.openWrite();
      await part.pipe(fileSink);
      await fileSink.close();
    }
    files.add(UploadedFile(filename, file));
  }

  return files;
}

Future<void> _parseMultipart(
  ctx,
  Directory uploadDirectory,
  MediaType media,
  Stream<List<int>> dataStream,
) async {
  var parts = dataStream.transform(
    MimeMultipartTransformer(media.parameters['boundary']!),
  );

  final filesParts = <String, Map<String, List<MimeMultipart>>>{};

  await for (MimeMultipart part in parts) {
    var header = HeaderValue.parse(part.headers['content-disposition']!);
    var name = header.parameters['name']!;

    var filename = header.parameters['filename'];
    if (filename != null) {
      var map = filesParts[name] ?? {};
      var list = map[filename] ?? [];
      list.add(part);
      map[filename] = list;
      filesParts[name] = map;
    } else {
      // if this part is not file
      var builder = await part.fold(
        BytesBuilder(copy: false),
        (BytesBuilder b, List<int> d) =>
            b..add(d is! String ? d : (d as String).codeUnits),
      );
      ctx.parsed[name] = utf8.decode(builder.takeBytes());
    }
  }

  for (var name in filesParts.keys) {
    var map = filesParts[name]!;
    ctx.files[name] = await _saveFiles(uploadDirectory, map);
  }
}
