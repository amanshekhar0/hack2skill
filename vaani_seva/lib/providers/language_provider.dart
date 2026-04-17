import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _languageCode = 'hi-IN';
  String _languageName = 'Hindi';

  String get languageCode => _languageCode;
  String get languageName => _languageName;
  bool get isHindi => _languageCode == 'hi-IN';

  Future<void> setLanguage(String code, String name) async {
    _languageCode = code;
    _languageName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang_code', code);
    await prefs.setString('lang_name', name);
    notifyListeners();
  }

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString('lang_code') ?? 'hi-IN';
    _languageName = prefs.getString('lang_name') ?? 'Hindi';
    notifyListeners();
  }
}
