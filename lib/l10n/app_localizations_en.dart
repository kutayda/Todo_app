// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Todo Calendar';

  @override
  String get newTask => 'New Task';

  @override
  String get editTask => 'Edit Task';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get highPriority => 'High Priority';

  @override
  String get mediumPriority => 'Medium Priority';

  @override
  String get lowPriority => 'Low Priority';

  @override
  String get pastTimeError => 'You cannot select a past time!';

  @override
  String overdueWarning(Object count) {
    return 'Warning! You have $count overdue tasks!';
  }

  @override
  String get noTasks => 'No plans for today Hz';
}
