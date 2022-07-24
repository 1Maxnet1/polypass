import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:polypass/components/appwrapper.dart';

import 'package:polypass/blocs/app_settings_bloc.dart';
import 'package:polypass/pages/settings/settings_bloc.dart';

class Settings extends StatelessWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppWrapper(
        actions: false,
        icon: false,
        child: BlocProvider(
          create: (_context) =>
              SettingsBloc(settingsBloc: context.read<AppSettingsBloc>()),
          child: Center(
              child: Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.symmetric(horizontal: 25),
                  decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(10)),
                  child: BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                    return Column(children: [
                      const Text('Default Vault Settings',
                          style: TextStyle(fontSize: 30, color: Colors.white)),
                      ToggleSetting(
                          title: 'Save key in memory while vault is unlocked',
                          value: state
                              .settings.defaultVaultSettings.saveKeyInMemory,
                          onChanged: (setting) {
                            context
                                .read<SettingsBloc>()
                                .add(SettingsEvent.setSaveKeyInMemory(setting));
                          }),
                      TextSetting(
                          title: 'KDF Iterations',
                          value: state.settings.defaultVaultSettings.iterations
                              .toString(),
                          onChanged: (setting) {
                            final parsed = int.tryParse(setting);
                            if (parsed != null) {
                              context
                                  .read<SettingsBloc>()
                                  .add(SettingsEvent.setKDFIterations(parsed));
                            }
                          }),
                      TextSetting(
                          title: 'KDF Threads',
                          value: state.settings.defaultVaultSettings.threads
                              .toString(),
                          onChanged: (setting) {
                            final parsed = int.tryParse(setting);
                            if (parsed != null) {
                              context
                                  .read<SettingsBloc>()
                                  .add(SettingsEvent.setKDFThreads(parsed));
                            }
                          }),
                      TextSetting(
                          title: 'KDF Memory',
                          value: state.settings.defaultVaultSettings.memory
                              .toString(),
                          onChanged: (setting) {
                            final parsed = int.tryParse(setting);
                            if (parsed != null) {
                              context
                                  .read<SettingsBloc>()
                                  .add(SettingsEvent.setKDFMemory(parsed));
                            }
                          }),
                      Row(
                        children: const [
                          BackToHomeButton(),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
                          SaveButton()
                        ],
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                      )
                    ], mainAxisSize: MainAxisSize.min);
                  }))),
        ));
  }
}

class ToggleSetting extends StatelessWidget {
  const ToggleSetting(
      {Key? key,
      required this.title,
      required this.value,
      required this.onChanged})
      : super(key: key);

  final String title;
  final bool value;
  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title),
        Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).colorScheme.tertiary)
      ],
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
    );
  }
}

class TextSetting extends StatelessWidget {
  const TextSetting(
      {Key? key,
      required this.title,
      required this.value,
      required this.onChanged})
      : super(key: key);

  final String title;
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final controller = TextEditingController();
    controller.text = value;
    controller.selection = TextSelection.fromPosition(
        TextPosition(offset: controller.text.length));

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: theme.colorScheme.secondary),
      margin: const EdgeInsets.all(5),
      child: TextField(
          controller: controller,
          decoration: InputDecoration(
              labelText: title,
              contentPadding: const EdgeInsets.all(10),
              floatingLabelStyle: theme.textTheme.bodySmall,
              labelStyle: theme.textTheme.bodySmall,
              border: InputBorder.none),
          style: theme.textTheme.bodySmall,
          onChanged: onChanged),
    );
  }
}

class BackToHomeButton extends StatelessWidget {
  const BackToHomeButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Back',
          style: TextStyle(color: Colors.white, fontSize: 20)),
      style: ButtonStyle(
          padding: MaterialStateProperty.all(const EdgeInsets.all(15))),
      onPressed: () {
        GoRouter.of(context).go('/');
      },
    );
  }
}

class SaveButton extends StatelessWidget {
  const SaveButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: const Text('Save',
          style: TextStyle(color: Colors.white, fontSize: 20)),
      style: ButtonStyle(
          padding: MaterialStateProperty.all(const EdgeInsets.all(15))),
      onPressed: () {
        context.read<SettingsBloc>().add(const SettingsEvent.settingsSaved());
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Settings saved')));
      },
    );
  }
}
