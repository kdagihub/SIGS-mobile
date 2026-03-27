import 'package:dio/dio.dart';

import '../../models/association_models.dart';
import '../../models/territoire_models.dart';
import '../api_client.dart';

class AssociationRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<PaginatedResponse<Association>> fetchAssociations({
    int page = 1,
    int pageSize = 25,
    String? search,
    String? ordering,
    String? estAgree,
    String? federation,
    String? localite,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (ordering != null) params['ordering'] = ordering;
    if (estAgree != null) params['est_agree'] = estAgree;
    if (federation != null) params['federation'] = federation;
    if (localite != null) params['localite'] = localite;

    final resp =
        await _dio.get('/drdd/associations/', queryParameters: params);
    final data = resp.data as Map<String, dynamic>;
    return PaginatedResponse<Association>(
      count: (data['count'] as num?)?.toInt() ?? 0,
      results: (data['results'] as List)
          .map((e) => Association.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<AssociationStats> fetchStats() async {
    final resp = await _dio.get('/drdd/associations/stats/');
    return AssociationStats.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<AssociationFormOptions> fetchFormOptions() async {
    final resp = await _dio.get('/drdd/associations/form-options/');
    return AssociationFormOptions.fromJson(
        resp.data as Map<String, dynamic>);
  }

  Future<Association> fetchDetail(String code) async {
    final resp = await _dio.get('/drdd/associations/$code/');
    return Association.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Association> create(
    Map<String, dynamic> data, {
    String? logoPath,
    String? recepisePath,
    String? agrementPath,
  }) async {
    final body = await _buildBody(data,
        logoPath: logoPath,
        recepisePath: recepisePath,
        agrementPath: agrementPath);
    final resp = await _dio.post('/drdd/associations/', data: body);
    return Association.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Association> update(
    String code,
    Map<String, dynamic> data, {
    String? logoPath,
    String? recepisePath,
    String? agrementPath,
  }) async {
    final body = await _buildBody(data,
        logoPath: logoPath,
        recepisePath: recepisePath,
        agrementPath: agrementPath);
    final resp =
        await _dio.patch('/drdd/associations/$code/', data: body);
    return Association.fromJson(resp.data as Map<String, dynamic>);
  }

  /// PATCH léger pour les actions groupées (ex: est_agree)
  Future<void> patchField(String code, Map<String, dynamic> data) async {
    await _dio.patch('/drdd/associations/$code/', data: data);
  }

  Future<void> delete(String code) async {
    await _dio.delete('/drdd/associations/$code/');
  }

  Future<dynamic> _buildBody(
    Map<String, dynamic> data, {
    String? logoPath,
    String? recepisePath,
    String? agrementPath,
  }) async {
    if (logoPath == null && recepisePath == null && agrementPath == null) {
      return data;
    }
    final map = <String, dynamic>{...data};
    if (logoPath != null) {
      map['logo_as'] = await MultipartFile.fromFile(
        logoPath,
        filename: logoPath.split('/').last,
      );
    }
    if (recepisePath != null) {
      map['recepisse_as'] = await MultipartFile.fromFile(
        recepisePath,
        filename: recepisePath.split('/').last,
      );
    }
    if (agrementPath != null) {
      map['agrement_as'] = await MultipartFile.fromFile(
        agrementPath,
        filename: agrementPath.split('/').last,
      );
    }
    return FormData.fromMap(map);
  }
}
