import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/phobes_theme.dart';
import '../../l10n/app_localizations.dart';
import '../phobes_widgets.dart';
import '../../services/weather_service.dart';
import '../../services/book_service.dart';
import '../../models/book_model.dart';

class NavigationSidebar extends StatelessWidget {
  final int selectedIndex;
  final int selectedSubIndex;
  final Function(int, int?) onItemSelected;
  final List<SidebarItemData> items;
  final Widget? header;
  final double width;
  final VoidCallback? onSignOut;
  final String? signOutLabel;
  final bool iconOnly;
  final Widget? footer;

  const NavigationSidebar({
    super.key,
    required this.selectedIndex,
    this.selectedSubIndex = -1,
    required this.onItemSelected,
    required this.items,
    this.header,
    this.width = 260,
    this.onSignOut,
    this.signOutLabel,
    this.iconOnly = false,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final resolvedSignOut = signOutLabel ?? l10n.signOut;

    final compact = width < 230;
    final hPad = iconOnly ? 8.0 : 16.0;

    return AnimatedContainer(
      duration: PhobesTheme.animNormal,
      curve: PhobesTheme.curveDefault,
      width: width,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          right: BorderSide(
            color: cs.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          if (header != null) header!,
          SizedBox(height: iconOnly ? 12 : 20),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedIndex == index;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SidebarItem(
                      item: item,
                      isSelected: isSelected,
                      compact: compact,
                      iconOnly: iconOnly,
                      onTap: () => onItemSelected(index, null),
                    ),
                    if (!iconOnly &&
                        isSelected &&
                        item.subItems != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        child: Column(
                          children:
                              List.generate(item.subItems!.length, (subIdx) {
                            final subItem = item.subItems![subIdx];
                            final isSubSelected = selectedSubIndex == subIdx;

                            return _SidebarSubItem(
                              label: subItem.label,
                              icon: subItem.icon,
                              isSelected: isSubSelected,
                              compact: compact,
                              onTap: () => onItemSelected(index, subIdx),
                            );
                          }),
                        ),
                      ),
                    SizedBox(height: iconOnly ? 4 : 8),
                  ],
                );
              },
            ),
          ),
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 12),
              child: footer,
            )
          else if (onSignOut != null) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onSignOut,
                  borderRadius: BorderRadius.circular(16),
                  child: Tooltip(
                    message: resolvedSignOut,
                    child: AnimatedContainer(
                      duration: PhobesTheme.animFast,
                      padding: EdgeInsets.symmetric(
                        horizontal: iconOnly ? 0 : 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.error.withOpacity(0.2),
                        ),
                      ),
                      child: iconOnly
                          ? Center(
                              child: Icon(
                                Icons.logout_rounded,
                                color: cs.error.withOpacity(0.85),
                                size: 22,
                              ),
                            )
                          : Row(
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  color: cs.error.withOpacity(0.85),
                                  size: compact ? 20 : 22,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    resolvedSignOut,
                                    style: GoogleFonts.outfit(
                                      fontSize: compact ? 13 : 15,
                                      fontWeight: FontWeight.w600,
                                      color: cs.error.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (footer == null && !iconOnly)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Phobes Vision 2026',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.3),
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Web sidebar footer: profile (account) + sign-out.
class SidebarUserFooter extends StatelessWidget {
  final String displayName;
  final String? photoUrl;
  final int xp;
  final bool iconOnly;
  final bool isAccountSelected;
  final VoidCallback onAccountTap;
  final VoidCallback onSignOut;
  final String signOutTooltip;

  const SidebarUserFooter({
    super.key,
    required this.displayName,
    this.photoUrl,
    required this.xp,
    this.iconOnly = false,
    this.isAccountSelected = false,
    required this.onAccountTap,
    required this.onSignOut,
    this.signOutTooltip = '',
  });

  Widget _avatar(ColorScheme cs, {double size = 40}) {
    final trimmed = displayName.trim();
    final initials =
        trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '?';

    Widget child;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      child = ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _initialsAvatar(cs, initials, size),
        ),
      );
    } else {
      child = _initialsAvatar(cs, initials, size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isAccountSelected
              ? cs.primary
              : cs.outline.withOpacity(0.15),
          width: isAccountSelected ? 2 : 1,
        ),
      ),
      child: child,
    );
  }

  Widget _initialsAvatar(ColorScheme cs, String initials, double size) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: PhobesTheme.primaryGradient,
      ),
      child: Text(
        initials,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final name =
        displayName.trim().isEmpty ? l10n.myAccount : displayName.trim();
    final resolvedSignOut =
        signOutTooltip.isEmpty ? l10n.signOut : signOutTooltip;

    if (iconOnly) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: name,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAccountTap,
                customBorder: const CircleBorder(),
                child: _avatar(cs, size: 36),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Tooltip(
            message: resolvedSignOut,
            child: IconButton(
              onPressed: onSignOut,
              icon: Icon(
                Icons.logout_rounded,
                size: 20,
                color: cs.error.withOpacity(0.85),
              ),
              style: IconButton.styleFrom(
                backgroundColor: cs.error.withOpacity(0.08),
                minimumSize: const Size(36, 36),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      );
    }

    return Material(
      color: isAccountSelected
          ? cs.primary.withOpacity(0.08)
          : cs.onSurface.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onAccountTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      _avatar(cs),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$xp xp',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface.withOpacity(0.5),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onSignOut,
              tooltip: resolvedSignOut,
              icon: Icon(
                Icons.logout_rounded,
                size: 22,
                color: cs.error.withOpacity(0.85),
              ),
              style: IconButton.styleFrom(
                minimumSize: const Size(40, 40),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SidebarSubItemData {
  final IconData icon;
  final String label;

  SidebarSubItemData({required this.icon, required this.label});
}

class SidebarItemData {
  final IconData icon;
  final String label;
  final Color? color;
  final List<SidebarSubItemData>? subItems;

  final VoidCallback? onTap;

  SidebarItemData({
    required this.icon,
    required this.label,
    this.color,
    this.subItems,
    this.onTap,
  });
}

class _SidebarSubItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _SidebarSubItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.compact = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FadeInLeft(
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.only(left: 38),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: PhobesTheme.animFast,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withOpacity(0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: compact ? 14 : 16,
                    color:
                        isSelected ? cs.primary : cs.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: compact ? 12 : 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? cs.primary
                            : cs.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final SidebarItemData item;
  final bool isSelected;
  final bool compact;
  final bool iconOnly;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    this.compact = false,
    this.iconOnly = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final content = AnimatedContainer(
      duration: PhobesTheme.animFast,
      padding: EdgeInsets.symmetric(
        horizontal: iconOnly ? 0 : 16,
        vertical: iconOnly ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: isSelected ? cs.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? cs.primary.withOpacity(0.2)
              : Colors.transparent,
        ),
      ),
      child: iconOnly
          ? Center(
              child: Icon(
                item.icon,
                color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.6),
                size: 22,
              ),
            )
          : Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected
                      ? cs.primary
                      : cs.onSurface.withOpacity(0.6),
                  size: compact ? 20 : 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.outfit(
                      fontSize: compact ? 13 : 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? cs.primary
                          : cs.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
    );

    final tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap ?? onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );

    return FadeInLeft(
      duration: const Duration(milliseconds: 300),
      child: iconOnly
          ? Tooltip(message: item.label, child: tile)
          : tile,
    );
  }
}

class DailyIntelligencePanel extends StatefulWidget {
  final VoidCallback? onNotificationTap;
  final double width;
  final bool compactTypography;

  const DailyIntelligencePanel({
    super.key,
    this.onNotificationTap,
    this.width = 300,
    this.compactTypography = false,
  });

  @override
  State<DailyIntelligencePanel> createState() => _DailyIntelligencePanelState();
}

class _DailyIntelligencePanelState extends State<DailyIntelligencePanel> {
  final TextEditingController _noteController = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  final BookService _bookService = BookService();
  WeatherData? _weatherData;
  BookQuote? _dailyQuote;
  String _selectedCity = 'İstanbul';
  bool _isLoadingWeather = false;
  Timer? _weatherRetryTimer;

  static const String _prefKeyCity = 'selected_weather_city';
  static const String _prefKeyWeatherData = 'cached_weather_data';

  @override
  void initState() {
    super.initState();
    _loadSavedNote();
    _initWeather();
    _loadRandomQuote();

    _weatherRetryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_weatherData == null ||
          _weatherData!.city == 'İstanbul' && _weatherData!.tempC == '15') {
        _loadWeather();
      }
    });
  }

  @override
  void dispose() {
    _weatherRetryTimer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _initWeather() async {
    _weatherData = WeatherData(
      tempC: '15',
      feelsLikeC: '14',
      humidity: '60',
      windSpeed: '10',
      description: 'Bulutlu',
      city: 'İstanbul',
      forecast: [],
    );

    await _loadSavedWeather();

    _loadWeather();
  }

  Future<void> _loadSavedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedCity = prefs.getString(_prefKeyCity) ?? 'İstanbul';
      final cachedJson = prefs.getString(_prefKeyWeatherData);

      if (cachedJson != null) {
        final Map<String, dynamic> data = jsonDecode(cachedJson);
        if (!mounted) return;
        setState(() {
          _weatherData = WeatherData(
            tempC: data['tempC'] ?? '15',
            feelsLikeC: data['feelsLikeC'] ?? '14',
            humidity: data['humidity'] ?? '60',
            windSpeed: data['windSpeed'] ?? '10',
            description: data['description'] ?? 'Bulutlu',
            city: data['city'] ?? 'İstanbul',
            forecast: (data['forecast'] as List? ?? [])
                .map((f) => ForecastDay(
                      date: f['date'],
                      maxTemp: f['maxTemp'],
                      minTemp: f['minTemp'],
                      avgTemp: f['avgTemp'],
                      description: f['description'],
                    ),)
                .toList(),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading cached weather: $e');
    }
  }

  Future<void> _saveWeather(String city, WeatherData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyCity, city);

      final weatherMap = {
        'tempC': data.tempC,
        'feelsLikeC': data.feelsLikeC,
        'humidity': data.humidity,
        'windSpeed': data.windSpeed,
        'description': data.description,
        'city': data.city,
        'forecast': data.forecast
            .map((f) => {
                  'date': f.date,
                  'maxTemp': f.maxTemp,
                  'minTemp': f.minTemp,
                  'avgTemp': f.avgTemp,
                  'description': f.description,
                },)
            .toList(),
      };
      await prefs.setString(_prefKeyWeatherData, jsonEncode(weatherMap));
    } catch (e) {
      debugPrint('Error saving weather: $e');
    }
  }

  Future<void> _loadWeather() async {
    if (_isLoadingWeather) return;
    setState(() => _isLoadingWeather = true);

    try {
      final data = await _weatherService.fetchWeather(cityName: _selectedCity);
      if (mounted && data != null) {
        setState(() {
          _weatherData = data;
          _isLoadingWeather = false;
        });
        _saveWeather(_selectedCity, data);
      } else if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    } catch (e) {
      debugPrint('Weather loading error: $e');
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }

  Future<void> _loadSavedNote() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _noteController.text = prefs.getString('quick_note') ??
          'Bugün odaklanman gereken ana görev projeyi bitirmek.';
      _selectedCity = prefs.getString('selected_city') ?? 'İstanbul';
    });

    _loadWeather();
  }

  Future<void> _loadRandomQuote() async {
    final quote = await _bookService.getRandomQuote();
    if (mounted && quote != null) setState(() => _dailyQuote = quote);
  }

  Widget _buildQuoteCard(ColorScheme cs) {
    final quote = _dailyQuote;
    if (quote == null) return const SizedBox.shrink();
    final color = Color(quote.color);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, size: 14, color: color),
              const SizedBox(width: 6),
              Text('Günün Alıntısı',
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.5)),
              const Spacer(),
              GestureDetector(
                onTap: _loadRandomQuote,
                child: Icon(Icons.refresh_rounded,
                    size: 14, color: color.withOpacity(0.6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '"${quote.text}"',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: cs.onSurface.withOpacity(0.75),
              height: 1.5,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '— ${quote.bookTitle}',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quick_note', _noteController.text);
  }

  Future<void> _saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_city', city);
    setState(() => _selectedCity = city);
    _loadWeather();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    final bool isCompact =
        screenHeight < 800 || widget.compactTypography || widget.width < 260;
    final double verticalPadding = isCompact ? 12.0 : 20.0;
    final double sectionGap = isCompact ? 20.0 : 32.0;
    final horizontalPad = widget.width < 260 ? 16.0 : 24.0;

    String dayName = DateFormat('EEEE').format(now);
    String dateStr = DateFormat('d MMMM').format(now);

    try {
      dayName = DateFormat('EEEE', 'tr_TR').format(now);
      dateStr = DateFormat('d MMMM', 'tr_TR').format(now);
    } catch (e) {
      debugPrint('DateFormat locale error: $e');
    }

    return Container(
      width: widget.width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          left: BorderSide(
            color: cs.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPad,
            4,
            horizontalPad,
            verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: GoogleFonts.outfit(
                          fontSize: isCompact ? 24 : 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          color: cs.onSurface,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: GoogleFonts.outfit(
                          fontSize: isCompact ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: PhobesIconButton(
                      icon: Icons.notifications_none_rounded,
                      backgroundColor: cs.onSurface.withOpacity(0.05),
                      onTap: widget.onNotificationTap ?? () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildWeatherCard(cs, isCompact),
              if (_dailyQuote != null) ...[
                SizedBox(height: sectionGap),
                _buildQuoteCard(cs),
              ],
              SizedBox(height: sectionGap),
              _buildSectionHeader(cs, Icons.edit_note_rounded, 'Hızlı Not'),
              const SizedBox(height: 16),
              Container(
                height: isCompact ? 120 : 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline.withOpacity(0.05)),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    height: 1.6,
                    color: cs.onSurface.withOpacity(0.8),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Bir şeyler not edin...',
                    hintStyle: GoogleFonts.outfit(
                      color: cs.onSurface.withOpacity(0.3),
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PhobesButton(
                text: 'Kaydet',
                onPressed: () async {
                  await _saveNote();
                  if (context.mounted) {
                    PhobesSnackbar.show(context,
                        message: 'Not başarıyla kaydedildi',
                        type: PhobesSnackbarType.success,);
                  }
                },
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ColorScheme cs, IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: cs.primary, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  // ─── Yeni hava durumu kartı ─────────────────────────────────────────────────
  Widget _buildWeatherCard(ColorScheme cs, bool isCompact) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_weatherData == null) {
      return Container(
        width: double.infinity,
        height: 340,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outline.withOpacity(0.1)),
        ),
        child: Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: cs.primary),
        ),
      );
    }

    final w = _weatherData!;
    final aqi = w.airQualityIndex != null ? int.tryParse(w.airQualityIndex!) : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        // Gökyüzü tonu — koyu arka plana uyumlu gradient
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E2A3A),
            Color(0xFF263348),
            Color(0xFF1B2D40),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Üst: şehir + yükleniyor ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _showCitySearch,
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        _selectedCity,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Colors.white54, size: 18),
                    ],
                  ),
                ),
                if (_isLoadingWeather)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor:
                          AlwaysStoppedAnimation(Colors.white54),
                    ),
                  ),
              ],
            ),
          ),

          // ── Ana: sıcaklık + ikon ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${w.tempC}°',
                        style: GoogleFonts.outfit(
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        w.description,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _weatherEmoji(w.description, size: 52),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── 2×2 istatistik ızgarası ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: widget.width < 280 ? 2.35 : 2.6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _statTile(Icons.water_drop_rounded, 'Nem',
                    '${w.humidity}%', compact: isCompact),
                _statTile(Icons.air_rounded, 'Rüzgar',
                    '${w.windSpeed} km/h', compact: isCompact),
                _statTile(Icons.thermostat_rounded, 'Hissedilen',
                    '${w.feelsLikeC}°', compact: isCompact),
                _statTile(
                  Icons.sensors_rounded,
                  'AQI',
                  aqi != null ? '$aqi' : '—',
                  valueColor: _aqiColor(aqi),
                  compact: isCompact,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Divider ────────────────────────────────────────────────────
          Divider(
            color: Colors.white.withOpacity(0.08),
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),

          // ── 3 günlük tahmin ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: w.forecast.map((day) {
                String dayLabel = '';
                try {
                  final date = DateTime.parse(day.date);
                  dayLabel = DateFormat('EEE', 'tr_TR').format(date);
                  // İlk harf büyük
                  dayLabel = dayLabel[0].toUpperCase() +
                      dayLabel.substring(1);
                } catch (_) {
                  dayLabel = day.date.split('-').last;
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _weatherEmoji(day.description, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      '${day.avgTemp}°',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stat kutucuğu ──────────────────────────────────────────────────────────
  Widget _statTile(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: compact ? 14 : 16),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: compact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: valueColor ?? Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: compact ? 9 : 10,
                    color: Colors.white.withOpacity(0.4),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hava durumu emoji/ikonu ────────────────────────────────────────────────
  Widget _weatherEmoji(String description, {required double size}) {
    final desc = description.toLowerCase();
    String emoji;
    if (desc.contains('güneş') || desc.contains('açık') ||
        desc.contains('sunny') || desc.contains('clear')) {
      emoji = '☀️';
    } else if (desc.contains('parçalı bulut') || desc.contains('partly')) {
      emoji = '⛅';
    } else if (desc.contains('bulut') || desc.contains('cloud')) {
      emoji = '☁️';
    } else if (desc.contains('sağanak') || desc.contains('heavy rain')) {
      emoji = '🌧️';
    } else if (desc.contains('yağmur') || desc.contains('rain') ||
        desc.contains('drizzle')) {
      emoji = '🌦️';
    } else if (desc.contains('kar') || desc.contains('snow')) {
      emoji = '❄️';
    } else if (desc.contains('fırtına') || desc.contains('storm') ||
        desc.contains('thunder')) {
      emoji = '⛈️';
    } else if (desc.contains('sis') || desc.contains('fog') ||
        desc.contains('mist')) {
      emoji = '🌫️';
    } else if (desc.contains('rüzgar') || desc.contains('windy')) {
      emoji = '💨';
    } else {
      emoji = '🌤️';
    }
    return Text(emoji, style: TextStyle(fontSize: size));
  }

  // ── AQI renk skalası ──────────────────────────────────────────────────────
  Color _aqiColor(int? aqi) {
    if (aqi == null) return Colors.white70;
    if (aqi <= 50) return const Color(0xFF4CAF50);   // İyi
    if (aqi <= 100) return const Color(0xFFFFEB3B);  // Orta
    if (aqi <= 150) return const Color(0xFFFF9800);  // Hassaslar için sağlıksız
    if (aqi <= 200) return const Color(0xFFE53935);  // Sağlıksız
    return const Color(0xFF9C27B0);                   // Tehlikeli
  }

  void _showCitySearch() {
    const List<String> globalCities = [
      'İstanbul',
      'Ankara',
      'İzmir',
      'London',
      'New York',
      'Tokyo',
      'Paris',
      'Berlin',
      'Rome',
      'Dubai',
      'Moscow',
      'Beijing',
      'Seoul',
      'Sydney',
      'Toronto',
      'Singapore',
      'Amsterdam',
      'Barcelona',
    ];

    const List<String> trDistricts = [
      'Kadıköy',
      'Beşiktaş',
      'Üsküdar',
      'Şişli',
      'Bakırköy',
      'Beylikdüzü',
      'Ataşehir',
      'Maltepe',
      'Sarıyer',
      'Çankaya',
      'Keçiören',
      'Yenimahalle',
      'Mamak',
      'Etimesgut',
      'Sincan',
      'Konak',
      'Karşıyaka',
      'Bornova',
      'Buca',
      'Osmangazi',
      'Nilüfer',
      'Muratpaşa',
      'Kepez',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(context).colorScheme.surface.withOpacity(0.95),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                spreadRadius: -10,
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.public_rounded,
                          color: Theme.of(context).colorScheme.primary,),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Şehir/İlçe Seç',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Tüm dünya şehirlerini arayabilirsin',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _CitySearchList(
                  cities: const [...globalCities, ...trDistricts],
                  onSelect: (city) {
                    _saveCity(city);
                    Navigator.pop(context);
                  },
                  scrollController: controller,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CitySearchList extends StatefulWidget {
  final List<String> cities;
  final Function(String) onSelect;
  final ScrollController scrollController;

  const _CitySearchList({
    required this.cities,
    required this.onSelect,
    required this.scrollController,
  });

  @override
  State<_CitySearchList> createState() => _CitySearchListState();
}

class _CitySearchListState extends State<_CitySearchList> {
  late List<String> filteredCities;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredCities = widget.cities;
    _searchCtrl.addListener(_filter);
  }

  void _filter() {
    setState(() {
      filteredCities = widget.cities
          .where((city) =>
              city.toLowerCase().contains(_searchCtrl.text.toLowerCase()),)
          .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showCustomSearch = _searchCtrl.text.isNotEmpty &&
        !filteredCities
            .any((c) => c.toLowerCase() == _searchCtrl.text.toLowerCase());

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outline.withOpacity(0.1)),
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Şehir veya ilçe ara...',
                hintStyle:
                    GoogleFonts.outfit(color: cs.onSurface.withOpacity(0.3)),
                prefixIcon:
                    Icon(Icons.search_rounded, color: cs.primary, size: 22),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: filteredCities.length + (showCustomSearch ? 1 : 0),
            itemBuilder: (context, index) {
              if (showCustomSearch && index == 0) {
                return _buildCityItem('Ara: "${_searchCtrl.text}"', true);
              }
              final city = filteredCities[showCustomSearch ? index - 1 : index];
              return _buildCityItem(city, false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCityItem(String name, bool isCustomSearch) {
    final cs = Theme.of(context).colorScheme;
    final displayName = isCustomSearch
        ? name.replaceFirst('Ara: "', '').replaceFirst('"', '')
        : name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FadeInLeft(
        duration: const Duration(milliseconds: 300),
        child: ListTile(
          onTap: () => widget.onSelect(displayName),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isCustomSearch ? Colors.orange : cs.primary)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCustomSearch
                  ? Icons.manage_search_rounded
                  : Icons.location_on_rounded,
              size: 18,
              color: isCustomSearch ? Colors.orange : cs.primary,
            ),
          ),
          title: Text(
            name,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: isCustomSearch ? cs.primary : cs.onSurface,
            ),
          ),
          trailing: Icon(Icons.chevron_right_rounded,
              size: 18, color: cs.onSurface.withOpacity(0.2),),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: cs.onSurface.withOpacity(0.02),
          hoverColor: cs.primary.withOpacity(0.05),
        ),
      ),
    );
  }
}
