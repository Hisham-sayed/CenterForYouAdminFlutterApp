import 'package:flutter/foundation.dart';
import 'exceptions.dart';
import 'failures.dart';

class ErrorHandler {
  static Failure handle(Object error) {
    if (error is ServerException) {
      return _handleServerException(error);
    } else if (error is NetworkException) {
      return NetworkFailure('Unable to connect to the server. Please check your internet connection.');
    } else {
      debugPrint('Unknown Error: $error');
      return const ServerFailure('Something went wrong. Please try again.');
    }
  }

  static Failure _handleServerException(ServerException error) {
    // Log the actual error for debugging
    debugPrint('Server Exception: ${error.statusCode} - ${error.responseData}');

    try {
      final statusCode = error.statusCode;
      final data = error.responseData;

      // Check for structured validation errors (400)
      if (statusCode == 400 && data is Map<String, dynamic>) {
        if (data.containsKey('validationErrors')) {
          final rawErrors = data['validationErrors'];
          final Map<String, String> errors = {};
          
          if (rawErrors is Map) {
            rawErrors.forEach((key, value) {
              errors[key.toString()] = value.toString();
            });
            return ValidationFailure(
              data['title'] ?? 'One or more validation errors occurred.',
              errors,
            );
          }
        }
        
        // Handle other 400 structures if necessary
         if (data.containsKey('errors')) {
             // Some APIs return "errors": { "Field": ["Msg"] }
             final rawErrors = data['errors'];
             if(rawErrors is Map) {
                final Map<String, String> errors = {};
                 rawErrors.forEach((key, value) {
                   if (value is List && value.isNotEmpty) {
                     errors[key.toString()] = value.first.toString();
                   } else {
                      errors[key.toString()] = value.toString();
                   }
                });
                 return ValidationFailure('Validation Error', errors);
             }
         }
      }

      // Handle common status codes
      switch (statusCode) {
        case 400:
          return ServerFailure(data is Map ? (data['message'] ?? 'Bad Request') : 'Bad Request');
        case 401:
          return const ServerFailure('Session expired. Please log in again.');
        case 403:
          return const ServerFailure('You do not have permission to access this resource.');
        case 404:
          return const ServerFailure('Resource not found.');
        case 500:
          return const ServerFailure('Internal server error. Please try again later.');
        case 503:
          return const ServerFailure('Service unavailable. Please try again later.');
        default:
          return ServerFailure('Request failed with status: $statusCode');
      }
    } catch (e) {
      return const ServerFailure('Failed to process server response.');
    }
  }
}
