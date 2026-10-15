import 'dart:convert';
import 'dart:io';

List<int>? compressGzipBytes(String bodyStr) {
  try {
    return gzip.encode(utf8.encode(bodyStr));
  } catch (_) {
    return null;
  }
}
