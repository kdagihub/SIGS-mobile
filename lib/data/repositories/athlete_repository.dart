import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../models/athlete.dart';
import '../../models/licence.dart';
import '../api_client.dart';

class AthletePortailResult {
  final Athlete athlete;
  final List<Licence> licencesNumeriques;
  final int totalLicences;
  final bool hasAnyLicence;

  const AthletePortailResult({
    required this.athlete,
    required this.licencesNumeriques,
    required this.totalLicences,
    required this.hasAnyLicence,
  });
}

class AthleteRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<AthletePortailResult> fetchLicences(String msNius) async {
    final cleanNius = Uri.encodeComponent(msNius.trim().toUpperCase());
    final response = await _dio.get('/public/athlete/$cleanNius/licences/');
    final data = response.data as Map<String, dynamic>;

    if (data['found'] != true) {
      throw AthleteNotFoundException();
    }

    final athlete = Athlete.fromJson(data['athlete'] as Map<String, dynamic>);
    final licencesJson = data['licences_numeriques'] as List<dynamic>? ?? [];
    final licences = licencesJson
        .map((l) => Licence.fromJson(l as Map<String, dynamic>))
        .toList();

    return AthletePortailResult(
      athlete: athlete,
      licencesNumeriques: licences,
      totalLicences: data['total_licences'] as int? ?? 0,
      hasAnyLicence: data['has_any_licence'] as bool? ?? false,
    );
  }

  Future<Uint8List> downloadFicheAthlete(String msNius) async {
    final cleanNius = Uri.encodeComponent(msNius.trim().toUpperCase());
    final response = await _dio.get<List<int>>(
      '/public/athlete/$cleanNius/fiche-pdf/',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }

  Future<Uint8List> downloadFicheLicence(
      String msNius, String licenceCode) async {
    final cleanNius = Uri.encodeComponent(msNius.trim().toUpperCase());
    final cleanCode = Uri.encodeComponent(licenceCode);
    final response = await _dio.get<List<int>>(
      '/public/athlete/$cleanNius/licence/$cleanCode/fiche-pdf/',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data!);
  }
}

class AthleteNotFoundException implements Exception {
  @override
  String toString() => 'Aucun athlète trouvé avec ce MS-NIUS.';
}

class TooManyRequestsException implements Exception {
  @override
  String toString() => 'Trop de requêtes. Veuillez patienter quelques instants.';
}
