import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> downloadBytes(List<int> bytes, String filename) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  await file.writeAsBytes(bytes);
  return file.path;
}
