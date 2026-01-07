import 'package:flutter/foundation.dart';
import '../error/error_handler.dart';
import '../error/failures.dart';

/// A base controller that handles loading state, error messages, and validation errors.
/// All feature controllers should extend this class to ensure consistent behavior.
abstract class BaseController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, String>? _validationErrors;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, String>? get validationErrors => _validationErrors;
  bool get hasError => _errorMessage != null;

  /// Executes a [action] safely, handling loading state and errors automatically.
  /// 
  /// [action] is the async function to execute.
  /// If an error occurs, it is processed by [ErrorHandler].
  Future<bool> safeCall(Future<dynamic> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    _validationErrors = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (e) {
      debugPrint('Controller Error: $e');
      final failure = ErrorHandler.handle(e);
      _errorMessage = failure.message;
      
      if (failure is ValidationFailure) {
        _validationErrors = failure.errors;
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearErrors() {
    _errorMessage = null;
    _validationErrors = null;
    notifyListeners();
  }
}
