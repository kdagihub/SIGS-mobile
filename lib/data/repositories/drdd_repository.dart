import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../models/drdd_models.dart';
import '../api_client.dart';

class DrddRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<DrddDashboardData> fetchDashboard() async {
    final response = await _dio.get('/drdd/dashboard/');
    final data = response.data as Map<String, dynamic>;

    debugPrint('[DRDD-repo] clés reçues: ${data.keys.toList()}');
    final evtList = data['evenements_recents'];
    final actList = data['activites_recentes'];
    debugPrint('[DRDD-repo] evenements_recents type=${evtList.runtimeType}, '
        'len=${evtList is List ? evtList.length : "N/A"}');
    debugPrint('[DRDD-repo] activites_recentes type=${actList.runtimeType}, '
        'len=${actList is List ? actList.length : "N/A"}');

    return DrddDashboardData(
      territoire: DrddTerritoire.fromJson(
        data['territoire'] as Map<String, dynamic>,
      ),
      stats: DrddStats.fromJson(
        data['stats'] as Map<String, dynamic>,
      ),
      evenementsRecents: evtList is List
          ? evtList
              .map((e) =>
                  DrddEvenementRecent.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      activitesRecentes: actList is List
          ? actList
              .map((e) =>
                  DrddActiviteRecente.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class DrddDashboardData {
  final DrddTerritoire territoire;
  final DrddStats stats;
  final List<DrddEvenementRecent> evenementsRecents;
  final List<DrddActiviteRecente> activitesRecentes;

  const DrddDashboardData({
    required this.territoire,
    required this.stats,
    required this.evenementsRecents,
    required this.activitesRecentes,
  });
}
