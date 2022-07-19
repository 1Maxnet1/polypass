import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:polypass/pages/vault/home/vault_home_bloc.dart';
import 'package:polypass/data/vault_file.dart';
import 'package:polypass/blocs/vault_bloc.dart';
import 'package:polypass/pages/vault/home/component_bloc.dart';
import 'package:polypass/pages/vault/home/list_item_bloc.dart';

import 'package:polypass/components/master_password_dialog.dart';
import 'package:polypass/components/appwrapper.dart';

class VaultHome extends StatelessWidget {
  const VaultHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppWrapper(
        child: BlocProvider(
      create: (context) => VaultHomeBloc(vaultBloc: context.read<VaultBloc>()),
      child: Column(children: const [SearchBar(), PasswordsView()]),
    ));
  }
}

class PasswordsView extends StatelessWidget {
  const PasswordsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Theme.of(context).cardColor),
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          child: Row(children: const [
            Tree(),
            SizedBox(width: 3, child: VerticalDivider()),
            FolderList()
          ])),
    );
  }
}

class Tree extends StatelessWidget {
  const Tree({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width * .25) - 21,
      child: BlocBuilder<VaultBloc, VaultState>(builder: (context, state) {
        final unlockedState =
            state.maybeMap(unlocked: (state) => state, orElse: () => null);

        if (unlockedState == null) {
          return Container();
        }

        final decryptedContents = unlockedState.vault.contents.maybeMap(
            decrypted: (contents) => contents, orElse: () => throw Error());

        final groups =
            decryptedContents.data.components.whereType<Group>().toList();
        groups.sort((a, b) =>
            a.group.name.toLowerCase().compareTo(b.group.name.toLowerCase()));

        if (unlockedState.selectedGroup?[0] == 'Search Results') {
          final components = context
              .read<VaultHomeBloc>()
              .state
              .results
              .map((path) => unlockedState.vault.getComponent(path));

          groups.add(Group(VaultGroup(
              name: 'Search Results', components: components.toList())));
        }

        return ListView(primary: false, children: [
          ...groups.map((group) =>
              TreeGroup(group: group.group, path: [group.group.name]))
        ]);
      }),
    );
  }
}

class TreeGroup extends StatelessWidget {
  const TreeGroup({Key? key, required this.group, this.path = const []})
      : super(key: key);

