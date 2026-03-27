import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 1;
  bool _loading = false;
  String? _globalError;

  // Step 1
  String _userType = '';
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _entityCodeController = TextEditingController();

  // Step 2
  String _resetToken = '';
  int _tokenExpiresIn = 900;
  Timer? _countdownTimer;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _pinController.dispose();
    _entityCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  int get _passwordScore {
    final p = _newPasswordController.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(p)) score++;
    return score;
  }

  String get _strengthText {
    switch (_passwordScore) {
      case 0:
        return '';
      case 1:
      case 2:
        return 'Faible';
      case 3:
        return 'Moyen';
      case 4:
        return 'Bon';
      default:
        return 'Très fort';
    }
  }

  Color get _strengthColor {
    switch (_passwordScore) {
      case 1:
      case 2:
        return SigsTheme.dangerRed;
      case 3:
        return SigsTheme.warningAmber;
      case 4:
        return SigsTheme.primaryOrange;
      case 5:
        return SigsTheme.successGreen;
      default:
        return Colors.grey.shade300;
    }
  }

  double get _strengthWidth {
    if (_passwordScore == 0) return 0;
    return _passwordScore / 5;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _tokenExpiresIn--;
        if (_tokenExpiresIn <= 0) {
          _countdownTimer?.cancel();
          _globalError =
              'Session expirée. Veuillez recommencer la procédure.';
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) setState(() => _currentStep = 1);
          });
        }
      });
    });
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is String) return data;
    if (data is Map) {
      if (data['detail'] != null) return data['detail'].toString();
      if (data['non_field_errors'] is List &&
          (data['non_field_errors'] as List).isNotEmpty) {
        return data['non_field_errors'][0].toString();
      }
      final values = data.values.where((v) => v is List && v.isNotEmpty);
      if (values.isNotEmpty) return values.first[0].toString();
    }
    return 'Erreur serveur. Veuillez réessayer.';
  }

  Future<void> _verifyCredentials() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _globalError = null;
    });

    try {
      late final ({String token, int expiresIn}) result;

      if (_userType == 'entity') {
        result = await _repo.verifyResetCredentials(
          email: _emailController.text.trim(),
          entityCode: _entityCodeController.text.trim(),
          pin: _pinController.text.trim(),
        );
      } else {
        result = await _repo.verifyAdminResetCredentials(
          email: _emailController.text.trim(),
          pin: _pinController.text.trim(),
        );
      }

      _resetToken = result.token;
      _tokenExpiresIn = result.expiresIn;
      setState(() => _currentStep = 2);
      _startCountdown();
    } on DioException catch (e) {
      setState(() {
        if (e.response?.statusCode == 429) {
          _globalError = 'Trop de tentatives. Veuillez patienter.';
        } else {
          _globalError = _extractError(e);
        }
      });
    } catch (e) {
      setState(() => _globalError = 'Erreur inattendue. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _globalError = null;
    });

    try {
      await _repo.resetPasswordWithToken(
        token: _resetToken,
        newPassword: _newPasswordController.text,
        confirmNewPassword: _confirmPasswordController.text,
      );
      _countdownTimer?.cancel();
      setState(() => _currentStep = 3);
    } on DioException catch (e) {
      final msg = _extractError(e);
      setState(() => _globalError = msg);
      if (msg.contains('expiré') || msg.contains('invalide')) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _currentStep = 1;
              _resetToken = '';
            });
          }
        });
      }
    } catch (_) {
      setState(() => _globalError = 'Erreur inattendue. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 24),
              _buildStepper(),
              const SizedBox(height: 24),
              _buildTitle(),
              const SizedBox(height: 24),
              if (_currentStep == 1) _buildStep1(),
              if (_currentStep == 2) _buildStep2(),
              if (_currentStep == 3) _buildStep3(),
              const SizedBox(height: 32),
              _buildBackToLogin(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () {
            if (_currentStep == 2) {
              _countdownTimer?.cancel();
              setState(() {
                _currentStep = 1;
                _globalError = null;
              });
            } else {
              context.pop();
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
          color: SigsTheme.primaryBlue,
          style: IconButton.styleFrom(
            backgroundColor: SigsTheme.surfaceGrey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const Spacer(),
        Image.asset('assets/images/logo_sigs.png', height: 36),
        const Spacer(),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildStepper() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepCircle(1, 'Vérification'),
        _stepConnector(_currentStep > 1),
        _stepCircle(2, 'Nouveau MDP'),
      ],
    );
  }

  Widget _stepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? SigsTheme.successGreen
                : isActive
                    ? SigsTheme.primaryOrange
                    : Colors.grey.shade300,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '$step',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? SigsTheme.primaryOrange : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _stepConnector(bool active) {
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
      decoration: BoxDecoration(
        color: active ? SigsTheme.successGreen : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildTitle() {
    String title;
    String subtitle;

    switch (_currentStep) {
      case 1:
        title = 'Réinitialisation';
        subtitle = 'Vérifiez votre identité pour continuer';
        break;
      case 2:
        title = 'Nouveau mot de passe';
        subtitle = 'Définissez un mot de passe sécurisé';
        break;
      default:
        title = 'Mot de passe réinitialisé';
        subtitle = 'Vous pouvez maintenant vous connecter';
    }

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _currentStep == 3
                ? SigsTheme.successGreen
                : SigsTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ───────── STEP 1 ─────────

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHelpCard(),
        const SizedBox(height: 20),
        _buildUserTypeSelector(),
        if (_userType.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildCredentialsForm(),
        ],
      ],
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SigsTheme.primaryOrange.withValues(alpha: 0.08),
            SigsTheme.warningAmber.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SigsTheme.primaryOrange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              color: SigsTheme.primaryOrange, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations oubliées ?',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SigsTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Contactez la DSI : dsi.sportci@gmail.com\nTél : 07 07 48 54 97',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type de compte',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: SigsTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sélectionnez votre type de compte',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        _userTypeCard(
          type: 'entity',
          icon: Icons.business_rounded,
          title: 'Utilisateur avec entité',
          subtitle: 'Email + Code PIN + Code DSI',
        ),
        const SizedBox(height: 10),
        _userTypeCard(
          type: 'admin',
          icon: Icons.admin_panel_settings_rounded,
          title: 'Utilisateur administratif',
          subtitle: 'Email + Code PIN uniquement',
        ),
      ],
    );
  }

  Widget _userTypeCard({
    required String type,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = _userType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _userType = type;
        _globalError = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? SigsTheme.primaryOrange.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? SigsTheme.primaryOrange : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? SigsTheme.primaryOrange
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: selected ? Colors.white : Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? SigsTheme.primaryOrange
                          : SigsTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: SigsTheme.primaryOrange, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialsForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('Adresse email'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'votre@email.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email requis';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _label('Code PIN de sécurité'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            textInputAction:
                _userType == 'entity' ? TextInputAction.next : TextInputAction.done,
            obscureText: true,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: '4 à 6 chiffres',
              prefixIcon: Icon(Icons.lock_outline_rounded),
              counterText: '',
            ),
            style: GoogleFonts.courierPrime(
              fontSize: 18,
              letterSpacing: 6,
            ),
            textAlign: TextAlign.center,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Code PIN requis';
              if (v.length < 4) return 'Minimum 4 chiffres';
              return null;
            },
          ),
          if (_userType == 'entity') ...[
            const SizedBox(height: 16),
            _label('Code de votre entité (Code DSI)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _entityCodeController,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'Ex: DR2400NX, FED240001A...',
                prefixIcon: Icon(Icons.business_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Code entité requis';
                }
                if (v.trim().length < 8) return 'Code trop court';
                return null;
              },
            ),
          ],
          if (_globalError != null) ...[
            const SizedBox(height: 16),
            _errorBanner(_globalError!),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _verifyCredentials,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.verified_user_rounded),
              label: Text(
                _loading ? 'Vérification...' : 'Vérifier mes informations',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────── STEP 2 ─────────

  Widget _buildStep2() {
    final minutes = _tokenExpiresIn ~/ 60;
    final seconds = _tokenExpiresIn % 60;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SigsTheme.successGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SigsTheme.successGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: SigsTheme.successGreen, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Identité vérifiée',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: SigsTheme.successGreen,
                        ),
                      ),
                      Text(
                        'Temps restant : ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _tokenExpiresIn < 120
                              ? SigsTheme.dangerRed
                              : Colors.grey.shade600,
                          fontWeight: _tokenExpiresIn < 120
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _label('Nouveau mot de passe'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _newPasswordController,
            obscureText: _obscureNew,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Minimum 8 caractères',
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscureNew = !_obscureNew),
                icon: Icon(_obscureNew
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mot de passe requis';
              if (v.length < 8) return 'Minimum 8 caractères';
              if (!RegExp(r'[a-z]').hasMatch(v)) return 'Une minuscule requise';
              if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Une majuscule requise';
              if (!RegExp(r'[0-9]').hasMatch(v)) return 'Un chiffre requis';
              return null;
            },
          ),
          const SizedBox(height: 8),
          _buildStrengthBar(),
          const SizedBox(height: 16),
          _label('Confirmer le mot de passe'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: 'Répétez le mot de passe',
              prefixIcon: const Icon(Icons.key_rounded),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(_obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirmation requise';
              if (v != _newPasswordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
          if (_globalError != null) ...[
            const SizedBox(height: 16),
            _errorBanner(_globalError!),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _resetPassword,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _loading ? 'Réinitialisation...' : 'Réinitialiser',
                style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: _strengthWidth,
            minHeight: 4,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(_strengthColor),
          ),
        ),
        if (_strengthText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              _strengthText,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _strengthColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ───────── STEP 3 ─────────

  Widget _buildStep3() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: SigsTheme.successGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: SigsTheme.successGreen,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Votre mot de passe a été modifié avec succès.\nVous pouvez maintenant vous connecter.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login_rounded),
            label: Text(
              'Se connecter',
              style:
                  GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ───────── Shared Widgets ─────────

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: SigsTheme.primaryBlue,
      ),
    );
  }

  Widget _errorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SigsTheme.dangerRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SigsTheme.dangerRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: SigsTheme.dangerRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                  fontSize: 13, color: SigsTheme.dangerRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToLogin() {
    return Center(
      child: TextButton.icon(
        onPressed: () => context.pop(),
        icon: Icon(Icons.arrow_back_rounded,
            size: 18, color: SigsTheme.primaryOrange),
        label: Text(
          _currentStep == 3 ? 'Aller à la connexion' : 'Retour à la connexion',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: SigsTheme.primaryOrange,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
