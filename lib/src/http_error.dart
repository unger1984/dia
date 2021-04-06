import 'dart:core';

/// HttpError class
/// Contain information about http error
/// [status] - response code
/// [message] - text message of code
/// [error] - Error objects thrown in the case of a program failure
/// [stackTrace] - [StackTrace] by all stack trace objects
class HttpError extends Error {
  final int _status;
  late String _message;
  late Error? _error;
  late final StackTrace? _stackTrace;

  /// Create [HttpError] object
  /// [status] - response code
  ///
  /// Optional parameters
  /// [message] - text message of code
  /// [error] - Error objects thrown in the case of a program failure
  /// [stackTrace] - [StackTrace] by all stack trace objects
  HttpError(this._status,
      {String? message, StackTrace? stackTrace, Error? error})
      : assert(_status >= 400 && _status <= 600,
            'The status should be an error code: 400-600') {
    if (message != null) {
      _message = message;
    } else {
      _message = _codes[_status] ?? 'Unknown error';
    }
    _stackTrace = stackTrace;
    _error = error;
  }

  /// text message of code
  String get message => _message;

  /// response code
  int get status => _status;

  /// Error objects thrown in the case of a program failure
  Error? get error => _error;

  /// [StackTrace] by all stack trace objects
  StackTrace? get stackTrace => _stackTrace;

  /// Generate default HTML for this HTTP error
  /// without fail contains information about [status] and [message]
  /// additional, can contains information about [error] and [stackTrace]
  String get defaultBody {
    var res = '''<html lang="en">
    <head>
      <title>$_status $_message</title>
    </head>
    <body>
      <h1>$_status $_message</h1>''';
    if (_error != null) {
      res += '<h2>$error</h2>';
    }
    if (_stackTrace != null) {
      res += '''<h3>StackTrace</h3>
      <p>
      ''';
      final stack = _stackTrace.toString().split('\n');
      for (var index = 0; index < stack.length; index++) {
        final str = stack[index];
        res += '$str<br/>';
      }

      res += '</p>';
    }

    res += '''
    </body>
    </html>''';
    return res;
  }
}

/// http errors statuses and messages
const _codes = <int, String>{
  100: 'Continue',
  101: 'Switching Protocols',
  102: 'Processing',
  103: 'Early Hints',
  200: 'OK',
  201: 'Created',
  202: 'Accepted',
  203: 'Non-Authoritative Information',
  204: 'No Content',
  205: 'Reset Content',
  206: 'Partial Content',
  207: 'Multi-Status',
  208: 'Already Reported',
  226: 'IM Used',
  300: 'Multiple Choices',
  301: 'Moved Permanently',
  302: 'Found',
  303: 'See Other',
  304: 'Not Modified',
  305: 'Use Proxy',
  307: 'Temporary Redirect',
  308: 'Permanent Redirect',
  400: 'Bad Request',
  401: 'Unauthorized',
  402: 'Payment Required',
  403: 'Forbidden',
  404: 'Not Found',
  405: 'Method Not Allowed',
  406: 'Not Acceptable',
  407: 'Proxy Authentication Required',
  408: 'Request Timeout',
  409: 'Conflict',
  410: 'Gone',
  411: 'Length Required',
  412: 'Precondition Failed',
  413: 'Payload Too Large',
  414: 'URI Too Long',
  415: 'Unsupported Media Type',
  416: 'Range Not Satisfiable',
  417: 'Expectation Failed',
  418: "I'm a Teapot",
  421: 'Misdirected Request',
  422: 'Unprocessable Entity',
  423: 'Locked',
  424: 'Failed Dependency',
  425: 'Too Early',
  426: 'Upgrade Required',
  428: 'Precondition Required',
  429: 'Too Many Requests',
  431: 'Request Header Fields Too Large',
  451: 'Unavailable For Legal Reasons',
  500: 'Internal Server Error',
  501: 'Not Implemented',
  502: 'Bad Gateway',
  503: 'Service Unavailable',
  504: 'Gateway Timeout',
  505: 'HTTP Version Not Supported',
  506: 'Variant Also Negotiates',
  507: 'Insufficient Storage',
  508: 'Loop Detected',
  509: 'Bandwidth Limit Exceeded',
  510: 'Not Extended',
  511: 'Network Authentication Required'
};
