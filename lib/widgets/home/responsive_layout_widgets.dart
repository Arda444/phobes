import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/phobes_theme.dart';
import '../phobes_widgets.dart';
import '../../services/weather_service.dart';

class NavigationSidebar extends StatelessWidget {
  final int selectedIndex;
  final int selectedSubIndex;
  final Function(int, int?) onItemSelected;
  final List<SidebarItemData> items;
  final Widget? header;

  const NavigationSidebar({
    super.key,
    required this.selectedIndex,
    this.selectedSubIndex = -1,
    required this.onItemSelected,
    required this.items,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          right: BorderSide(
            color: cs.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          if (header != null) header!,
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      onTap: () => onItemSelected(index, null),
                    ),
                    if (isSelected && item.subItems != null)
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
                              onTap: () => onItemSelected(index, subIdx),
                            );
                          }),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "Phobes Vision 2026",
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.3),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
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

  SidebarItemData({
    required this.icon,
    required this.label,
    this.color,
    this.subItems,
  });
}

class _SidebarSubItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarSubItem({
    required this.label,
    required this.icon,
    required this.isSelected,
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
                    ? cs.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.7),
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
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FadeInLeft(
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: PhobesTheme.animFast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? cs.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.6),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? cs.primary
                          : cs.onSurface.withValues(alpha: 0.8),
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
          ),
        ),
      ),
    );
  }
}

class DailyIntelligencePanel extends StatefulWidget {
  final VoidCallback? onNotificationTap;
  const DailyIntelligencePanel({super.key, this.onNotificationTap});

  @override
  State<DailyIntelligencePanel> createState() => _DailyIntelligencePanelState();
}

class _DailyIntelligencePanelState extends State<DailyIntelligencePanel> {
  final TextEditingController _noteController = TextEditingController();
  final WeatherService _weatherService = WeatherService();
  WeatherData? _weatherData;
  String _selectedCity = "İstanbul";
  bool _isLoadingWeather = false;
  Timer? _weatherRetryTimer;

  static const String _prefKeyCity = 'selected_weather_city';
  static const String _prefKeyWeatherData = 'cached_weather_data';

  @override
  void initState() {
    super.initState();
    _loadSavedNote();
    _initWeather();
    // Periodic check/retry every 30 seconds
    _weatherRetryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_weatherData == null ||
          _weatherData!.city == "İstanbul" && _weatherData!.tempC == "15") {
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
    // 1. First set default Istanbul data so UI isn't empty
    _weatherData = WeatherData(
      tempC: "15",
      feelsLikeC: "14",
      humidity: "60",
      windSpeed: "10",
      description: "Bulutlu",
      city: "İstanbul",
      forecast: [],
    );

    // 2. Load actual saved data from cache
    await _loadSavedWeather();

    // 3. Fetch fresh data
    _loadWeather();
  }

  Future<void> _loadSavedWeather() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selectedCity = prefs.getString(_prefKeyCity) ?? "İstanbul";
      final cachedJson = prefs.getString(_prefKeyWeatherData);

      if (cachedJson != null) {
        final Map<String, dynamic> data = jsonDecode(cachedJson);
        setState(() {
          _weatherData = WeatherData(
            tempC: data['tempC'] ?? "15",
            feelsLikeC: data['feelsLikeC'] ?? "14",
            humidity: data['humidity'] ?? "60",
            windSpeed: data['windSpeed'] ?? "10",
            description: data['description'] ?? "Bulutlu",
            city: data['city'] ?? "İstanbul",
            forecast: (data['forecast'] as List? ?? [])
                .map((f) => ForecastDay(
                      date: f['date'],
                      maxTemp: f['maxTemp'],
                      minTemp: f['minTemp'],
                      avgTemp: f['avgTemp'],
                      description: f['description'],
                    ))
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
                })
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
      debugPrint("Weather loading error: $e");
      if (mounted) {
        setState(() => _isLoadingWeather = false);
      }
    }
  }

