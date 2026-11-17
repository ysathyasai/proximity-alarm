import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../data/models/destination.dart';
import '../../providers/saved_destinations_provider.dart';
import '../../providers/settings_provider.dart';
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
    context.read<SavedDestinationsProvider>().addRecentSearch(dest);
    widget.onDestinationSelected(dest);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPitchBlack = context.watch<SettingsProvider>().isPitchBlack;
    final savedProvider = context.watch<SavedDestinationsProvider>();
    final savedDestinations = savedProvider.destinations;
    final recentSearches = savedProvider.recentSearches;

    final String query = _controller.text.trim().toLowerCase();
    final bool isEmptyQuery = query.isEmpty;

    // Offline / Local matches when search has no network results
    final List<Destination> offlineMatches = isEmptyQuery
        ? []
        : [
            ...savedDestinations,
            ...recentSearches,
          ]
            .where((d) =>
                d.name.toLowerCase().contains(query) ||
                d.address.toLowerCase().contains(query))
            .fold<List<Destination>>([], (list, item) {
            if (!list.any((d) =>
                d.name.toLowerCase() == item.name.toLowerCase() ||
                (d.latitude == item.latitude && d.longitude == item.longitude))) {
              list.add(item);
            }
            return list;
          });

    final bool hasInitialDropdownItems =
        isEmptyQuery && (savedDestinations.isNotEmpty || recentSearches.isNotEmpty);

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

        // Dropdown Suggestions (Search results, Offline Fallback, OR Quick Saved/Recent Places)
        if (_showDropdown &&
            (hasInitialDropdownItems ||
                _suggestions.isNotEmpty ||
                offlineMatches.isNotEmpty ||
                _isLoading))
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              color: isDark
                  ? (isPitchBlack ? const Color(0xFF0C0C0C) : const Color(0xFF1E293B))
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? (isPitchBlack ? const Color(0xFF222222) : const Color(0xFF334155))
                    : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isEmptyQuery
                ? ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    children: [
                      // Saved places section
                      if (savedDestinations.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                          child: Text(
                            'SAVED PLACES',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        ...savedDestinations.map((item) {
                          IconData catIcon = Icons.place_rounded;
                          if (item.category == 'home') catIcon = Icons.home_rounded;
                          if (item.category == 'work') catIcon = Icons.work_rounded;
                          if (item.category == 'station') catIcon = Icons.train_rounded;
                          if (item.category == 'favorite') catIcon = Icons.star_rounded;

                          return ListTile(
                            dense: true,
                            leading: Icon(catIcon,
                                color: theme.colorScheme.primary, size: 20),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Saved',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                            onTap: () => _selectSuggestion(item),
                          );
                        }),
                      ],

                      // Recent searches section
                      if (recentSearches.isNotEmpty) ...[
                        if (savedDestinations.isNotEmpty)
                          Divider(
                            height: 12,
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFF1F5F9),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'RECENT SEARCHES',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => savedProvider.clearRecentSearches(),
                                child: Text(
                                  'Clear',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...recentSearches.map((item) {
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.history_rounded,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
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
                        }),
                      ],
                    ],
                  )
                : _isLoading && _suggestions.isEmpty && offlineMatches.isEmpty
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
                        itemCount: _suggestions.isNotEmpty
                            ? _suggestions.length
                            : offlineMatches.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                        ),
                        itemBuilder: (context, index) {
                          final isFromNetwork = _suggestions.isNotEmpty;
                          final item = isFromNetwork
                              ? _suggestions[index]
                              : offlineMatches[index];

                          return ListTile(
                            dense: true,
                            leading: Icon(
                              isFromNetwork
                                  ? Icons.location_on_outlined
                                  : Icons.cloud_off_rounded,
                              color: isFromNetwork
                                  ? theme.colorScheme.primary
                                  : const Color(0xFF10B981),
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
                            trailing: !isFromNetwork
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Offline',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () => _selectSuggestion(item),
                          );
                        },
                      ),
          ),
      ],
    );
  }
}
