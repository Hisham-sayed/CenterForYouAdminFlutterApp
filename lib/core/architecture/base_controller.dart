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
  bool get hasValidationErrors => _validationErrors != null && _validationErrors!.isNotEmpty;

  /// Returns a list of formatted validation error strings in the format:
  /// "- Field: Error message"
  List<String> get formattedValidationErrorsList {
    if (_validationErrors == null) return [];
    
    return _validationErrors!.entries.map((e) {
      // Clean up key: "VideoLink" -> "Video Link" (Simple camel case split if needed, 
      // but for now we assume keys are decent).
      // We can do a basic split by capital letters if strictly needed, 
      // but usually keys like "VideoLink" are readable enough or we rely on API.
      
      // Clean up value: .NET Core often returns "'Field' must not be empty."
      // We stripping the redundant field name from the start if present to avoid:
      // "- Title: 'Title' must not be empty." -> "- Title: must not be empty." 
      // OR we just keep it as is. 
      // The user prompt example: "- Title: This field cannot be empty."
      // ensuring we follow the requested structure.
      
      String field = e.key;
      String message = e.value;
      
      return "- $field: $message";
    }).toList();
  }
  
  /// Returns a single string summary of validation errors.
  String get validationSummary {
    if (!hasValidationErrors) return errorMessage ?? 'Unknown Error';
    return formattedValidationErrorsList.join('\n');
  }

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
