/// [Middleware] for Dia that allows you to serving static files
library dia_static;

import 'dart:io';
import 'dart:math' as math;

import 'package:convert/convert.dart';
import 'package:dia/dia.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

/// Dia [Middleware] for serving static path [root]
/// all requested url try found file in [root]
/// [prefix] - replaced in url
Middleware<T> serve<T extends Context>(
  String root, {
  String? prefix,
  String? index,
}) =>
    (ctx, next) async {
      if (!Directory(root).existsSync()) {
        throw ArgumentError('Not found root directory="$root"');
      }
      if (prefix != null && !RegExp(r'^/').hasMatch(prefix)) {
        throw ArgumentError('Param prefix mast start with "/"');
      }

      if (ctx.request.method.toLowerCase() == 'get' ||
          ctx.request.method.toLowerCase() == 'header') {
        final rootDir = Directory(root);
        final rootPath = rootDir.resolveSymbolicLinksSync();

        var uriPath = prefix != null
            ? ctx.request.uri.path.replaceAll(RegExp(r'^' + prefix), '')
            : ctx.request.uri.path;

        if (uriPath.endsWith('/') && index != null) {
          uriPath += index;
        }

        final requestPath =
            path.joinAll([rootPath, ...Uri.parse(uriPath).pathSegments]);
        final entityType = FileSystemEntity.typeSync(requestPath);

        if (entityType == FileSystemEntityType.file) {
          final file = File(requestPath);
          final resolvedPath = file.resolveSymbolicLinksSync();

          if (path.isWithin(rootPath, resolvedPath)) {
            final length = math.min(
              MimeTypeResolver().magicNumbersMaxLength,
              file.lengthSync(),
            );
            final byteSink = ByteAccumulatorSink();
            await file.openRead(0, length).listen(byteSink.add).asFuture();

            final contentType = MimeTypeResolver()
                    .lookup(file.path, headerBytes: byteSink.bytes) ??
                '';

            final stat = file.statSync();
            ctx.headers.set('Content-length', stat.size.toString());
            ctx.headers.set('Content-type', contentType);
            ctx.statusCode =
                ctx.request.method.toLowerCase() == 'header' ? 204 : 200;
            ctx.body = ctx.request.method.toLowerCase() == 'header'
                ? ''
                : file.openRead();
          }
        }
      }

      await next();
    };
