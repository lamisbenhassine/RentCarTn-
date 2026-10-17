import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/validators.dart';
import '../../data/mock/mock_cars.dart';
import '../../state/auction_provider.dart';
import '../../state/auth_provider.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

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
  bool _saving = false;

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
      helpText: 'Date de naissance',
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final updated = auth.user!.copyWith(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      cin: _cin.text.trim(),
      licenceNumber: _licence.text.trim(),
      address: _address.text.trim(),
      city: _city,
      birthDate: _birthDate,
      publicUsername: _username.text.trim(),
    );
    auth.updateProfile(updated);
    context.read<AuctionProvider>().setUsername(updated.publicUsername);

    setState(() => _saving = false);
    AppSnack.success(context, 'Profil mis à jour.');
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final wide = Responsive.isWide(context);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Modifier mon profil',
        subtitle: 'Informations utilisées pour vos contrats',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Identité'),
                    if (wide)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstName,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Prénom',
                              ),
                              validator: Validators.name,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _lastName,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Nom',
                              ),
                              validator: Validators.name,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      TextFormField(
                        controller: _firstName,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Prénom',
                        ),
                        validator: Validators.name,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _lastName,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nom'),
                        validator: Validators.name,
                      ),
                    ],
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _pickBirthDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de naissance',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                        child: Text(
                          _birthDate == null
                              ? 'Non renseignée'
                              : Formatters.dateLong(_birthDate!),
                          style: TextStyle(
                            fontSize: 15,
                            color: _birthDate == null
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Coordonnées'),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        prefixText: '+216 ',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _city,
                      decoration: const InputDecoration(
                        labelText: 'Ville',
                        prefixIcon: Icon(Icons.place_outlined),
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
                      decoration: const InputDecoration(
                        labelText: 'Adresse',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Documents de conduite'),
                    TextFormField(
                      controller: _cin,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Numéro CIN',
                        hintText: '8 chiffres',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                          ? null
                          : Validators.cin(v),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _licence,
                      decoration: const InputDecoration(
                        labelText: 'Numéro de permis',
                        hintText: 'TN-2015-884512',
                        prefixIcon: Icon(Icons.credit_card_rounded),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                          ? null
                          : Validators.licenceNumber(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('Enchères'),
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(
                        labelText: 'Pseudonyme public',
                        helperText:
                            'Affiché aux autres participants des enchères',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (v) =>
                          Validators.required(v, champ: 'Le pseudonyme'),
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
                      : const Text('Enregistrer les modifications'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Annuler'),
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
        style: const TextStyle(
          fontSize: 15.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