  final VaultGroup group;
  final List<String> path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_context) => ComponentBloc(),
      child: BlocBuilder<ComponentBloc, ComponentState>(
        builder: (context, componentState) {
          return BlocBuilder<VaultBloc, VaultState>(
              builder: (context, vaultState) {
            final unlockedState = vaultState.maybeMap(
                unlocked: (state) => state, orElse: () => throw Error());
            final Widget textWidget;
            if (componentState.mode == ComponentMode.normal) {
              textWidget = Text(group.name,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: theme.textTheme.bodySmall!.fontSize));
            } else {
              textWidget = TextFormField(
                initialValue: group.name,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: theme.textTheme.bodySmall!.fontSize),
                onFieldSubmitted: (newName) async {
                  if (newName.contains(RegExp(r'\.'))) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Invalid character - "." is not allowed in names')));
                    return;
                  }

                  if (newName == 'Search Results') {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('This group name is reserved')));
                    return;
                  }

                  final vaultBloc = context.read<VaultBloc>();

                  var selectedPath = unlockedState.selectedGroup;

                  if (selectedPath != null) {
                    if (selectedPath.join('.') == path.join('.')) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content:
                              Text('You cannot rename the selected group')));
                      return;
                    }
                  }

                  final parentGroup = path.length == 1
                      ? unlockedState.vault.toGroup()
                      : unlockedState.vault
                          .getComponent(path.take(path.length - 1).toList())
                          .maybeWhen(
                              group: (group) => group,
                              orElse: () => throw Error());

                  if (parentGroup.components
                      .where((component) =>
                          component.when(
                              group: (group) => group.name,
                              item: (item) => item.name) ==
                          newName)
                      .isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'A group or item with this name already exists in the selected group')));
                    return;
                  }

                  final component = unlockedState.vault
                      .getComponent(path)
                      .maybeMap(
                          group: (group) => group, orElse: () => throw Error());
                  final updatedComponent = component.copyWith(
                      group: component.group.copyWith(name: newName));

                  final newVault = unlockedState.vault
                      .updateComponent(path: path, component: updatedComponent);

                  var masterKey = (await getMasterKey(context)).masterKey;

                  if (masterKey == null) {
                    return;
                  }

                  vaultBloc.add(VaultEvent.updated(newVault, masterKey));

                  context
                      .read<ComponentBloc>()
                      .add(const ComponentEvent.modeToggled());
                },
              );
            }

            var groups = <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 5),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
                  decoration: BoxDecoration(
                      color: path[0] == 'Search Results'
                          ? Colors.orange
                          : unlockedState.selectedGroup?.join('.') ==
                                  path.join('.')
                              ? theme.colorScheme.tertiary
                              : componentState.inArea
                                  ? theme.colorScheme.primaryContainer
                                  : theme.cardColor,
                      borderRadius: BorderRadius.circular(5)),
                  child: GestureDetector(
                    child: MouseRegion(
                        child: Row(children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              child: textWidget,
                            ),
                          )
                        ]),
                        onEnter: (_event) {
                          context
                              .read<ComponentBloc>()
                              .add(const ComponentEvent.entered());
                        },
                        onExit: (_event) {
                          context
                              .read<ComponentBloc>()
                              .add(const ComponentEvent.exited());
                        }),
                    onTap: () {
                      context.read<VaultBloc>().add(VaultEvent.groupSelected(
                          path,
                          unlockedState.selectedGroup?.join('.') ==
                              path.join('.')));
                    },
                    onDoubleTap: () {
                      context
                          .read<ComponentBloc>()
                          .add(const ComponentEvent.modeToggled());
                    },
                  ),
                ),
              )
            ];

            final selectedPath = unlockedState.selectedGroup;

            if (selectedPath?.join('.') == path.join('.') ||
                path.length < (selectedPath?.length ?? -1)) {
              final childGroups = group.components.whereType<Group>().toList();
              childGroups.sort((a, b) => a.group.name
                  .toLowerCase()
                  .compareTo(b.group.name.toLowerCase()));
              for (final childGroup in childGroups) {
                groups.add(Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: TreeGroup(
                      group: childGroup.group,
                      path: [...path, childGroup.group.name]),
                ));
              }
            }

            return Column(children: groups);
          });
        },
      ),
    );
  }
}

class FolderList extends StatelessWidget {
  const FolderList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width * .75) - 22,
      child: BlocBuilder<VaultBloc, VaultState>(
        builder: (context, state) {
          final unlockedState =
              state.maybeMap(unlocked: (state) => state, orElse: () => null);

          if (unlockedState == null) {
            // TODO: Switch from throwing errors to peacefully returning
            return Container();
          }

          final decryptedContents = unlockedState.vault.contents.maybeMap(
              decrypted: (contents) => contents, orElse: () => throw Error());
          final List<VaultComponent> components;
          final paths = unlockedState.selectedGroup;

          if (paths == null) {
            components = decryptedContents.data.components;
          } else if (paths[0] == 'Search Results') {
            components = context
                .read<VaultHomeBloc>()
                .state
                .results
                .map((path) => unlockedState.vault.getComponent(path))
                .toList();
          } else {
            components = unlockedState.vault.getComponent(paths).maybeWhen(
                group: (group) => group.components,
                orElse: () => throw Error());
          }

          final items = components.whereType<Item>().toList();
          items.sort((a, b) =>
              a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase()));

          return Padding(
            padding: const EdgeInsets.only(left: 15),
            child: ListView(primary: false, children: [
              const ListHeader(),
              ...items.map((item) => ListItem(
                  item: item.item,
                  path: paths != null
                      ? [...paths, item.item.name]
                      : [item.item.name]))
            ]),
          );
        },
      ),
    );
  }
}

class BaseRow extends StatelessWidget {
  const BaseRow(
      {Key? key,
      required this.name,
      required this.username,
      required this.actions,
      required this.extra,
      this.hoverEffect = true,
      this.path})
      : super(key: key);

