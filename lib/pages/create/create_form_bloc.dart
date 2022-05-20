import 'package:bloc/bloc.dart';

import 'package:polypass/data/vault_repository.dart';
import 'package:polypass/data/vault_file.dart';

import 'package:freezed_annotation/freezed_annotation.dart';
part 'create_form_bloc.freezed.dart';

@freezed
class CreateFormState with _$CreateFormState {
  const CreateFormState._();
  const factory CreateFormState(
    String name,
    String description,
    String masterPassword,
    String path,
    bool submitted,
    bool created
  ) = _CreateFormState;

  factory CreateFormState.empty() => const CreateFormState('', '', '', '', false, false);

  bool get isFormValid => (name != '') && (description != '') && (masterPassword != '') && (path != '');
}

@freezed
class CreateFormEvent with _$CreateFormEvent {
  const factory CreateFormEvent.nameChanged(String name) = NameChangedEvent;
  const factory CreateFormEvent.descriptionChanged(String description) = DescriptionChangedEvent;
  const factory CreateFormEvent.masterPasswordChanged(String masterPassword) = MasterPasswordChangedEvent;
  const factory CreateFormEvent.pathChanged(String path) = PathChangedEvent;
  const factory CreateFormEvent.formSubmitted() = FormSubmittedEvent;
}

class CreateFormBloc extends Bloc<CreateFormEvent, CreateFormState> {
  CreateFormBloc({
    required this.vaultRepository
  }) : super(CreateFormState.empty()) {
    on<CreateFormEvent>((event, emit) async {
      await event.map(
        nameChanged: (event) => _onNameChanged(event, emit),
        descriptionChanged: (event) => _onDescriptionChanged(event, emit),
        masterPasswordChanged: (event) => _onMasterPasswordChanged(event, emit),
        pathChanged: (event) => _onPathChanged(event, emit),
        formSubmitted: (event) => _onFormSubmitted(event, emit)
      );
    });
  }

  final VaultRepository vaultRepository;

  Future<void> _onNameChanged(NameChangedEvent event, Emitter<CreateFormState> emit) async {
    emit(state.copyWith(
      name: event.name
    ));
  }

  Future<void> _onDescriptionChanged(DescriptionChangedEvent event, Emitter<CreateFormState> emit) async {
    emit(state.copyWith(
      description: event.description
    ));
  }

  Future<void> _onMasterPasswordChanged(MasterPasswordChangedEvent event, Emitter<CreateFormState> emit) async {
    emit(state.copyWith(
      masterPassword: event.masterPassword
    ));
  }

  Future<void> _onPathChanged(PathChangedEvent event, Emitter<CreateFormState> emit) async {
    emit(state.copyWith(
      path: event.path
    ));
  }

  Future<void> _onFormSubmitted(FormSubmittedEvent event, Emitter<CreateFormState> emit) async {
    emit(state.copyWith(
      submitted: true
    ));

    // TODO: Derive masterKey from state.masterPassword
    // ignore: prefer_const_declarations
    final masterKey = '';

    await vaultRepository.updateFile(VaultFile(
      header: VaultHeader(
        name: state.name,
        description: state.description
      ),
      path: state.path,
      contents: const EncryptedData<VaultContents>.decrypted(VaultContents(components: []))
    ), masterKey);

    emit(state.copyWith(
      created: true
    ));
  }
}