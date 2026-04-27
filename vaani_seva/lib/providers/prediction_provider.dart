import 'package:flutter/foundation.dart';
import '../models/prediction_request.dart';
import '../models/prediction_response.dart';
import '../services/api_service.dart';
import '../services/local_fallback.dart';

enum PredictionStatus { idle, loading, success, error }

class PredictionProvider extends ChangeNotifier {
  PredictionStatus _status = PredictionStatus.idle;
  PredictionResponse? _result;
  PredictionRequest? _request;
  String _errorMessage = '';
  bool _usedFallback = false;

  PredictionStatus get status => _status;
  PredictionResponse? get result => _result;
  PredictionRequest? get request => _request;
  String get errorMessage => _errorMessage;
  bool get usedFallback => _usedFallback;

  Future<void> predict(PredictionRequest request) async {
    _status = PredictionStatus.loading;
    _usedFallback = false;
    _result = null;
    _request = request;
    notifyListeners();

    final apiResult = await ApiService.predict(request);

    if (apiResult != null) {
      _result = apiResult;
      _status = PredictionStatus.success;
    } else {
      _result = LocalFallback.evaluate(request);
      _usedFallback = true;
      _status = PredictionStatus.success;
    }

    notifyListeners();
  }

  void reset() {
    _status = PredictionStatus.idle;
    _result = null;
    _request = null;
    _errorMessage = '';
    _usedFallback = false;
    notifyListeners();
  }
}
