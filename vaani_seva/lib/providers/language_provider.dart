import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _languageCode = 'en-US';
  bool _isInitialized = false;

  String get languageCode => _languageCode;
  
  String get languageName {
    switch (_languageCode) {
      case 'hi-IN': return 'Hindi';
      case 'kn-IN': return 'Kannada';
      case 'en-US':
      default:
        return 'English';
    }
  }

  Future<void> setLanguage(String code, String name) async {
    print('LanguageProvider: User set code to $code');
    _languageCode = code;
    _isInitialized = true; // Mark as initialized so loadSaved doesn't override
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang_code', code);
    
    notifyListeners();
  }

  Future<void> loadSaved() async {
    if (_isInitialized) return; // Don't load if user already picked in splash
    
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('lang_code')) {
      _languageCode = prefs.getString('lang_code')!;
      print('LanguageProvider: Loaded saved code $_languageCode');
      _isInitialized = true;
      notifyListeners();
    }
  }
}
