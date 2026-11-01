import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/validators.dart';
import '../../data/mock/mock_cars.dart';
import '../../data/services/licence_scan_service.dart';
import '../../l10n/l10n.dart';
import '../../state/auction_provider.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/user_avatar.dart';
import 'avatar_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _cin;
  late final TextEditingController _licence;
  late final TextEditingController _address;
  late final TextEditingController _username;

  late String _city;
  DateTime? _birthDate;
  DateTime? _licenceExpiry;

  /// Photo en cours d'édition (data URL), enregistrée avec le reste.
  String? _avatarUrl;
  bool _saving = false;

  // Scan OCR du permis.
  final _scanner = const LicenceScanService();
  bool _scanning = false;
  LicenceScanResult? _lastScan;

  /// Champs remplis par le scan (surlignés jusqu'à modification manuelle).
  bool _numberFromScan = false;
  bool _expiryFromScan = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _firstName = TextEditingController(text: user.firstName);
    _lastName = TextEditingController(text: user.lastName);
    _email = TextEditingController(text: user.email);
    _phone = TextEditingController(text: user.phone);
    _cin = TextEditingController(text: user.cin);
    _licence = TextEditingController(text: user.licenceNumber);
    _address = TextEditingController(text: user.address);
    _username = TextEditingController(text: user.publicUsername);
    _city = MockCars.villes.contains(user.city) ? user.city : 'Tunis';
    _birthDate = user.birthDate;
    _licenceExpiry = user.licenceExpiry;
    _avatarUrl = user.avatarUrl;
  }

  Future<void> _pickAvatar() async {
    try {
      final choice = await pickAvatar(
        context,
        hasPhoto: _avatarUrl?.isNotEmpty ?? false,
      );
      if (choice == null || !mounted) return;
      setState(() => _avatarUrl = choice.dataUrl);
    } on AvatarPickException catch (e) {
      if (mounted) AppSnack.error(context, e.message);
    }
  }

  // Les sélecteurs de date prennent la langue de l'app (fr / en / ar).

  Future<void> _pickLicenceExpiry() async {
    final now = DateTime.now();
    final current = _licenceExpiry;
    // Un permis déjà expiré peut être saisi (il sera signalé « Expiré »),
    // y compris une date scannée très ancienne.
    var first = DateTime(now.year - 10);
    var last = DateTime(now.year + 20);
    if (current != null && current.isBefore(first)) first = current;
    if (current != null && current.isAfter(last)) last = current;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year + 5, now.month),
      firstDate: first,
      lastDate: last,
      helpText: context.l10n.editLicenceExpiry,
    );
    if (picked != null) {
      setState(() {
        _licenceExpiry = picked;
        _expiryFromScan = false; // saisie manuelle : plus surlignée
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Scan du permis (OCR)
  // ---------------------------------------------------------------------------

  Future<void> _scanLicence() async {
    final l = context.l10n;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                l.scanTip,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: context.cs.onSurfaceVariant,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.accent,
              ),
              title: Text(l.scanCamera),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.accent,
              ),
              title: Text(l.scanGallery),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final XFile? file;
    try {
      // Bonne résolution : l'OCR lit mieux les petits caractères.
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2200,
        imageQuality: 92,
      );
    } on PlatformException catch (e) {
      debugPrint('[LicenceScan] image_picker : ${e.code} ${e.message}');
      if (mounted) {
        AppSnack.error(
          context,
          e.code == 'camera_access_denied' ? l.scanCameraDenied : l.scanFailed,
        );
      }
      return;
    }
    if (file == null || !mounted) return;

    setState(() => _scanning = true);
    final LicenceScanResult result;
    try {
      result = await _scanner.scan(file.path);
    } on LicenceScanException {
      if (mounted) {
        setState(() => _scanning = false);
        AppSnack.error(context, l.scanFailed);
      }
      return;
    }
    if (!mounted) return;

    setState(() {
      _scanning = false;
      _lastScan = result;
      if (result.licenceNumber != null) {
        _licence.text = result.licenceNumber!;
        _numberFromScan = true;
      }
      if (result.expiry != null) {
        _licenceExpiry = result.expiry;
        _expiryFromScan = true;
      }
    });
  }

  /// Message sous le bouton selon ce que le scan a trouvé.
  List<Widget> _scanFeedback(AppLocalizations l) {
    final scan = _lastScan;
    if (scan == null) return const [];

    final (icon, color, message) = scan.isEmpty
        ? (Icons.search_off_rounded, AppColors.warning, l.scanNothing)
        : scan.licenceNumber == null
        ? (Icons.info_outline_rounded, AppColors.info, l.scanOnlyExpiry)
        : scan.expiry == null
        ? (Icons.info_outline_rounded, AppColors.info, l.scanOnlyNumber)
        : (
            Icons.check_circle_outline_rounded,
            AppColors.success,
            l.scanComplete,
          );

    return [
      const SizedBox(height: 12),
      NoticeBox(icon: icon, color: color, message: message),
      if (scan.isExpired()) ...[
        const SizedBox(height: 10),
        NoticeBox(
          icon: Icons.gpp_bad_outlined,
          color: AppColors.danger,
          message: l.scanExpired(context.dateLong(scan.expiry!)),
        ),
      ],
    ];
  }

  /// Fond vert + aide « Rempli par le scan » pour un champ pré-rempli.
  InputDecoration _scanHighlight(InputDecoration base, bool fromScan) {
    if (!fromScan) return base;
    return base.copyWith(
      filled: true,
      fillColor: AppColors.success.withValues(alpha: 0.14),
      helperText: context.l10n.scanFilledHelper,
      helperStyle: const TextStyle(color: AppColors.success),
    );
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _phone,
      _cin,
      _licence,
      _address,
      _username,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 90),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      helpText: context.l10n.editBirthDate,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    final l = context.l10n;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final auth = context.read<AuthProvider>();
    final newEmail = _email.text.trim().toLowerCase();
    // Nouvelle adresse = à vérifier de nouveau.
    final emailChanged = newEmail != auth.user!.email.toLowerCase();
    final updated = auth.user!.copyWith(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: newEmail,
      emailVerified: emailChanged ? false : null,
      phone: _phone.text.trim(),
      cin: _cin.text.trim(),
      licenceNumber: _licence.text.trim(),
      address: _address.text.trim(),
      city: _city,
      birthDate: _birthDate,
      licenceExpiry: _licenceExpiry,
      avatarUrl: _avatarUrl,
      clearAvatar: _avatarUrl == null,
      publicUsername: _username.text.trim(),
    );
    final ok = await auth.updateProfile(updated);
    if (!mounted) return;
    if (!ok) {
      setState(() => _saving = false);
      AppSnack.error(context, l.authError(auth.errorCode));
      return;
    }
    context.read<AuctionProvider>().setUsername(
      updated.publicUsername,
      userId: updated.id,
    );

    setState(() => _saving = false);
    if (emailChanged) {
      AppSnack.info(context, l.editConfirmNewEmail);
      context.go(Routes.verifyEmail);
      return;
    }
    AppSnack.success(context, l.editSaved);
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final wide = Responsive.isWide(context);

    final firstNameField = TextFormField(
      controller: _firstName,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(labelText: l.commonFirstName),
      validator: Validators.name,
    );
    final lastNameField = TextFormField(
      controller: _lastName,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(labelText: l.commonLastName),
      validator: Validators.name,
    );

    return Scaffold(
      backgroundColor: context.cs.surfaceContainerLow,
      // Comme appScreenBar (partagé, couleurs claires en dur), mais aux
      // couleurs du thème pour suivre le mode sombre.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 76,
        backgroundColor: context.cs.surfaceContainerLow,
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(Routes.profile),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.profileEdit, style: Theme.of(context).textTheme.titleLarge),
            Text(
              l.editSubtitle,
              style: TextStyle(
                fontSize: 12.5,
                color: context.cs.outline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: const [SizedBox(width: 8)],
        shape: Border(bottom: BorderSide(color: context.cs.outlineVariant)),
      ),
      body: ContentContainer(
        maxWidth: 720,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              Responsive.value(context, mobile: 16.0, tablet: 24.0),
              16,
              Responsive.value(context, mobile: 16.0, tablet: 24.0),
              28,
            ),
            children: [
              AppCard(
                color: context.cs.surface,
                borderColor: context.cs.outlineVariant,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _pickAvatar,
                      child: UserAvatar(
                        initials: context.read<AuthProvider>().user!.initials,
                        avatarUrl: _avatarUrl,
                        size: 76,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.avatarSheetTitle,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: context.cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.editPhotoSource,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: context.cs.outline,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextButton.icon(
                            onPressed: _pickAvatar,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(
                              Icons.photo_camera_outlined,
                              size: 18,
                            ),
                            label: Text(
                              _avatarUrl == null
                                  ? l.editAddPhoto
                                  : l.editChangePhoto,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                color: context.cs.surface,
                borderColor: context.cs.outlineVariant,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(l.editSectionIdentity),
                    if (wide)
                      Row(
                        children: [
                          Expanded(child: firstNameField),
                          const SizedBox(width: 14),
                          Expanded(child: lastNameField),
                        ],
                      )
                    else ...[
                      firstNameField,
                      const SizedBox(height: 14),
                      lastNameField,
                    ],
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _pickBirthDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l.editBirthDate,
                          prefixIcon: const Icon(Icons.cake_outlined),
                        ),
                        child: Text(
                          _birthDate == null
                              ? l.commonNotProvidedFem
                              : context.dateLong(_birthDate!),
                          style: TextStyle(
                            fontSize: 15,
                            color: _birthDate == null
                                ? context.cs.outline
                                : context.cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                color: context.cs.surface,
                borderColor: context.cs.outlineVariant,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(l.editSectionContact),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: l.commonEmail,
                        prefixIcon: const Icon(Icons.mail_outline_rounded),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: l.commonPhone,
                        prefixText: '+216 ',
                        prefixIcon: const Icon(Icons.phone_outlined),
                      ),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _city,
                      decoration: InputDecoration(
                        labelText: l.editCity,
                        prefixIcon: const Icon(Icons.place_outlined),
                      ),
                      items: [
                        for (final city in MockCars.villes)
                          DropdownMenuItem(value: city, child: Text(city)),
                      ],
                      onChanged: (v) => setState(() => _city = v ?? _city),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _address,
                      decoration: InputDecoration(
                        labelText: l.profileAddress,
                        prefixIcon: const Icon(Icons.home_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                color: context.cs.surface,
                borderColor: context.cs.outlineVariant,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(l.editSectionDocuments),
                    if (_scanner.isSupported) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _scanning ? null : _scanLicence,
                          icon: _scanning
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : const Icon(Icons.document_scanner_outlined),
                          label: Text(
                            _scanning ? l.scanInProgress : l.scanButton,
                          ),
                        ),
                      ),
                      ..._scanFeedback(l),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _cin,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l.editCin,
                        hintText: l.editCinHint,
                        prefixIcon: const Icon(Icons.badge_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? null
                          : Validators.cin(v),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _licence,
                      decoration: _scanHighlight(
                        InputDecoration(
                          labelText: l.editLicenceNumber,
                          hintText: 'TN-2015-884512',
                          prefixIcon: const Icon(Icons.credit_card_rounded),
                        ),
                        _numberFromScan,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? null
                          : Validators.licenceNumber(v),
                      onChanged: (_) {
                        if (_numberFromScan) {
                          setState(() => _numberFromScan = false);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _pickLicenceExpiry,
                      child: InputDecorator(
                        decoration: _scanHighlight(
                          InputDecoration(
                            labelText: l.editLicenceExpiry,
                            prefixIcon: const Icon(Icons.event_outlined),
                            errorText:
                                _licenceExpiry != null &&
                                    _licenceExpiry!.isBefore(
                                      DateUtils.dateOnly(DateTime.now()),
                                    )
                                ? l.editLicenceExpired
                                : null,
                          ),
                          _expiryFromScan,
                        ),
                        child: Text(
                          _licenceExpiry == null
                              ? l.commonNotProvidedFem
                              : context.dateLong(_licenceExpiry!),
                          style: TextStyle(
                            fontSize: 15,
                            color: _licenceExpiry == null
                                ? context.cs.outline
                                : context.cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                color: context.cs.surface,
                borderColor: context.cs.outlineVariant,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(l.editSectionAuctions),
                    TextFormField(
                      controller: _username,
                      decoration: InputDecoration(
                        labelText: l.editAlias,
                        helperText: l.editAliasHelper,
                        prefixIcon: const Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (v) =>
                          Validators.required(v, champ: l.editAliasField),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(l.editSaveChanges),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: Text(l.commonCancel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          color: context.cs.onSurface,
        ),
      ),
    );
  }
}