  final Widget Function(
      ComponentState state, bool isSelected, double columnWidth) name;
  final Widget Function(
      ComponentState state, bool isSelected, double columnWidth) username;
  final Widget? Function(
      ComponentState state, bool isSelected, double columnWidth) actions;
  final List<Widget>? Function(
      ComponentState state, bool isSelected, double columnWidth) extra;
  final bool hoverEffect;
  final List<String>? path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_context) => ComponentBloc(),
      child:
          BlocBuilder<ComponentBloc, ComponentState>(builder: (context, state) {
        final bloc = context.read<ComponentBloc>();
        final rowWidth =
            (MediaQuery.of(context).size.width * .75) - 22 - 15 - 20 - 80;

        final vaultBloc = context.read<VaultBloc>();
        final unlockedState = vaultBloc.state
            .maybeMap(unlocked: (state) => state, orElse: () => throw Error());

        final isSelected =
            path?.join('.') == unlockedState.selectedItem?.join('.');

        var extras = extra(state, isSelected, rowWidth);
        extras ??= [];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: GestureDetector(
                  child: MouseRegion(
                    onEnter: (_event) {
                      bloc.add(const ComponentEvent.entered());
                    },
                    onExit: (_event) {
                      bloc.add(const ComponentEvent.exited());
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: path != null && isSelected
                              ? theme.colorScheme.tertiary
                              : (state.inArea && hoverEffect)
                                  ? theme.colorScheme.primaryContainer
                                  : theme.cardColor,
                          borderRadius: BorderRadius.circular(5)),
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Row(children: [
                                SizedBox(
                                    width: rowWidth * .35,
                                    child: name(
                                        state, isSelected, rowWidth * .35)),
                                const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20)),
                                SizedBox(
                                    width: rowWidth * .35,
                                    child: username(
                                        state, isSelected, rowWidth * .35)),
                                const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20)),
                                SizedBox(
                                    width: rowWidth * .3,
                                    child: actions(
                                        state, isSelected, rowWidth * .3))
                              ]),
                              const Spacer()
                            ],
                          ),
                          ...extras
                        ],
                      ),
                    ),
                  ),
                  onTap: path == null
                      ? null
                      : () {
                          vaultBloc
                              .add(VaultEvent.itemSelected(path, isSelected));
                        }),
            )
          ],
        );
      }),
    );
  }
}

class ListItem extends StatelessWidget {
  const ListItem({Key? key, required this.item, required this.path})
      : super(key: key);

