import 'package:dio/dio.dart';

import '../../models/territoire_models.dart';
import '../api_client.dart';

class TerritoireRepository {
  final Dio _dio = ApiClient.instance.dio;

  // ────────────── Départements ──────────────

  Future<PaginatedResponse<Departement>> fetchDepartements({
    int page = 1,
    int pageSize = 25,
    String? search,
    String? ordering,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (ordering != null) params['ordering'] = ordering;

    final resp = await _dio.get('/drdd/departements/', queryParameters: params);
    final data = resp.data as Map<String, dynamic>;
    return PaginatedResponse<Departement>(
      count: (data['count'] as num?)?.toInt() ?? 0,
      results: (data['results'] as List)
          .map((e) => Departement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<DepartementStats> fetchDepartementStats() async {
    final resp = await _dio.get('/drdd/departements/stats/');
    return DepartementStats.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Departement> createDepartement(Map<String, dynamic> data) async {
    final resp = await _dio.post('/drdd/departements/', data: data);
    return Departement.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Departement> updateDepartement(
      String code, Map<String, dynamic> data) async {
    final resp = await _dio.put('/drdd/departements/$code/', data: data);
    return Departement.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> patchDepartement(
      String code, Map<String, dynamic> data) async {
    await _dio.patch('/drdd/departements/$code/', data: data);
  }

  Future<void> deleteDepartement(String code) async {
    await _dio.delete('/drdd/departements/$code/');
  }

  // ────────────── Localités ──────────────

  Future<PaginatedResponse<Localite>> fetchLocalites({
    int page = 1,
    int pageSize = 25,
    String? search,
    String? ordering,
    String? directionDepartement,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (ordering != null) params['ordering'] = ordering;
    if (directionDepartement != null) {
      params['direction_departement'] = directionDepartement;
    }

    final resp = await _dio.get('/drdd/localites/', queryParameters: params);
    final data = resp.data as Map<String, dynamic>;
    return PaginatedResponse<Localite>(
      count: (data['count'] as num?)?.toInt() ?? 0,
      results: (data['results'] as List)
          .map((e) => Localite.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<LocaliteStats> fetchLocaliteStats() async {
    final resp = await _dio.get('/drdd/localites/stats/');
    return LocaliteStats.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<LocaliteFormOptions> fetchLocaliteFormOptions() async {
    final resp = await _dio.get('/drdd/localites/form-options/');
    return LocaliteFormOptions.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Localite> fetchLocaliteDetail(String code) async {
    final resp = await _dio.get('/drdd/localites/$code/');
    return Localite.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Localite> createLocalite(Map<String, dynamic> data) async {
    final resp = await _dio.post('/drdd/localites/', data: data);
    return Localite.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Localite> updateLocalite(
      String code, Map<String, dynamic> data) async {
    final resp = await _dio.put('/drdd/localites/$code/', data: data);
    return Localite.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteLocalite(String code) async {
    await _dio.delete('/drdd/localites/$code/');
  }
}
