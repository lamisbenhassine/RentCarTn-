import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/services/location_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/validators.dart';
import '../../data/mock/mock_cars.dart';
import '../../data/repositories/auth_repository.dart';
import '../../l10n/l10n.dart';
import '../../data/models/user_role.dart';
import '../../state/auction_provider.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common.dart';
import 'auth_scaffold.dart';
import 'google_sign_in_button.dart';
import 'password_strength.dart';

/// Inscription en 3 étapes : Identité → Localisation → Sécurité.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

enum _LocStatus { idle, loading, success, failed }

class _RegisterScreenState extends State<RegisterScreen> {
  static const _stepCount = 3;

  /// Une clé par étape : on ne valide que les champs affichés.
  final _identityKey = GlobalKey<FormState>();
  final _securityKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  final _location = const LocationService();

  int _step = 0;

  // Étape 1 — compte existant (message traduit à l'affichage).
  bool _emailTaken = false;
  bool _phoneTaken = false;

  // Étape 2 — localisation.
  _LocStatus _locStatus = _LocStatus.idle;
  DetectedLocation? _detected;
  LocationException? _locError;
  bool _manualCity = false;
  String _city = 'Tunis';
  UserRole _role = UserRole.user;

  // Étape 3 — sécurité.
  bool _obscure = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation entre étapes
  // ---------------------------------------------------------------------------

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    switch (_step) {
      case 0:
        if (await _validateIdentity()) setState(() => _step = 1);
      case 1:
        if (_validateLocation()) setState(() => _step = 2);
      case 2:
        await _submit();
    }
  }

  void _back() {
    FocusScope.of(context).unfocus();
    if (_step > 0) setState(() => _step--);
  }

  Future<bool> _validateIdentity() async {
    setState(() {
      _emailTaken = false;
      _phoneTaken = false;
    });
    if (!_identityKey.currentState!.validate()) return false;

    final result = await context.read<AuthProvider>().checkIdentityAvailable(
      email: _email.text,
      phone: _phone.text,
    );
    if (!mounted) return false;
    if (result.emailTaken || result.phoneTaken) {
      setState(() {
        _emailTaken = result.emailTaken;
        _phoneTaken = result.phoneTaken;
      });
      return false;
    }
    return true;
  }

  bool _validateLocation() {
    if (_locStatus == _LocStatus.success || _manualCity) return true;
    AppSnack.error(context, context.l10n.registerUseLocationOrCity);
    return false;
  }

  // ---------------------------------------------------------------------------
  // Localisation
  // ---------------------------------------------------------------------------

  Future<void> _useMyLocation() async {
    setState(() {
      _locStatus = _LocStatus.loading;
      _locError = null;
    });
    try {
      final found = await _location.detect();
      if (!mounted) return;
      setState(() {
        _detected = found;
        _city = found.nearestCity;
        _manualCity = false;
        _locStatus = _LocStatus.success;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _locError = e;
        _locStatus = _LocStatus.failed;
        // GPS refusé / désactivé → on bascule sur le choix manuel.
        _manualCity = true;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Envoi
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    final l = context.l10n;
    if (!_securityKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      AppSnack.error(context, l.registerAcceptTermsRequired);
      return;
    }

    final useGps = _locStatus == _LocStatus.success && !_manualCity;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      firstName: _firstName.text,
      lastName: _lastName.text,
      email: _email.text,
      phone: _phone.text,
      password: _password.text,
      city: _city,
      address: useGps ? (_detected?.address ?? '') : '',
      latitude: useGps ? _detected?.latitude : null,
      longitude: useGps ? _detected?.longitude : null,
      role: _role,
    );
    if (!mounted) return;

    if (ok) {
      context.read<AuctionProvider>().setUsername(
        auth.publicUsername,
        userId: auth.user?.id,
      );
      // Compte créé mais e-mail à vérifier : écran du code, pas l'accueil.
      AppSnack.success(context, l.registerSuccess);
      context.go(Routes.verifyEmail);
      return;
    }

    final code = auth.errorCode;
    AppSnack.error(
      context,
      code == null ? l.registerFailed : l.authError(code),
    );
    // E-mail / téléphone pris entre-temps → retour à l'étape 1.
    if (code == AuthErrorCode.emailTaken || code == AuthErrorCode.phoneTaken) {
      setState(() {
        _emailTaken = code == AuthErrorCode.emailTaken;
        _phoneTaken = code == AuthErrorCode.phoneTaken;
        _step = 0;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final busy = context.watch<AuthProvider>().busy;
    final locating = _locStatus == _LocStatus.loading;
    final isLast = _step == _stepCount - 1;
    final titles = [
      l.registerStepIdentity,
      l.registerStepLocation,
      l.registerStepSecurity,
    ];

    return PopScope(
      // Le bouton retour Android revient à l'étape précédente.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AuthScaffold(
        title: l.registerTitle,
        subtitle: l.registerSubtitle,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepProgress(step: _step, titles: titles),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: switch (_step) {
                  0 => _identityStep(),
                  1 => _locationStep(),
                  _ => _securityStep(),
                },
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                if (_step > 0) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : _back,
                      // arrow_back_rounded s'inverse tout seul en arabe.
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: Text(l.commonBack),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: busy || locating ? null : _next,
                    child: busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isLast ? l.registerCreateMyAccount : l.commonNext,
                          ),
                  ),
                ),
              ],
            ),
            // Raccourci Google seulement à la 1ʳᵉ étape (avant toute saisie).
            if (_step == 0) ...[
              const SizedBox(height: 18),
              const OrDivider(),
              const SizedBox(height: 18),
              const GoogleSignInButton(),
            ],
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.registerAlreadyRegistered,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(Routes.login),
                  child: Text(l.commonLogin),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Étape 1 : Identité ----------------------------------------------------

  Widget _identityStep() {
    final l = context.l10n;
    final wide = Responsive.isWide(context);
    return Form(
      key: _identityKey,
      child: Column(
        children: [
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _firstNameField()),
                const SizedBox(width: 14),
                Expanded(child: _lastNameField()),
              ],
            )
          else ...[
            _firstNameField(),
            const SizedBox(height: 16),
            _lastNameField(),
          ],
          const SizedBox(height: 16),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: l.commonEmail,
              hintText: l.commonEmailHint,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
              errorText: _emailTaken ? l.commonEmailTaken : null,
            ),
            validator: Validators.email,
            onChanged: (_) {
              if (_emailTaken) setState(() => _emailTaken = false);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l.commonPhone,
              hintText: '22 345 678',
              prefixText: '+216 ',
              prefixIcon: const Icon(Icons.phone_outlined),
              errorText: _phoneTaken ? l.commonPhoneTaken : null,
            ),
            validator: Validators.phone,
            onChanged: (_) {
              if (_phoneTaken) setState(() => _phoneTaken = false);
            },
          ),
          const SizedBox(height: 16),
          // Équipe : type de compte (l'admin n'est jamais créé ici).
          DropdownButtonFormField<UserRole>(
            initialValue: _role,
            decoration: InputDecoration(
              labelText: l.registerAccountType,
              prefixIcon: const Icon(Icons.badge_outlined),
            ),
            items: [
              DropdownMenuItem(
                value: UserRole.user,
                child: Text(l.registerRoleUser),
              ),
              DropdownMenuItem(
                value: UserRole.company,
                child: Text(l.registerRoleCompany),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _role = v);
            },
          ),
        ],
      ),
    );
  }

  Widget _firstNameField() => TextFormField(
    controller: _firstName,
    textCapitalization: TextCapitalization.words,
    decoration: InputDecoration(
      labelText: context.l10n.commonFirstName,
      prefixIcon: const Icon(Icons.person_outline_rounded),
    ),
    validator: Validators.name,
  );

  Widget _lastNameField() => TextFormField(
    controller: _lastName,
    textCapitalization: TextCapitalization.words,
    decoration: InputDecoration(labelText: context.l10n.commonLastName),
    validator: Validators.name,
  );

  // --- Étape 2 : Localisation ------------------------------------------------

  Widget _locationStep() {
    final l = context.l10n;
    final loading = _locStatus == _LocStatus.loading;
    final detected = _detected;
    final showDetected =
        _locStatus == _LocStatus.success && detected != null && !_manualCity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.registerAgencyIntro,
          style: TextStyle(fontSize: 13.5, color: context.cs.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: loading ? null : _useMyLocation,
            icon: loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(loading ? l.commonLocating : l.registerUseMyLocation),
          ),
        ),
        const SizedBox(height: 16),
        if (showDetected) ...[
          _DetectedCard(location: detected),
          if (detected.distanceKm > 150) ...[
            const SizedBox(height: 12),
            NoticeBox(
              icon: Icons.travel_explore_rounded,
              color: AppColors.warning,
              message: l.registerFarFromAgencies,
            ),
          ],
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: () => setState(() => _manualCity = true),
              child: Text(l.registerChooseOtherCity),
            ),
          ),
        ],
        if (_locError != null) ...[
          _LocationErrorBox(
            error: _locError!,
            onOpenSettings: switch (_locError!.reason) {
              LocationFailure.serviceDisabled => _location.openLocationSettings,
              LocationFailure.deniedForever => _location.openAppSettings,
              _ => null,
            },
          ),
          const SizedBox(height: 16),
        ],
        if (_manualCity)
          DropdownButtonFormField<String>(
            initialValue: _city,
            decoration: InputDecoration(
              labelText: l.registerAgencyCity,
              prefixIcon: const Icon(Icons.place_outlined),
            ),
            items: [
              for (final city in MockCars.villes)
                DropdownMenuItem(value: city, child: Text(city)),
            ],
            onChanged: (v) => setState(() => _city = v ?? 'Tunis'),
          )
        else if (_locStatus == _LocStatus.idle)
          Center(
            child: TextButton(
              onPressed: () => setState(() => _manualCity = true),
              child: Text(l.registerPreferChooseCity),
            ),
          ),
      ],
    );
  }

  // --- Étape 3 : Sécurité ----------------------------------------------------

  Widget _securityStep() {
    final l = context.l10n;
    return Form(
      key: _securityKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: l.commonPassword,
              helperText: l.commonPasswordHelper,
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: Validators.password,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          PasswordStrength(password: _password.text),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirm,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: l.commonConfirmPassword,
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (v) => Validators.confirmPassword(v, _password.text),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _acceptTerms,
                onChanged: (v) => setState(() => _acceptTerms = v ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    l.registerAcceptTerms,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          NoticeBox(message: l.registerSecurityNotice),
        ],
      ),
    );
  }
}