  final VaultItem item;
  final List<String> path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_context) => ListItemBloc(),
      child: BlocBuilder<VaultBloc, VaultState>(builder: (context, vaultState) {
        final unlockedVaultState = vaultState.maybeMap(
            unlocked: (state) => state, orElse: () => throw Error());

        if (unlockedVaultState.viewingSelectedItem &&
            unlockedVaultState.selectedItem?.join('.') == path.join('.')) {
          context
              .read<ListItemBloc>()
              .add(const ListItemEvent.modeToggled(newMode: ListItemMode.view));
        }

        return BlocBuilder<ListItemBloc, ListItemState>(
            builder: (context, state) {
          var decryptedPassword = '';
          if (state.mode == ListItemMode.view) {
            final masterKey = state.masterKey;

            if (masterKey == null) {
              Future.delayed(Duration.zero, () => getMasterKey(context))
                  .then((k) {
                if (k.masterKey == null) {
                  context.read<ListItemBloc>().add(
                      const ListItemEvent.modeToggled(
                          newMode: ListItemMode.normal));
                } else {
                  context
                      .read<ListItemBloc>()
                      .add(ListItemEvent.masterKeyChanged(k.masterKey));
                }
              });
            }

            decryptedPassword = masterKey == null
                ? '-'
                : item.password
                    .decrypt(masterKey)
                    .maybeWhen(
                        decrypted: (data, _iv) => data,
                        orElse: () => throw Error())
                    .password;
          }

          return BaseRow(
              path: path,
              extra: (componentState, isSelected, columnWidth) {
                final extra = <Widget>[];

                if (state.mode == ListItemMode.view) {
                  extra.add(Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Row(children: [
                        SizedBox(
                          width: columnWidth * .35,
                          child: Row(
                            children: [
                              Text('Password: ',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: theme
                                              .textTheme.bodyMedium!.fontSize! *
                                          1.1,
                                      fontWeight: FontWeight.bold)),
                              Text(decryptedPassword,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: theme
                                              .textTheme.bodyMedium!.fontSize! *
                                          1.1,
                                      fontWeight: FontWeight.w300)),
                            ],
                          ),
                        ),
                        const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20)),
                        SizedBox(
                          width: columnWidth * .35,
                          child: Row(
                            children: [
                              Text('Notes: ',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: theme
                                              .textTheme.bodyMedium!.fontSize! *
                                          1.1,
                                      fontWeight: FontWeight.bold)),
                              Text(item.notes,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: theme
                                              .textTheme.bodyMedium!.fontSize! *
                                          1.1,
                                      fontWeight: FontWeight.w300)),
                            ],
                          ),
                        )
                      ])));
                }

                return extra;
              },
              name: (state, isSelected, columnWidth) {
                return Text(item.name,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: theme.textTheme.bodyMedium!.fontSize! * 1.2,
                        fontWeight: FontWeight.w300));
              },
              username: (state, isSelected, columnWidth) {
                return Text(
                  item.username,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: theme.textTheme.bodyMedium!.fontSize! * 1.2,
                      fontWeight: FontWeight.w300),
                );
              },
              actions: (state, isSelected, columnWidth) {
                if (state.inArea) {
                  final actions = <Widget>[
                    RichText(
                        text: TextSpan(
                            text: 'View',
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.lightBlue,
                                fontSize: theme.textTheme.bodySmall!.fontSize,
                                decoration: TextDecoration.underline),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                context.read<ListItemBloc>().add(
                                    const ListItemEvent.masterKeyChanged(null));
                                context
                                    .read<ListItemBloc>()
                                    .add(const ListItemEvent.modeToggled());
                              }))
                  ];

                  if (path[0] != 'Search Results') {
                    actions.addAll([
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5)),
                      RichText(
                          text: TextSpan(
                              text: 'Edit',
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.lightBlue,
                                  fontSize: theme.textTheme.bodySmall!.fontSize,
                                  decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  GoRouter.of(context)
                                      .go('/vault/edit/${path.join('.')}');
                                })),
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5)),
                      RichText(
                          text: TextSpan(
                              text: 'Delete',
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.lightBlue,
                                  fontSize: theme.textTheme.bodySmall!.fontSize,
                                  decoration: TextDecoration.underline),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  final vaultBloc = context.read<VaultBloc>();
                                  final unlockedState = vaultBloc.state
                                      .maybeMap(
                                          unlocked: (state) => state,
                                          orElse: () => throw Error());

                                  final newVault =
                                      unlockedState.vault.deleteComponent(path);

                                  var masterKey =
                                      (await getMasterKey(context)).masterKey;

                                  if (masterKey == null) {
                                    return;
                                  }

                                  vaultBloc.add(
                                      VaultEvent.updated(newVault, masterKey));
                                }))
                    ]);
                  }
                  return Row(children: actions);
                }
              });
        });
      }),
    );
  }
}

class ListHeader extends StatelessWidget {
  const ListHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: BaseRow(
          name: (_state, _isSelected, _columnWidth) {
            return Text('Item Name',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: theme.textTheme.bodyMedium!.fontSize! * 1.3,
                    fontWeight: FontWeight.w400));
          },
          username: (_state, _isSelected, _columnWidth) {
            return Text('Item Username',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: theme.textTheme.bodyMedium!.fontSize! * 1.3,
                    fontWeight: FontWeight.w400));
          },
          actions: (_state, _isSelected, _columnWidth) => null,
          extra: (_state, _isSelected, _columnWidth) => null,
          hoverEffect: false),
    );
  }
}

class SearchBar extends StatelessWidget {
  const SearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vaultHomeBloc = context.read<VaultHomeBloc>();

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5), color: theme.cardColor),
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: theme.colorScheme.secondary),
        padding: const EdgeInsets.only(left: 10),
        child: TextField(
          decoration: InputDecoration(
            icon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                vaultHomeBloc.add(const VaultHomeEvent.searchSubmitted());
              },
            ),
            label: const Text('Search passwords'),
            floatingLabelStyle: theme.textTheme.bodySmall,
            labelStyle: theme.textTheme.bodySmall,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(10),
          ),
          style: theme.textTheme.bodySmall,
          onChanged: (query) {
            vaultHomeBloc.add(VaultHomeEvent.queryChanged(query));
          },
          onSubmitted: (_query) {
            vaultHomeBloc.add(const VaultHomeEvent.searchSubmitted());
          },
        ),
      ),
    );
  }
}
