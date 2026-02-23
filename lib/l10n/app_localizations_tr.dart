// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Todo Takvimi';

  @override
  String get newTask => 'Yeni Görev';

  @override
  String get editTask => 'Görevi Düzenle';

  @override
  String get title => 'Başlık';

  @override
  String get description => 'Açıklama';

  @override
  String get add => 'Ekle';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'İptal';

  @override
  String get delete => 'Sil';

  @override
  String get highPriority => 'Yüksek Öncelik';

  @override
  String get mediumPriority => 'Orta Öncelik';

  @override
  String get lowPriority => 'Düşük Öncelik';

  @override
  String get pastTimeError => 'Geçmiş bir zamana görev ekleyemezsin!';

  @override
  String overdueWarning(Object count) {
    return 'Dikkat! Süresi dolmuş $count görevin var!';
  }

  @override
  String get noTasks => 'Bugün için plan yok 💤';
}