  Future<void> _loadSavedNote() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _noteController.text = prefs.getString('quick_note') ??
          "Bugün odaklanman gereken ana görev projeyi bitirmek.";
      _selectedCity = prefs.getString('selected_city') ?? 'İstanbul';
    });
    // Load weather after city is loaded
    _loadWeather();
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

    // Adaptive spacing logic based on screen height
    final bool isCompact = screenHeight < 800;
    final double verticalPadding = isCompact ? 12.0 : 20.0;
    final double sectionGap = isCompact ? 20.0 : 32.0;

    String dayName = DateFormat('EEEE').format(now);
    String dateStr = DateFormat('d MMMM').format(now);

    try {
      dayName = DateFormat('EEEE', 'tr_TR').format(now);
      dateStr = DateFormat('d MMMM', 'tr_TR').format(now);
    } catch (_) {}

    return Container(
      width: 340,
      height: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          left: BorderSide(
            color: cs.outline.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(24, 4, 24, verticalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stack for Header and Notification Button
              Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: GoogleFonts.outfit(
                          fontSize: isCompact ? 28 : 36,
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
                          color: cs.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: PhobesIconButton(
                      icon: Icons.notifications_none_rounded,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.05),
                      onTap: widget.onNotificationTap ?? () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weather Card
              _buildWeatherCard(cs, isCompact),

              SizedBox(height: sectionGap),

              // Quick Note Section
              _buildSectionHeader(cs, Icons.edit_note_rounded, "Hızlı Not"),
              const SizedBox(height: 16),
              Container(
                height: isCompact ? 120 : 180,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.05)),
                ),
                child: TextField(
                  controller: _noteController,
                  maxLines: null,
                  expands: true,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    height: 1.6,
                    color: cs.onSurface.withValues(alpha: 0.8),
                  ),
                  decoration: InputDecoration(
                    hintText: "Bir şeyler not edin...",
                    hintStyle: GoogleFonts.outfit(
                      color: cs.onSurface.withValues(alpha: 0.3),
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
                text: "Kaydet",
                onPressed: () async {
                  await _saveNote();
                  if (context.mounted) {
                    PhobesSnackbar.show(context,
                        message: "Not başarıyla kaydedildi",
                        type: PhobesSnackbarType.success);
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
            color: cs.primary.withValues(alpha: 0.1),
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

  Widget _buildWeatherCard(ColorScheme cs, bool isCompact) {
    // If we have NO data at all (not even default), only then show the big spinner
    if (_weatherData == null) {
      return Container(
        width: double.infinity,
        height: 380,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 380), // Ensure stability
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _showCitySearch(),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCity,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70, size: 20),
                  ],
                ),
              ),
              if (_isLoadingWeather)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_weatherData!.tempC}°",
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _weatherData!.description,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              _getWeatherIcon(_weatherData!.description,
                  size: 64, color: Colors.white),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherStat(Icons.water_drop_rounded, "Nem",
                    "${_weatherData!.humidity}%"),
                _buildWeatherStat(Icons.air_rounded, "Rüzgar",
                    "${_weatherData!.windSpeed} km/h"),
                _buildWeatherStat(Icons.thermostat_rounded, "Hissedilen",
                    "${_weatherData!.feelsLikeC}°"),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildForecastSection(cs),
        ],
      ),
    );
  }

  Widget _buildForecastSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "3 Günlük Tahmin",
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _weatherData!.forecast.map((day) {
            return _buildForecastItem(day);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildForecastItem(ForecastDay day) {
    // Format date string (e.g., "2024-03-01") to day name
    String dayName = "Gün";
    try {
      final date = DateTime.parse(day.date);
      dayName = DateFormat('EEE', 'tr_TR').format(date);
    } catch (_) {
      dayName = day.date.split('-').last;
    }

    return Column(
      children: [
        Text(
          dayName,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        _getWeatherIcon(day.description, size: 24, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          "${day.avgTemp}°",
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _getWeatherIcon(String description, {double size = 24, Color? color}) {
    final desc = description.toLowerCase();
    IconData icon = Icons.wb_sunny_rounded;
    Color iconColor = color ?? Colors.orange;

    if (desc.contains('bulut') || desc.contains('cloud')) {
      icon = Icons.cloud_rounded;
    } else if (desc.contains('yağmur') || desc.contains('rain')) {
      icon = Icons.grain_rounded;
    } else if (desc.contains('kar') || desc.contains('snow')) {
      icon = Icons.ac_unit_rounded;
    } else if (desc.contains('fırtına') || desc.contains('storm')) {
      icon = Icons.thunderstorm_rounded;
    } else if (desc.contains('sis') || desc.contains('fog')) {
      icon = Icons.cloud_queue_rounded;
    }

    return Icon(icon, size: size, color: iconColor);
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
      'Barcelona'
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
      'Kepez'
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
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
                spreadRadius: -10,
              )
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.1),
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
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.public_rounded,
                          color: Theme.of(context).colorScheme.primary),
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
                                  .withValues(alpha: 0.5),
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
              city.toLowerCase().contains(_searchCtrl.text.toLowerCase()))
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
              color: cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.outline.withValues(alpha: 0.1)),
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Şehir veya ilçe ara...',
                hintStyle: GoogleFonts.outfit(
                    color: cs.onSurface.withValues(alpha: 0.3)),
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
                return _buildCityItem("Ara: \"${_searchCtrl.text}\"", true);
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
                  .withValues(alpha: 0.1),
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
              size: 18, color: cs.onSurface.withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          tileColor: cs.onSurface.withValues(alpha: 0.02),
          hoverColor: cs.primary.withValues(alpha: 0.05),
        ),
      ),
    );
  }
}
