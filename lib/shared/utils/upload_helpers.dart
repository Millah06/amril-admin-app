// Cross-platform image-upload helpers.
//
// Ported verbatim from amril-app (lib/shared/utils/upload_helpers.dart) per the
// admin-overhaul roadmap ground rule 1 — do NOT rewrite the picker/upload path.
//
// WHY THIS EXISTS
//   On Flutter WEB, image_picker returns an XFile whose `path` is a blob: URL,
//   NOT a filesystem path. `File(xfile.path)`, `MultipartFile.fromPath(...)` and
//   `getTemporaryDirectory()` all fail (silently) on web. The only portable way
//   to move a picked image is through its BYTES (`xfile.readAsBytes()`).
//
//   Route every multipart upload through these helpers so the web/native split
//   lives in exactly one place and can never drift again.
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

/// Build an `http` MultipartFile from a picked [file], correct on web + native.
Future<http.MultipartFile> httpMultipartFromXFile(
  String field,
  XFile file,
) async {
  if (kIsWeb) {
    final bytes = await file.readAsBytes();
    return http.MultipartFile.fromBytes(field, bytes, filename: file.name);
  }
  return http.MultipartFile.fromPath(
    field,
    file.path,
    filename: p.basename(file.path),
  );
}

/// Build a `dio` MultipartFile from a picked [file], correct on web + native.
Future<dio.MultipartFile> dioMultipartFromXFile(XFile file) async {
  if (kIsWeb) {
    final bytes = await file.readAsBytes();
    return dio.MultipartFile.fromBytes(bytes, filename: file.name);
  }
  return dio.MultipartFile.fromFile(file.path, filename: file.name);
}

/// Wrap raw [bytes] as an XFile that uploads correctly on every platform.
/// Used after in-app editing (e.g. pro_image_editor) where we only have bytes.
/// On web we must NOT write to a temp file (no filesystem) — XFile.fromData
/// keeps the bytes in memory and still exposes readAsBytes()/name.
XFile xfileFromBytes(Uint8List bytes, {required String name}) {
  return XFile.fromData(
    bytes,
    name: name,
    mimeType: 'image/jpeg',
  );
}
