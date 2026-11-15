import 'package:flutter/material.dart';
import '../models/destination.dart';
import 'map_screen.dart';

/// Legacy alias routing directly to the updated MapScreen
class DestinationPickerScreen extends StatelessWidget {
  const DestinationPickerScreen({super.key, this.initialDestination});

  final Destination? initialDestination;

  @override
  Widget build(BuildContext context) {
    return MapScreen(initialDestination: initialDestination);
  }
}
