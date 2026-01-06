//
// Mobile/Desktop implementation (non-web):
// - Ghi CSV vào thư mục tạm
// - Mở Share/Save As để user chọn lưu vào Files/Drive/Zalo/Gmail...
//
// ✅ 100% miễn phí, không cần Cloud Functions.

import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String?> downloadCsvImpl(String csvContent, String fileName) async {
  // đảm bảo có đuôi .csv
  final safeName = fileName.toLowerCase().endsWith('.csv')
      ? fileName
      : '$fileName.csv';

  // ghi file vào thư mục tạm (sandbox)
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$safeName');
  await file.writeAsString(csvContent, flush: true);

  // mở share sheet để user chọn lưu/chia sẻ
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/csv', name: safeName)],
    subject: safeName,
    text: 'CSV export: $safeName',
  );

  // trả path nội bộ (để debug). File có thể bị dọn bởi OS sau một thời gian.
  return file.path;
}
