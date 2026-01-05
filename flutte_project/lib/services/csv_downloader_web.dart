// lib/services/csv_downloader_web.dart
//
// Chỉ dùng cho Web (dart.library.html)

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

/// Web implementation: tạo Blob -> Anchor download.
/// Return: null (không có path trên web)
Future<String?> downloadCsvImpl(String csvContent, String fileName) async {
  // Ensure UTF-8 + BOM để Excel VN mở không lỗi dấu
  final bytes = utf8.encode('\ufeff$csvContent');
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');

  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..style.display = 'none'
    ..download = fileName;

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();

  // cleanup
  html.Url.revokeObjectUrl(url);

  return null;
}
