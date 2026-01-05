// lib/services/csv_downloader_stub.dart
//
// Dùng cho Android/iOS/Desktop (không phải web).
// Không dùng package => lưu file vào systemTemp và trả về path.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

Future<String?> downloadCsvImpl(String csvContent, String fileName) async {
  // systemTemp luôn có, không cần permission
  final dir = Directory.systemTemp;

  // Đảm bảo filename an toàn
  final safeName = fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

  final file = File('${dir.path}/$safeName');

  // BOM để Excel mở đúng dấu
  final bytes = utf8.encode('\ufeff$csvContent');
  await file.writeAsBytes(bytes, flush: true);

  // Trả path để UI có thể show snackbar / debug
  return file.path;
}
