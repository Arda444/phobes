import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'calendar_screen.dart';
import 'team_screen.dart';
import 'account_screen.dart';
import 'nova_chat_screen.dart';
import 'statistics_screen.dart';
import 'focus_screen.dart';
import 'habit_screen.dart';
import '../l10n/app_localizations.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  // Alt menüdeki aktif ikon (Highlight için)
  int _selectedIndex = 0;

  // Ekranda fiilen gösterilen sayfa (IndexedStack için)
  // Bunu ayırdık ki menü açılınca arka plan değişmesin.
  int _visualIndex = 0;

  bool _isMenuOpen = false;

  // "Yaşam" sekmesi için varsayılan ekran
  Widget _currentLifeWidget = const StatisticsScreen();
  String _lifeTitle = "İstatistik";

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _updateWidgetOptions();
  }

  void _updateWidgetOptions() {
    _widgetOptions = [
      const CalendarScreen(), // 0
      const TeamScreen(), // 1
      const NovaChatScreen(), // 2
      _currentLifeWidget, // 3 (Değişken ekran)
      const AccountScreen(), // 4
    ];
  }

  void _onItemTapped(int index) {
    // Eğer "Yaşam" (3) butonuna basıldıysa:
    if (index == 3) {
      setState(() {
        if (_isMenuOpen) {
          // Menü zaten açıksa kapat ve görseli eski haline döndür
          _isMenuOpen = false;
          _selectedIndex = _visualIndex; // İkonu da eski sayfaya döndür
        } else {
          // Menü kapalıysa aç
          _isMenuOpen = true;
          _selectedIndex = 3; // İkonu 'X' yap
          // DİKKAT: _visualIndex'i değiştirmiyoruz!
          // Böylece arka planda eski sayfa kalıyor.
        }
      });
      return;
    }

    // Diğer sekmelere basılırsa normal geçiş yap
    setState(() {
      _selectedIndex = index;
      _visualIndex = index; // Hem ikonu hem sayfayı güncelle
      _isMenuOpen = false; // Menü açıksa kapat
    });
  }

  // Pop-up menüden seçim yapıldığında
  void _selectLifeOption(Widget widget, String title) {
    setState(() {
      _currentLifeWidget = widget;
      _lifeTitle = title;
      _updateWidgetOptions(); // Widget listesini güncelle

      _visualIndex = 3; // Artık sayfayı "Yaşam" sekmesine çevir
      _selectedIndex = 3; // İkon "Yaşam"da kalsın
      _isMenuOpen = false; // Menüyü kapat
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Stack(
        children: [
          // 1. ANA İÇERİK (IndexedStack _visualIndex kullanıyor)
          IndexedStack(index: _visualIndex, children: _widgetOptions),

          // 2. KARARTMA EFEKTİ
          if (_isMenuOpen)
            GestureDetector(
              onTap: () => setState(() {
                _isMenuOpen = false;
                _selectedIndex = _visualIndex; // Kapatınca ikonu düzelt
              }),
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                width: double.infinity,
                height: double.infinity,
              ),
            ),

          // 3. POP-UP MENÜ BUTONLARI
          if (_isMenuOpen)
            Positioned(
              bottom: 20,
              right: 70,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FadeInUp(
                    duration: const Duration(milliseconds: 200),
                    child: _buildMenuButton(
                      icon: Icons.check_box_rounded,
                      label: "Alışkanlık",
                      color: Colors.green,
                      onTap: () =>
                          _selectLifeOption(const HabitScreen(), "Alışkanlık"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    duration: const Duration(milliseconds: 300),
                    child: _buildMenuButton(
                      icon: Icons.timer_rounded,
                      label: "Odak Modu",
                      color: Colors.orange,
                      onTap: () =>
                          _selectLifeOption(const FocusScreen(), "Odak"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    child: _buildMenuButton(
                      icon: Icons.bar_chart_rounded,
                      label: "İstatistik",
                      color: Colors.blue,
                      onTap: () => _selectLifeOption(
                          const StatisticsScreen(), "İstatistik"),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_month_rounded),
                label: l10n.navCalendar),

            BottomNavigationBarItem(
                icon: const Icon(Icons.group_work_rounded),
                label: l10n.navTeams),

            BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2
                        ? Colors.teal
                        : Colors.teal.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    boxShadow: _selectedIndex == 2
                        ? [
                            BoxShadow(
                                color: Colors.teal.withValues(alpha: 0.5),
                                blurRadius: 10)
                          ]
                        : [],
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white),
                ),
                label: 'Nova'),

            // YAŞAM BUTONU
            BottomNavigationBarItem(
                icon: Icon(
                    _isMenuOpen
                        ? Icons.close_rounded
                        : Icons.dashboard_customize_rounded,
                    color: _selectedIndex == 3 ? Colors.white : Colors.grey),
                label:
                    _selectedIndex == 3 && !_isMenuOpen ? _lifeTitle : "Yaşam"),

            BottomNavigationBarItem(
                icon: const Icon(Icons.person_rounded), label: l10n.navAccount),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: const Color(0xFF1A1A1A),
          selectedItemColor: Colors.purple.shade300,
          unselectedItemColor: Colors.grey.shade600,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)
              ],
            ),
            child: Text(label,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 1)
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }
}
