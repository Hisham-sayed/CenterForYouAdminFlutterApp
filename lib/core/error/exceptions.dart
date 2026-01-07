class ServerException implements Exception {
  final int statusCode;
  final dynamic responseData;

  ServerException({required this.statusCode, this.responseData});

  @override
  String toString() {
    return 'ServerException: $statusCode, $responseData';
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'Network Error']);
}
