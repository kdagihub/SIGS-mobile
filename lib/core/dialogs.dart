import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart';
import '../providers/auth_provider.dart';

void showExitDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Quitter l\'application ?',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Votre session restera active.',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'Rester',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            exit(0);
          },
          child: const Text(
            'Quitter',
            style: TextStyle(color: SigsTheme.primaryBlue),
          ),
        ),
      ],
    ),
  );
}

void showLogoutDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Se déconnecter',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
      ),
      content: Text(
        'Votre session sera supprimée. Vous devrez vous reconnecter.',
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'Annuler',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            ref.read(authProvider.notifier).logout();
          },
          child: const Text(
            'Se déconnecter',
            style: TextStyle(color: SigsTheme.dangerRed),
          ),
        ),
      ],
    ),
  );
}

String userInitials(String name) {
  final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
}
