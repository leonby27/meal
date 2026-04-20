import 'package:flutter/widgets.dart';
import 'package:meal_tracker/core/services/locale_service.dart';
import 'package:meal_tracker/l10n/app_localizations.dart';

extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

AppLocalizations get currentL10n =>
    lookupAppLocalizations(LocaleNotifier.instance.value);
