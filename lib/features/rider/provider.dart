import 'package:flutter/foundation.dart';
import '../../core/network/dio_client.dart';
import 'model.dart';

class RiderProvider extends ChangeNotifier {
  bool loading = false;
  String? error;

  List<RiderApplication> applications = [];
  List<Rider> riders = [];

  // Load pending applications
  Future<void> loadApplications({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }

    try {
      final response = await DioClient.get('/admin/rider/applications');
      final data = response['applications'] as List;
      applications = data.map((e) => RiderApplication.fromJson(e)).toList();
      error = null;
    } catch (e) {
      error = e.toString();
      if (kDebugMode) print('❌ Load applications error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Load active riders
  Future<void> loadRiders({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }

    try {
      final response = await DioClient.get('/admin/rider/list');
      final data = response['riders'] as List;
      riders = data.map((e) => Rider.fromJson(e)).toList();
      error = null;
    } catch (e) {
      error = e.toString();
      print('❌ Load riders error: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // Approve application
  Future<void> approve(String applicationId) async {
    try {
      await DioClient.post('/admin/rider/applications/$applicationId/approve');
      await loadApplications(silent: true);
    } catch (e) {
      error = e.toString();
      if (kDebugMode) print('❌ Approve error: $e');
      rethrow;
    }
  }

  // Reject application
  Future<void> reject(String applicationId, String reason) async {
    try {
      await DioClient.post('/admin/rider/applications/$applicationId/reject', data: {
        'reason': reason,
      });
      await loadApplications(silent: true);
    } catch (e) {
      error = e.toString();
      if (kDebugMode) print('❌ Reject error: $e');
      rethrow;
    }
  }

  // Suspend rider
  Future<void> suspend(String riderId, String reason) async {
    try {
      await DioClient.post('/admin/rider/$riderId/suspend', data: {
        'reason': reason,
      });
      await loadRiders(silent: true);
    } catch (e) {
      error = e.toString();
      if (kDebugMode) print('❌ Suspend error: $e');
      rethrow;
    }
  }
}
