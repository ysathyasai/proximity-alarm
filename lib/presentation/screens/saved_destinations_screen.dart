import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/destination.dart';
import '../../providers/journey_provider.dart';
import '../../providers/saved_destinations_provider.dart';
import '../../providers/settings_provider.dart';
import 'destination_picker_screen.dart';

class SavedDestinationsScreen extends StatelessWidget {
  const SavedDestinationsScreen({super.key});

  void _showAddEditDialog(BuildContext context, {Destination? existing}) {
    final settings = context.read<SettingsProvider>();
    final unit = settings.distanceUnit;
    final nameController =
        TextEditingController(text: existing?.name ?? '');
    final addressController =
        TextEditingController(text: existing?.address ?? '');
    String category = existing?.category ?? 'favorite';
    double radius = existing?.radiusMeters ?? settings.defaultRadiusMeters;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(existing == null ? 'Add Destination' : 'Edit Destination'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Place Name (e.g. Home, Office, Central Station)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address or landmark',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Category:',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ('home', Icons.home_rounded, 'Home'),
                      ('work', Icons.work_rounded, 'Work'),
                      ('station', Icons.train_rounded, 'Transit'),
                      ('favorite', Icons.star_rounded, 'Favorite'),
                    ].map((item) {
                      final isSelected = category == item.$1;
                      return ChoiceChip(
                        avatar: Icon(item.$2, size: 16),
                        label: Text(item.$3),
                        selected: isSelected,
                        onSelected: (_) => setState(() => category = item.$1),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Alert Radius:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(
                        Formatters.formatDistance(radius, unit),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: radius.clamp(
                      AppConstants.minRadiusMeters,
                      AppConstants.maxRadiusMeters,
                    ),
                    min: AppConstants.minRadiusMeters,
                    max: AppConstants.maxRadiusMeters,
                    divisions: 49,
                    onChanged: (val) {
                      setState(() {
                        radius = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  final savedProvider = ctx.read<SavedDestinationsProvider>();
                  if (existing != null) {
                    savedProvider.updateDestination(
                      existing.copyWith(
                        name: name,
                        address: addressController.text.trim(),
                        category: category,
                        radiusMeters: radius,
                      ),
                    );
                  } else {
                    final journey = ctx.read<JourneyProvider>();
                    final pos = journey.currentPosition;
                    savedProvider.addDestination(
                      Destination(
                        name: name,
                        address: addressController.text.trim(),
                        latitude: pos?.latitude ?? 13.0827,
                        longitude: pos?.longitude ?? 80.2707,
                        category: category,
                        radiusMeters: radius,
                      ),
                    );
                  }
                  Navigator.of(ctx).pop();
                },
                child: const Text('SAVE'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final saved = context.watch<SavedDestinationsProvider>();
    final journey = context.read<JourneyProvider>();
    final settings = context.watch<SettingsProvider>();
    final unit = settings.distanceUnit;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Destinations'),
        actions: [
          IconButton(
            tooltip: 'Add on Map',
            icon: const Icon(Icons.add_location_alt_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DestinationPickerScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: saved.destinations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border_rounded,
                    size: 64,
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No saved destinations yet',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Save your daily bus stops, train stations, or home\nfor quick one-tap journey starts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _showAddEditDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Frequent Place'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: saved.destinations.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final dest = saved.destinations[index];
                IconData categoryIcon = Icons.place_rounded;
                if (dest.category == 'home') categoryIcon = Icons.home_rounded;
                if (dest.category == 'work') categoryIcon = Icons.work_rounded;
                if (dest.category == 'station') {
                  categoryIcon = Icons.train_rounded;
                }
                if (dest.category == 'favorite') {
                  categoryIcon = Icons.star_rounded;
                }

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(categoryIcon,
                          color: theme.colorScheme.primary, size: 24),
                    ),
                    title: Text(
                      dest.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dest.address.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            dest.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Alert radius: ${Formatters.formatDistance(dest.radiusMeters, unit)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit',
                          onPressed: () =>
                              _showAddEditDialog(context, existing: dest),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: Color(0xFFDC2626)),
                          tooltip: 'Delete',
                          onPressed: () => saved.deleteDestination(dest.id),
                        ),
                      ],
                    ),
                    onTap: () {
                      journey.selectDestination(dest);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Selected "${dest.name}" as destination!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'btn_add_saved',
        onPressed: () => _showAddEditDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Place'),
      ),
    );
  }
}
