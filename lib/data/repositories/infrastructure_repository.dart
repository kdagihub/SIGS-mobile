import 'package:dio/dio.dart';

import '../../models/infrastructure_models.dart';
import '../../models/territoire_models.dart';
import '../api_client.dart';

class InfrastructureRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<PaginatedResponse<Infrastructure>> fetchInfrastructures({
    int page = 1,
    int pageSize = 25,
    String? search,
    String? ordering,
    String? etatInfrastructure,
    String? localite,
    String? typeInfrastructure,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (ordering != null) params['ordering'] = ordering;
    if (etatInfrastructure != null) {
      params['etat_infrastructure'] = etatInfrastructure;
    }
    if (localite != null) params['localite'] = localite;
    if (typeInfrastructure != null) {
      params['type_infrastructure'] = typeInfrastructure;
    }

    final resp =
        await _dio.get('/drdd/infrastructures/', queryParameters: params);
    final data = resp.data as Map<String, dynamic>;
    return PaginatedResponse<Infrastructure>(
      count: (data['count'] as num?)?.toInt() ?? 0,
      results: (data['results'] as List)
          .map((e) => Infrastructure.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<InfrastructureStats> fetchStats() async {
    final resp = await _dio.get('/drdd/infrastructures/stats/');
    return InfrastructureStats.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<InfrastructureFormOptions> fetchFormOptions() async {
    final resp = await _dio.get('/drdd/infrastructures/form-options/');
    return InfrastructureFormOptions.fromJson(
        resp.data as Map<String, dynamic>);
  }

  Future<Infrastructure> fetchDetail(String code) async {
    final resp = await _dio.get('/drdd/infrastructures/$code/');
    return Infrastructure.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Infrastructure> create(
    Map<String, dynamic> data, {
    String? photoPath,
  }) async {
    final body = await _buildBody(data, photoPath: photoPath);
    final resp = await _dio.post('/drdd/infrastructures/', data: body);
    return Infrastructure.fromJson(resp.data as Map<String, dynamic>);
  }

  /// PATCH pour n'envoyer que les champs modifiés (et préserver la photo si inchangée)
  Future<Infrastructure> update(
    String code,
    Map<String, dynamic> data, {
    String? photoPath,
  }) async {
    final body = await _buildBody(data, photoPath: photoPath);
    final resp =
        await _dio.patch('/drdd/infrastructures/$code/', data: body);
    return Infrastructure.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> delete(String code) async {
    await _dio.delete('/drdd/infrastructures/$code/');
  }

  /// Construit le body : JSON simple si pas de photo, FormData sinon.
  Future<dynamic> _buildBody(
    Map<String, dynamic> data, {
    String? photoPath,
  }) async {
    if (photoPath == null) return data;

    final map = <String, dynamic>{...data};
    map['photo_is'] = await MultipartFile.fromFile(
      photoPath,
      filename: photoPath.split('/').last,
    );
    return FormData.fromMap(map);
  }
}
