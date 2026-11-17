import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../data/models/destination.dart';
import '../../providers/saved_destinations_provider.dart';
import '../../services/geocoding_service.dart';

class DestinationSearchBar extends StatefulWidget {
  final LatLng? userLocation;
  final ValueChanged<Destination> onDestinationSelected;
  final String hintText;

  const DestinationSearchBar({
    super.key,
    this.userLocation,
    required this.onDestinationSelected,
    this.hintText = 'Search destination, station, or address...',
  });

  @override
  State<DestinationSearchBar> createState() => _DestinationSearchBarState();
}

class _DestinationSearchBarState extends State<DestinationSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final GeocodingService _geocodingService = GeocodingService();

  Timer? _debounceTimer;
  List<Destination> _suggestions = [];
  bool _isLoading = false;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _controller.text.trim().isEmpty) {
        setState(() {
          _showDropdown = true;
        });
      } else if (!_focusNode.hasFocus && _controller.text.trim().isEmpty) {
        setState(() {
          _showDropdown = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showDropdown = _focusNode.hasFocus;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showDropdown = true;
    });

    // Debounce 600ms to respect OpenStreetMap Nominatim guidelines
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      final results = await _geocodingService.searchPlaces(
        query,
        userLocation: widget.userLocation,
      );

      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
      }
    });
  }

  void _selectSuggestion(Destination dest) {
    HapticFeedback.selectionClick();
    _controller.text = dest.name;
    setState(() {
      _showDropdown = false;
      _suggestions = [];
    });
    _focusNode.unfocus();
    widget.onDestinationSelected(dest);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final savedDestinations = context.watch<SavedDestinationsProvider>().destinations;

    final bool showingSaved =
        _controller.text.trim().isEmpty && savedDestinations.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _suggestions = [];
                            _showDropdown = false;
                          });
                        },
                      )
                    : null,
          ),
        ),

        // Dropdown Suggestions (Search results OR Quick Saved Places)
        if (_showDropdown &&
            (showingSaved || _suggestions.isNotEmpty || _isLoading))
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: showingSaved
                ? ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: savedDestinations.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                    ),
                    itemBuilder: (context, index) {
                      final item = savedDestinations[index];
                      IconData catIcon = Icons.place_rounded;
                      if (item.category == 'home') catIcon = Icons.home_rounded;
                      if (item.category == 'work') catIcon = Icons.work_rounded;
                      if (item.category == 'station') catIcon = Icons.train_rounded;
                      if (item.category == 'favorite') catIcon = Icons.star_rounded;

                      return ListTile(
                        dense: true,
                        leading: Icon(catIcon, color: theme.colorScheme.primary, size: 20),
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          item.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Saved', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        onTap: () => _selectSuggestion(item),
                      );
                    },
                  )
                : _isLoading && _suggestions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'Searching places...',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                        ),
                        itemBuilder: (context, index) {
                          final item = _suggestions[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.location_on_outlined,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              item.address,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSuggestion(item),
                          );
                        },
                      ),
          ),
      ],
    );
  }
}
