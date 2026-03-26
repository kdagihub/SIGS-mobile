import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/file_saver.dart';
import '../../../core/theme.dart';
import '../../../data/repositories/athlete_repository.dart';
import '../../../providers/athlete_provider.dart';
import '../widgets/athlete_header.dart';
import '../widgets/licence_card.dart';
import '../widgets/empty_state.dart';

class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({super.key});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  final _repo = AthleteRepository();
  bool _downloadingFiche = false;
  String? _downloadingLicenceCode;

  Future<void> _downloadFicheAthlete(String msNius) async {
    setState(() => _downloadingFiche = true);
    try {
      final bytes = await _repo.downloadFicheAthlete(msNius);
      await saveAndOpenPdf(bytes, 'Fiche_Athlete_$msNius.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement : $e'),
            backgroundColor: SigsTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingFiche = false);
    }
  }

  Future<void> _downloadFicheLicence(
      String msNius, String licenceCode) async {
    setState(() => _downloadingLicenceCode = licenceCode);
    try {
      final bytes = await _repo.downloadFicheLicence(msNius, licenceCode);
      await saveAndOpenPdf(bytes, 'Fiche_Licence_$licenceCode.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement : $e'),
            backgroundColor: SigsTheme.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingLicenceCode = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(athleteProvider);
    final result = state.result;

    if (result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/search');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final athlete = result.athlete;
    final licences = result.licencesNumeriques;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(athleteProvider.notifier).reset();
            context.pop();
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_sigs.png', height: 28),
            const SizedBox(width: 8),
            const Text('Portail Athlète'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 32),
        children: [
          AthleteHeader(athlete: athlete),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: _downloadingFiche
                  ? null
                  : () => _downloadFicheAthlete(athlete.msNius),
              icon: _downloadingFiche
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded),
              label: Text(
                _downloadingFiche
                    ? 'Génération en cours...'
                    : 'Télécharger ma fiche athlète',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: SigsTheme.successGreen,
                side: const BorderSide(color: SigsTheme.successGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.credit_card, size: 20, color: SigsTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  '${licences.length} licence(s) numérique(s)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SigsTheme.primaryBlue,
                      ),
                ),
                if (result.totalLicences > licences.length) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${result.totalLicences} au total)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (licences.isEmpty)
            EmptyState(hasAnyLicence: result.hasAnyLicence)
          else
            ...licences.map(
              (licence) => LicenceCard(
                licence: licence,
                isDownloading: _downloadingLicenceCode == licence.code,
                onDownloadPdf: () =>
                    _downloadFicheLicence(athlete.msNius, licence.code),
              ),
            ),
        ],
      ),
    );
  }
}
