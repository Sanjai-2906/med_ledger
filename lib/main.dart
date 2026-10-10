import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late Future<Database> _database;

  @override
  void initState() {
    super.initState();
    _database = _openDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Patient Ledger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176b87), brightness: Brightness.light),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: FutureBuilder<Database>(
        future: _database,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ErrorPage();
          }
          if (!snapshot.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return LoginPage(database: snapshot.data!);
        },
      ),
    );
  }

  Future<Database> _openDatabase() async {
    final projectDirectory = _findProjectDirectory();
    final dataDirectory = Directory(path.join(projectDirectory, 'data'));
    await dataDirectory.create(recursive: true);
    final databasePath = path.join(dataDirectory.path, 'patient_ledger.db');

    return openDatabase(
      databasePath,
      version: 1,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE credentials (
            id INTEGER PRIMARY KEY,
            password_hash TEXT NOT NULL
          )
        ''');
        await database.insert('credentials', {'id': 1, 'password_hash': _hashPassword('admin123')});
      },
    );
  }

  String _findProjectDirectory() {
    final startingDirectories = [Directory.current.path, path.dirname(Platform.resolvedExecutable)];

    for (final startingDirectory in startingDirectories) {
      var directory = Directory(startingDirectory);
      while (true) {
        final pubspecPath = path.join(directory.path, 'pubspec.yaml');
        if (File(pubspecPath).existsSync()) {
          return directory.path;
        }

        final parent = directory.parent;
        if (parent.path == directory.path) {
          break;
        }
        directory = parent;
      }
    }

    return Directory.current.path;
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({required this.database, super.key});

  final Database database;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => PatientLedgerPage(database: widget.database)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.medical_information_outlined, size: 52, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Patient Ledger',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter anything or leave blank to continue',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofocus: true,
                      onSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(onPressed: _login, child: const Text('Login')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PatientLedgerPage extends StatelessWidget {
  const PatientLedgerPage({required this.database, super.key});

  final Database database;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Ledger'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute<void>(builder: (_) => LoginPage(database: database))),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
      body: const Center(child: Text('Patient ledger')),
    );
  }
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Unable to open the local database.')));
  }
}

String _hashPassword(String password) {
  return base64UrlEncode(utf8.encode(password));
}
