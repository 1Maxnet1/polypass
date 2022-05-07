import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/db_bloc.dart';
import './blocs/unlock_form_bloc.dart';

import '../../../components/appwrapper.dart';

class DbLocked extends StatelessWidget {
  const DbLocked({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppWrapper(
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF373b42),
            borderRadius: BorderRadius.circular(10)
          ),
          padding: const EdgeInsets.all(10),
          width: 600,
          child: Form(
            child: BlocProvider(
              create: (context) => UnlockFormBloc(),
              child: MultiBlocListener(
                listeners: [
                  BlocListener<UnlockFormBloc, UnlockFormState>(
                    listener: (context, state) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Unlocking database...'),
                        duration: Duration( days: 365 )
                      ));
                    },
                    listenWhen: (previous, current) => previous.submitted != current.submitted
                  ),
                  BlocListener<UnlockFormBloc, UnlockFormState>(
                    listener: (context, state) {
                      context.read<DatabaseBloc>().add(DatabaseUnlocked(masterKey: state.masterKey));
                    },
                    listenWhen: (previous, current) => previous.unlocked != current.unlocked
                  )
                ],
                child: Column(
                  children: [
                    const Text(
                      'Unlock Database',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30
                      )
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5)
                      ),
                      margin: const EdgeInsets.symmetric( vertical: 10, horizontal: 5 ),
                      child: const MasterPasswordInput(),
                    ),
                    const SubmitButton()
                  ],
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                ),
              ),
            ),
          ),
        )
      )
    );
  }
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnlockFormBloc, UnlockFormState>(
      builder: (context, state) {
        return ElevatedButton(
          child: const Text(
            'Submit',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20
            )
          ),
          style: ButtonStyle(
            padding: MaterialStateProperty.all(const EdgeInsets.all(15))
          ),
          onPressed: state.submitted || !state.isFormValid ? null : () {
            context.read<UnlockFormBloc>().add(const FormSubmitted());
          },
        );
      }
    );
  }
}

class MasterPasswordInput extends StatelessWidget {
  const MasterPasswordInput({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UnlockFormBloc, UnlockFormState>(
      builder: (context, state) {
        return TextFormField(
          enabled: !state.submitted,
          decoration: const InputDecoration(
            labelText: 'Master Password',
            contentPadding: EdgeInsets.all(10),
            floatingLabelStyle: TextStyle( color: Colors.black ),
            labelStyle: TextStyle( color: Colors.black ),
            border: InputBorder.none
          ),
          cursorColor: Colors.black,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          onChanged: (masterPassword) {
            context.read<UnlockFormBloc>().add(MasterPasswordChanged( masterPassword: masterPassword));
          },
        );
      }
    );
  }
}