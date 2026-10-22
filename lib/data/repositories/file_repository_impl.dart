import 'dart:io';

import 'package:cashund/core/error/result.dart';
import 'package:cashund/data/repositories/guarded.dart';
import 'package:cashund/domain/repositories/file_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

@LazySingleton(as: FileRepository)
class FileRepositoryImpl implements FileRepository {
  @override
  FutureResult<bool> share({
    required String fileName,
    required String contents,
    required String mimeType,
  }) => guardFuture(() async {
    // Shared from the app's temporary folder, which the system cleans up.
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(contents, flush: true);

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: mimeType)],
        fileNameOverrides: [fileName],
      ),
    );
    // Some platforms can't tell what the user picked; that still counts.
    return result.status != ShareResultStatus.dismissed;
  });

  @override
  FutureResult<PickedFile?> pickText() => guardFuture(() async {
    final picked = await FilePicker.pickFile();
    if (picked == null) return null;
    return (name: picked.name, contents: await picked.xFile.readAsString());
  });
}
