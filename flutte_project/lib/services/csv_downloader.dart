// lib/services/csv_downloader.dart
//
// Wrapper dùng conditional import.
// - Web: csv_downloader_web.dart
// - Non-web: csv_downloader_stub.dart

import 'csv_downloader_stub.dart'
    if (dart.library.html) 'csv_downloader_web.dart';

/// Tải / lưu CSV xuống máy người dùng.
/// - Web: trigger browser download
/// - Mobile: mở Share/Save As để người dùng chọn nơi lưu
Future<String?> downloadCsv(String csvContent, String fileName) {
  return downloadCsvImpl(csvContent, fileName);
}
