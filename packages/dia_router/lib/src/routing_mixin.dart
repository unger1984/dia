import 'package:dia/dia.dart';

/// Mixin to [Context]
/// extends default [Context] additional fields specified
/// for [Router]
mixin Routing on Context {
  Map<String, String> _params = {};
  final Map<String, String> _query = {};
  String routerPrefix = '';

  /// RegExp route params
  Map<String, String> get params => _params;

  /// RegExp route params setter
  set params(Map<String, String> params) => _params = params;

  /// Uri.params
  Map<String, String> get query => _query;
}
