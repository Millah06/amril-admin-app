import 'package:flutter/foundation.dart';

import '../../../core/erorrs/app_exception.dart';
import '../models/config_model.dart';
import '../service/config_service.dart';


class ConfigProvider extends ChangeNotifier {
  ConfigProvider(this._service);

  final ConfigService _service;

  ConfigModel? _config;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  ConfigModel? get config => _config;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _config = await _service.getConfig();
    } on AppException catch (e) {
      _error = e.message;
    } catch (e) {
      // Catch-all so a parse/type error (e.g. a schema change) surfaces to the
      // UI instead of being swallowed and leaving a silent "No config loaded".
      _error = 'Failed to load config: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Saves only the fields that were changed.
  /// Returns error string or null on success.
  Future<String?> save(Map<String, dynamic> updatedFields) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      _config = await _service.updateConfig(updatedFields);
      return null;
    } on AppException catch (e) {
      _error = e.message;
      return e.message;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}