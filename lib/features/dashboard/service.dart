import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import 'model.dart';

class DashboardService {
  Future<DashboardStats> getStats() async {
    final data = await DioClient.get(ApiConstants.adminStats);

    // await DioClient.get('/admin/migrate');
    return DashboardStats.fromJson(data as Map<String, dynamic>);

  }
}