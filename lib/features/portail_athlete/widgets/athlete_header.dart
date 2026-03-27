import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme.dart';
import '../../../models/athlete.dart';

class AthleteHeader extends StatelessWidget {
  final Athlete athlete;

  const AthleteHeader({super.key, required this.athlete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 16),
            Text(
              athlete.fullName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: SigsTheme.primaryBlue,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _chip(context, Icons.badge_outlined, athlete.msNius),
                if (athlete.federation.displayName.isNotEmpty)
                  _chip(
                    context,
                    Icons.shield_outlined,
                    athlete.federation.displayName,
                  ),
                if (athlete.club != null &&
                    athlete.club!.displayName.isNotEmpty)
                  _chip(
                    context,
                    Icons.groups_outlined,
                    athlete.club!.displayName,
                  ),
                if (athlete.discipline != null &&
                    athlete.discipline!.isNotEmpty)
                  _chip(
                    context,
                    Icons.sports_outlined,
                    athlete.discipline!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (athlete.photo != null && athlete.photo!.isNotEmpty) {
      return CircleAvatar(
        radius: 44,
        backgroundColor: SigsTheme.primaryOrange.withValues(alpha: 0.15),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: athlete.photo!,
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            placeholder: (_, __) => _initialsAvatar(),
            errorWidget: (_, __, ___) => _initialsAvatar(),
          ),
        ),
      );
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    return CircleAvatar(
      radius: 44,
      backgroundColor: SigsTheme.primaryOrange,
      child: Text(
        athlete.initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: SigsTheme.primaryBlue),
      label: Text(
        label,
        style: TextStyle(
          color: SigsTheme.primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
