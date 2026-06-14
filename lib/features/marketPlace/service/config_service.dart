import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../models/config_model.dart';

class ConfigService {
  /// GET /admin/config
  Future<ConfigModel> getConfig() async {
    final data = await DioClient.get(ApiConstants.marketPlaceGetConfig);
    return ConfigModel.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH /admin/config
  Future<ConfigModel> updateConfig(Map<String, dynamic> fields) async {
    final data = await DioClient.patch(ApiConstants.marketPlaceUpdateConfig, data: fields);
    return ConfigModel.fromJson(data as Map<String, dynamic>);
  }
}