/// Barre de progression « Étape x/3 » + libellés des étapes.
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.step, required this.titles});

  final int step;
  final List<String> titles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.registerStepProgress(
            step + 1,
            titles.length,
            titles[step],
          ),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 8),
        // LinearProgressIndicator se remplit de droite à gauche en arabe.
        TweenAnimationBuilder<double>(
          tween: Tween(end: (step + 1) / titles.length),
          duration: const Duration(milliseconds: 300),
          builder: (_, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: context.cs.outlineVariant,
              color: AppColors.accent,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < titles.length; i++)
              Expanded(
                child: Text(
                  titles[i],
                  textAlign: switch (i) {
                    0 => TextAlign.start,
                    _ when i == titles.length - 1 => TextAlign.end,
                    _ => TextAlign.center,
                  },
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: i == step ? FontWeight.w700 : FontWeight.w500,
                    color: i <= step
                        ? context.cs.onSurface
                        : context.cs.outline,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Carte « adresse détectée + agence la plus proche ».
class _DetectedCard extends StatelessWidget {
  const _DetectedCard({required this.location});

  final DetectedLocation location;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location.address ?? l.commonAddressUnavailable,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.commonNearestAgency(
                    location.nearestCity,
                    location.distanceKm.toStringAsFixed(1),
                  ),
                  style: TextStyle(
                    fontSize: 13.5,
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Erreur GPS + bouton vers les paramètres quand c'est utile.
class _LocationErrorBox extends StatelessWidget {
  const _LocationErrorBox({required this.error, this.onOpenSettings});

  final LocationException error;
  final Future<bool> Function()? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        NoticeBox(
          icon: Icons.location_off_rounded,
          color: AppColors.warning,
          title: l.commonPositionUnavailable,
          message:
              '${l.locationError(error.reason)}\n${l.registerChooseCityBelow}',
        ),
        if (onOpenSettings != null)
          TextButton.icon(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: Text(l.commonOpenSettings),
          ),
      ],
    );
  }
}
