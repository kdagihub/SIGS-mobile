import 'package:dio/dio.dart';

import '../../models/evenement_models.dart';
import '../../models/territoire_models.dart';
import '../api_client.dart';

class EvenementRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<PaginatedResponse<Evenement>> fetchEvenements({
    int page = 1,
    int pageSize = 25,
    String? search,
    String? ordering,
    String? typeEvenement,
    String? discipline,
    String? federation,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (ordering != null) params['ordering'] = ordering;
    if (typeEvenement != null) params['type_evenement'] = typeEvenement;
    if (discipline != null) params['discipline'] = discipline;
    if (federation != null) params['federation'] = federation;

    final resp =
        await _dio.get('/drdd/evenements/', queryParameters: params);
    final data = resp.data as Map<String, dynamic>;
    return PaginatedResponse<Evenement>(
      count: (data['count'] as num?)?.toInt() ?? 0,
      results: (data['results'] as List)
          .map((e) => Evenement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<EvenementStats> fetchStats() async {
    final resp = await _dio.get('/drdd/evenements/stats/');
    return EvenementStats.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<EvenementFormOptions> fetchFormOptions() async {
    final resp = await _dio.get('/drdd/evenements/form-options/');
    return EvenementFormOptions.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Evenement> fetchDetail(String code) async {
    final resp = await _dio.get('/drdd/evenements/$code/');
    return Evenement.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Evenement> create(
    Map<String, dynamic> data, {
    String? imagePath,
    String? documentPath,
  }) async {
    final body = await _buildBody(data,
        imagePath: imagePath, documentPath: documentPath);
    final resp = await _dio.post('/drdd/evenements/', data: body);
    return Evenement.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Evenement> update(
    String code,
    Map<String, dynamic> data, {
    String? imagePath,
    String? documentPath,
  }) async {
    final body = await _buildBody(data,
        imagePath: imagePath, documentPath: documentPath);
    final resp = await _dio.patch('/drdd/evenements/$code/', data: body);
    return Evenement.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> delete(String code) async {
    await _dio.delete('/drdd/evenements/$code/');
  }

  /// Suppression groupée (séquentielle côté client)
  Future<List<String>> bulkDelete(List<String> codes) async {
    final errors = <String>[];
    for (final code in codes) {
      try {
        await _dio.delete('/drdd/evenements/$code/');
      } catch (_) {
        errors.add(code);
      }
    }
    return errors;
  }

  Future<dynamic> _buildBody(
    Map<String, dynamic> data, {
    String? imagePath,
    String? documentPath,
  }) async {
    if (imagePath == null && documentPath == null) return data;

    final map = <String, dynamic>{...data};
    if (imagePath != null) {
      map['image_evenement'] = await MultipartFile.fromFile(
        imagePath,
        filename: imagePath.split('/').last,
      );
    }
    if (documentPath != null) {
      map['document_annexe'] = await MultipartFile.fromFile(
        documentPath,
        filename: documentPath.split('/').last,
      );
    }
    return FormData.fromMap(map);
  }
}
