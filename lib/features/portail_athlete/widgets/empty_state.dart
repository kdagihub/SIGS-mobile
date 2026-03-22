import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class EmptyState extends StatelessWidget {
  final bool hasAnyLicence;

  const EmptyState({super.key, required this.hasAnyLicence});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              hasAnyLicence ? Icons.credit_card_off : Icons.search_off,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              hasAnyLicence
                  ? 'Aucune licence numérique'
                  : 'Aucune licence trouvée',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: SigsTheme.primaryBlue,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              hasAnyLicence
                  ? 'Vous possédez des licences, mais aucune avec carte numérique. '
                      'Contactez votre fédération pour plus d\'informations.'
                  : 'Aucune licence n\'est enregistrée pour ce matricule. '
                      'Si vous pensez qu\'il s\'agit d\'une erreur, '
                      'veuillez contacter votre fédération.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
