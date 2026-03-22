import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme.dart';
import '../../../models/licence.dart';

class LicenceCard extends StatelessWidget {
  final Licence licence;
  final bool isDownloading;
  final VoidCallback? onDownloadPdf;

  const LicenceCard({
    super.key,
    required this.licence,
    this.isDownloading = false,
    this.onDownloadPdf,
  });

  @override
  Widget build(BuildContext context) {
    final statusConfig = _getStatusConfig(licence.statut);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          // Header with federation + status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusConfig.color.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                _buildFederationLogo(),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    licence.federation.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusConfig.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    licence.statutDisplay ?? licence.statut,
                    style: TextStyle(
                      color: statusConfig.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Licence number
                Text(
                  licence.numero ?? licence.code,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                        color: SigsTheme.primaryBlue,
                      ),
                ),
                const SizedBox(height: 12),
                _infoRow(
                  context,
                  'Type',
                  licence.typeLicenceDisplay,
                  'Catégorie',
                  licence.categorieDisplay,
                ),
                const SizedBox(height: 8),
                _infoRow(
                  context,
                  'Saison',
                  licence.anneeSportiveDisplay,
                  'Format',
                  licence.formatDisplay ?? '',
                ),
              ],
            ),
          ),

          // Footer with dates + download
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _dateChip(
                        context,
                        'Délivrance',
                        _formatDate(licence.dateDelivrance),
                        Colors.grey.shade700,
                      ),
                      const SizedBox(width: 12),
                      _dateChip(
                        context,
                        'Expiration',
                        _formatDate(licence.dateExpiration),
                        licence.estExpiree
                            ? SigsTheme.dangerRed
                            : Colors.grey.shade700,
                      ),
                    ],
                  ),
                ),
                if (onDownloadPdf != null)
                  IconButton(
                    onPressed: isDownloading ? null : onDownloadPdf,
                    icon: isDownloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    tooltip: 'Télécharger la fiche licence',
                    color: SigsTheme.primaryOrange,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFederationLogo() {
    final logoUrl = licence.federation.logo;
    if (logoUrl != null && logoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: logoUrl,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          errorWidget: (_, __, ___) => _defaultFedIcon(),
        ),
      );
    }
    return _defaultFedIcon();
  }

  Widget _defaultFedIcon() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: SigsTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.shield, size: 18, color: SigsTheme.primaryBlue),
    );
  }

  Widget _infoRow(
    BuildContext context,
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    return Row(
      children: [
        Expanded(child: _infoItem(context, label1, value1)),
        const SizedBox(width: 8),
        Expanded(child: _infoItem(context, label2, value2)),
      ],
    );
  }

  Widget _infoItem(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isNotEmpty ? value : '—',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _dateChip(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.3,
          ),
        ),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '—';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  static _StatusConfig _getStatusConfig(String statut) {
    switch (statut.toUpperCase()) {
      case 'ACTIVE':
        return _StatusConfig(SigsTheme.successGreen);
      case 'EN_PRODUCTION':
        return _StatusConfig(SigsTheme.infoCyan);
      case 'SUSPENDUE':
        return _StatusConfig(SigsTheme.warningAmber);
      case 'EXPIREE':
        return _StatusConfig(SigsTheme.dangerRed);
      case 'ANNULEE':
      case 'REVOQUEE':
        return _StatusConfig(Colors.grey);
      default:
        return _StatusConfig(Colors.grey.shade600);
    }
  }
}

class _StatusConfig {
  final Color color;
  const _StatusConfig(this.color);
}
