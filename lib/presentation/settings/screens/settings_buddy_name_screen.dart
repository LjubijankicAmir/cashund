import 'package:auto_route/auto_route.dart';
import 'package:cashund/core/l10n/l10n.dart';
import 'package:cashund/core/theme/cashund_tokens.dart';
import 'package:cashund/presentation/common/widgets/buddy_avatar.dart';
import 'package:cashund/presentation/common/widgets/buddy_name_field.dart';
import 'package:cashund/presentation/common/widgets/primary_button.dart';
import 'package:cashund/presentation/common/widgets/pushed_page_header.dart';
import 'package:cashund/presentation/settings/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Renames the buddy. Saved with the button, then the page closes.
@RoutePage()
class SettingsBuddyNameScreen extends StatefulWidget {
  const SettingsBuddyNameScreen({super.key});

  @override
  State<SettingsBuddyNameScreen> createState() =>
      _SettingsBuddyNameScreenState();
}

class _SettingsBuddyNameScreenState extends State<SettingsBuddyNameScreen> {
  late final _controller = TextEditingController(
    text: context.read<SettingsBloc>().state.preferences?.buddyName,
  );

  /// Set once this page asked to save, so only its own save closes it.
  var _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    _saving = true;
    context.read<SettingsBloc>().add(
      SettingsEvent.buddyNameSaved(_controller.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocListener<SettingsBloc, SettingsState>(
      listenWhen: (previous, current) =>
          _saving && previous.status != current.status,
      listener: (context, state) {
        switch (state.status) {
          case SettingsStatus.saved:
            Navigator.of(context).pop();
          case SettingsStatus.failure:
            _saving = false;
          case SettingsStatus.idle || SettingsStatus.saving:
            break;
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    CashundSpace.s6,
                    CashundSpace.s3,
                    CashundSpace.s6,
                    CashundSpace.s6,
                  ),
                  children: [
                    PushedPageHeader(title: l10n.settingsBuddyNameTitle),
                    const SizedBox(height: CashundSpace.s6),
                    const Center(child: BuddyAvatar(size: 96)),
                    const SizedBox(height: CashundSpace.s6),
                    BuddyNameField(
                      controller: _controller,
                      helper: l10n.settingsBuddyNameHelper,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  CashundSpace.s6,
                  CashundSpace.s3,
                  CashundSpace.s6,
                  CashundSpace.s4,
                ),
                child: PrimaryButton(
                  label: l10n.settingsSaveName,
                  onPressed: _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
