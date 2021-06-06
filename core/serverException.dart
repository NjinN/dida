class ServerException implements Exception {
  int code = 500;
  String message = "";

  ServerException(String msg, {int code = 500}) {
    message = msg;
    this.code = code;
  }

  @override
  String toString() => 'ServerException: ${message}';
}

class ServerHaltException implements Exception{
  
}
