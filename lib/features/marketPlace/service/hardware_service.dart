import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/utils/upload_helpers.dart';
import '../models/hardware_model.dart';

/// A single page of cursor-paginated orders.
class HwOrderPage {
  final List<HwOrder> items;
  final String? nextCursor;
  final bool hasMore;
  HwOrderPage({required this.items, required this.nextCursor, required this.hasMore});
}

class HardwareService {
  // ── Products ──
  Future<List<HwProduct>> getProducts() async {
    final data = await DioClient.get(ApiConstants.hardwareProducts);
    return ((data['products'] as List?) ?? [])
        .map((e) => HwProduct.fromJson(e))
        .toList();
  }

  /// Creates a product and returns the parsed row (needed so images can be
  /// uploaded to the new id straight after).
  Future<HwProduct> createProduct(Map<String, dynamic> body) async {
    final data = await DioClient.post(ApiConstants.hardwareCreateProduct, data: body);
    return HwProduct.fromJson(data as Map<String, dynamic>);
  }

  Future<HwProduct> updateProduct(String id, Map<String, dynamic> body) async {
    final data =
        await DioClient.patch(ApiConstants.hardwareUpdateProduct(id), data: body);
    return HwProduct.fromJson(data as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String id) =>
      DioClient.delete(ApiConstants.hardwareDeleteProduct(id));

  /// Uploads [images] (multi) to the product and returns the full, updated
  /// images list from the server. Web-safe via [dioMultipartFromXFile].
  Future<List<String>> uploadProductImages(String id, List<XFile> images) async {
    final parts = <MultipartFile>[];
    for (final x in images) {
      parts.add(await dioMultipartFromXFile(x));
    }
    final form = FormData();
    for (final p in parts) {
      form.files.add(MapEntry('images', p));
    }
    final data =
        await DioClient.postMultipart(ApiConstants.hardwareProductImages(id), form);
    return ((data['images'] as List?) ?? []).map((e) => e.toString()).toList();
  }

  // ── Batches ──
  Future<List<HwBatch>> getBatches() async {
    final data = await DioClient.get(ApiConstants.hardwareBatches);
    return ((data['batches'] as List?) ?? [])
        .map((e) => HwBatch.fromJson(e))
        .toList();
  }

  Future<void> createBatch(Map<String, dynamic> body) =>
      DioClient.post(ApiConstants.hardwareCreateBatch, data: body);

  Future<void> updateBatch(String id, Map<String, dynamic> body) =>
      DioClient.patch(ApiConstants.hardwareUpdateBatch(id), data: body);

  // ── Orders (cursor-paginated) ──
  Future<HwOrderPage> getOrders({String? cursor, String? status, int limit = 20}) async {
    final data = await DioClient.get(
      ApiConstants.hardwareOrders,
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
        if (status != null) 'status': status,
      },
    );
    final list = (data['data'] as List?) ?? (data['orders'] as List?) ?? [];
    final meta = (data['meta'] as Map?) ?? const {};
    return HwOrderPage(
      items: list.map((e) => HwOrder.fromJson(e)).toList(),
      nextCursor: meta['nextCursor'] as String?,
      hasMore: meta['hasMore'] as bool? ?? false,
    );
  }

  Future<void> updateOrder(String id, Map<String, dynamic> body) =>
      DioClient.patch(ApiConstants.hardwareUpdateOrder(id), data: body);

  /// Member orders of one batch (§3 "View orders (N)") — same envelope shape
  /// as [getOrders], backed by GET /admin/hardware/batch/:id/orders.
  Future<HwOrderPage> getBatchOrders(String batchId,
      {String? cursor, int limit = 20}) async {
    final data = await DioClient.get(
      ApiConstants.hardwareBatchOrders(batchId),
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    final list = (data['data'] as List?) ?? (data['orders'] as List?) ?? [];
    final meta = (data['meta'] as Map?) ?? const {};
    return HwOrderPage(
      items: list.map((e) => HwOrder.fromJson(e)).toList(),
      nextCursor: meta['nextCursor'] as String?,
      hasMore: meta['hasMore'] as bool? ?? false,
    );
  }
}
