import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

enum DatabaseStatus { none, locked, unlocked, opening}

enum DatabaseComponent {
  category(DatabaseCategory),
  item(ItemData);

  const DatabaseComponent(component);
}

class DatabaseCategory {
  const DatabaseCategory({
    required this.name,
    this.icon,
    this.components = const []
  });

  final String name;
  final String? icon;
  final List<DatabaseComponent> components;
}

class ItemData {
  const ItemData();
}

class DatabaseState extends Equatable {
  const DatabaseState({
    required this.tree,
    required this.name,
    required this.description,
    required this.path,
    required this.status
  });

  final List<DatabaseComponent> tree;
  final String name;
  final String description;
  final String path;
  final DatabaseStatus status;

  DatabaseState copyWith({
    List<DatabaseComponent>? tree,
    String? name,
    String? description,
    String? path,
    DatabaseStatus? status
  }) {
    return DatabaseState(
      tree: tree ?? this.tree,
      name: name ?? this.name,
      description: description ?? this.description,
      path: path ?? this.path,
      status: status ?? this.status
    );
  }

  @override
  List<dynamic> get props => [tree, name, description, path, status];
}

abstract class DatabaseBlocEvent extends Equatable {
  const DatabaseBlocEvent();

  @override
  List<dynamic> get props => [];
}

class DatabaseOpened extends DatabaseBlocEvent {
  const DatabaseOpened({
    required this.path
  });

  final String path;

  @override
  List<String> get props => [path];
}

class DatabaseLocked extends DatabaseBlocEvent {
  const DatabaseLocked();
}

class DatabaseUnlocked extends DatabaseBlocEvent {
  const DatabaseUnlocked({
    required this.masterKey
  });

  final String masterKey;

  @override
  List<String> get props => [masterKey];
}

class DatabaseClosed extends DatabaseBlocEvent {
  const DatabaseClosed();

  @override
  List<String> get props => [];
}

class DatabaseBloc extends Bloc<DatabaseBlocEvent, DatabaseState> {
  DatabaseBloc({
    String name = '',
    String description = '',
    String path = '',
    List<DatabaseComponent> tree = const [],
    DatabaseStatus status = DatabaseStatus.none
  }) : super(DatabaseState(
    name: name,
    description: description,
    path: path,
    tree: tree,
    status: status 
  )) {
    on<DatabaseOpened>(_onDatabaseOpened);
    on<DatabaseLocked>(_onDatabaseLocked);
    on<DatabaseUnlocked>(_onDatabaseUnlocked);
    on<DatabaseClosed>(_onDatabaseClosed);
  }

  Future<void> _onDatabaseOpened(event, emit) async {
    emit(state.copyWith(
      status: DatabaseStatus.opening
    ));
    // TODO: Call repository function to fetch db data using event.path
    await Future.delayed(const Duration( seconds: 2));


    emit(state.copyWith(
      status: DatabaseStatus.locked
    ));
  }

  void _onDatabaseLocked(event, emit) {
    // TODO: Lock database
    emit(state.copyWith(
      status: DatabaseStatus.locked
    ));
  }

  void _onDatabaseUnlocked(event, emit) {
    // TODO: Decrypt database with event.masterKey
    emit(state.copyWith(
      status: DatabaseStatus.unlocked
    ));
  }

  void _onDatabaseClosed(event, emit) {
    emit(const DatabaseState(
      name: '',
      description: '',
      path: '',
      tree: const [],
      status: DatabaseStatus.none
    ));
  }
}