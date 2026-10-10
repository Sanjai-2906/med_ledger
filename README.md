# med_ledger

Initial offline Patient Ledger application built with Flutter and SQLite.

## Test login

- Password: `admin123`
- The password hash is stored in the local `patient_ledger.db` SQLite file.
- The database is stored in the project root's `data` folder, beside `lib` and `build`.
- The `data` folder and database file are created automatically when they do not exist.

## Build Windows executable

```powershell
flutter build windows --release
```

The executable is generated at `build\windows\x64\runner\Release\med_ledger.exe`.
