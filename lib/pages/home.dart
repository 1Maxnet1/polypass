import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/db_bloc.dart';

import '../appwrapper.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppWrapper(
      actions: false,
      icon: false,
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.key,
              size: 200,
              color: Colors.green
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 5)
            ),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Color(0xFF282c34),
                borderRadius: BorderRadius.all(Radius.circular(10))
              ),
              child: Column(
                children: [
                  const Text(
                    'Welcome to PolyPass',
                    style: TextStyle( fontSize: 30, color: Colors.white )
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 5)
                  ),
                  ElevatedButton(
                    child: const Padding(
                      child: Text('Create a database', style: TextStyle( fontSize: 25 )),
                      padding: EdgeInsets.all(5)
                    ),
                    onPressed: () {
                      GoRouter.of(context).go('/create');
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 5)
                  ),
                  ElevatedButton(
                    child: const Padding(
                      child: Text('Open a database', style: TextStyle( fontSize: 25 )),
                      padding: EdgeInsets.all(5)
                    ),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        dialogTitle: 'Open database',
                        type: FileType.custom,
                        allowedExtensions: ['ppdb']
                      );

                      final path = result?.paths.first;
                      
                      if(path != null) {
                        context.read<DatabaseBloc>().add(DatabaseOpened(path: path));
                      }
                    },
                  )
                ],
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
              ),
            )
          ],
          mainAxisAlignment: MainAxisAlignment.center,
        )
      )
    );
  }
}