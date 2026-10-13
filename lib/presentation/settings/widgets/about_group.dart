import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/presentation/common/widgets/settings_group.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// The app's version and the licenses of everything it's built with.
class AboutGroup extends StatefulWidget {
  const AboutGroup({super.key});

  @override
  State<AboutGroup> createState() => _AboutGroupState();
}

class _AboutGroupState extends State<AboutGroup> {
  late final Future<PackageInfo> _info = PackageInfo.fromPlatform();

  /// Packages register their licenses automatically; the bundled fonts
  /// don't, so they're added the first time the page opens.
  static var _fontLicensesAdded = false;

  static const _fontLicenses = {
    'Fredoka': 'assets/fonts/Fredoka-OFL.txt',
    'Figtree': 'assets/fonts/Figtree-OFL.txt',
  };

  void _openLicenses() {
    if (!_fontLicensesAdded) {
      _fontLicensesAdded = true;
      LicenseRegistry.addLicense(() async* {
        for (final MapEntry(key: font, value: asset) in _fontLicenses.entries) {
          yield LicenseEntryWithLineBreaks([
            font,
          ], await rootBundle.loadString(asset));
        }
      });
    }
    showLicensePage(context: context, applicationName: context.l10n.appTitle);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SettingsGroup(
      label: l10n.settingsAbout,
      rows: [
        FutureBuilder(
          future: _info,
          builder: (context, snapshot) => SettingsRow(
            leading: const Icon(LucideIcons.info),
            title: l10n.settingsVersion,
            value: switch (snapshot.data) {
              final info? => l10n.settingsVersionValue(
                info.version,
                info.buildNumber,
              ),
              null => null,
            },
          ),
        ),
        SettingsRow(
          leading: const Icon(LucideIcons.fileText),
          title: l10n.settingsLicenses,
          onTap: _openLicenses,
        ),
      ],
    );
  }
}
