import 'package:file_picker/file_picker.dart';

/// 素材库允许上传的文件扩展名（小写、不含点）。
const List<String> kAdMediaUploadExtensions = <String>[
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'mp4',
  'mov',
  'avi',
  'mkv',
  'webm',
  'mp3',
  'wav',
  'aac',
  'flac',
  'm4a',
];

/// 打开文件选择器，选中单个素材文件时返回本地路径。
Future<String?> pickAdMediaFilePath() async {
  final PlatformFile? file = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: kAdMediaUploadExtensions,
  );
  if (file == null) return null;

  final String? path = file.path;
  if (path == null || path.isEmpty) return null;
  return path;
}
