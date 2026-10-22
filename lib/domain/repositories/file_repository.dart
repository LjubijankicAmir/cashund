import 'package:cashund/core/error/result.dart';

/// A file the user picked: its name and its text.
typedef PickedFile = ({String name, String contents});

/// Moving files in and out of the app, through the system's share sheet
/// and file picker. The user decides where files go; the app never uploads.
abstract interface class FileRepository {
  /// Offers a file named [fileName] with [contents] in the share sheet.
  /// `true` when the user shared it somewhere, `false` when they backed out.
  FutureResult<bool> share({
    required String fileName,
    required String contents,
    required String mimeType,
  });

  /// Lets the user pick a file and reads it as text; `null` when they
  /// backed out.
  FutureResult<PickedFile?> pickText();
}
