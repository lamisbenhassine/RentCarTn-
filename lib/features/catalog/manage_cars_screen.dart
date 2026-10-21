import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/car.dart';
import '../../state/car_provider.dart';
import '../../widgets/car_image.dart';
import '../../widgets/common.dart';
import '../shell/main_shell.dart';

/// Liste CRUD de tous les véhicules (Create / Read / Update / Delete).
class ManageCarsScreen extends StatefulWidget {
  const ManageCarsScreen({super.key});

  @override
  State<ManageCarsScreen> createState() => _ManageCarsScreenState();
}

class _ManageCarsScreenState extends State<ManageCarsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CarProvider>().load();
    });
  }

  Future<void> _confirmDelete(Car car) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce véhicule ?'),
        content: Text(
          '« ${car.fullName} » sera retiré définitivement '
          '(base locale / session).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await context.read<CarProvider>().delete(car.id);
      if (!mounted) return;
      AppSnack.success(context, 'Véhicule supprimé.');
    } catch (_) {
      if (!mounted) return;
      AppSnack.error(context, 'Suppression impossible.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CarProvider>();
    final cars = provider.allCars;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: appScreenBar(
        context,
        title: 'Gérer les véhicules',
        subtitle: 'CRUD · ${cars.length} entrées',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.carForm()),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouveau véhicule'),
      ),
      body: ContentContainer(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                Responsive.value(
                  context,
                  mobile: 16.0,
                  tablet: 24.0,
                  desktop: 28.0,
                ),
                12,
                Responsive.value(
                  context,
                  mobile: 16.0,
                  tablet: 24.0,
                  desktop: 28.0,
                ),
                8,
              ),
              child: const NoticeBox(
                icon: Icons.storage_outlined,
                title: 'Persistance locale',
                message:
                    'APK / téléphone : sqflite. Navigateur (Chrome) : '
                    'shared_preferences — les CRUD survivent au refresh (F5).',
              ),
            ),
            Expanded(
              child: cars.isEmpty
                  ? EmptyState(
                      icon: Icons.directions_car_rounded,
                      title: 'Aucun véhicule',
                      message: 'Ajoutez votre premier véhicule à louer.',
                      actionLabel: 'Ajouter',
                      onAction: () => context.push(Routes.carForm()),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        Responsive.value(
                          context,
                          mobile: 16.0,
                          tablet: 24.0,
                          desktop: 28.0,
                        ),
                        12,
                        Responsive.value(
                          context,
                          mobile: 16.0,
                          tablet: 24.0,
                          desktop: 28.0,
                        ),
                        100,
                      ),
                      itemCount: cars.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final car = cars[i];
                        return AppCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              CarImage(
                                url: car.mainImage,
                                height: 64,
                                width: 88,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      car.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${car.year} · ${car.seats} places · '
                                      '${car.city}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${Formatters.moneyShort(car.pricePerDay)} / jour',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Modifier',
                                onPressed: () =>
                                    context.push(Routes.carForm(id: car.id)),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Supprimer',
                                onPressed: () => _confirmDelete(car),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
