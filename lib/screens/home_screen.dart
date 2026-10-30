import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/user_session_service.dart';
import 'schedule_view.dart';
import 'profile_view.dart';
import 'class_details_screen.dart';
import 'my_reservations_screen.dart';

/// Modelo de clase destacada (Featured Class)
class FeaturedClassItem {
  final String id;
  final String title;
  final String tag;
  final Color tagColor;
  final Color tagBorderColor;
  final Color tagBgColor;
  final String time;
  final String duration;
  final String spotsLabel;
  final bool hasSpots;
  final String networkImage;
  final String fallbackAsset;
  final String buttonLabel;
  final bool isPrimaryCta;
  bool isBooked;

  FeaturedClassItem({
    required this.id,
    required this.title,
    required this.tag,
    required this.tagColor,
    required this.tagBorderColor,
    required this.tagBgColor,
    required this.time,
    required this.duration,
    required this.spotsLabel,
    this.hasSpots = true,
    required this.networkImage,
    required this.fallbackAsset,
    required this.buttonLabel,
    this.isPrimaryCta = true,
    this.isBooked = false,
  });
}

/// Estado de la clase próxima
enum UpcomingStatus { confirmed, waitlist, open }

/// Modelo de clase próxima (Upcoming Class)
class UpcomingClassItem {
  final String id;
  final String dayLabel;
  final String time;
  final String title;
  final String instructorOrLocation;
  final bool isLocation;
  final String durationOrInfo;
  final UpcomingStatus status;
  final String category;

  UpcomingClassItem({
    required this.id,
    required this.dayLabel,
    required this.time,
    required this.title,
    required this.instructorOrLocation,
    this.isLocation = false,
    required this.durationOrInfo,
    required this.status,
    required this.category,
  });
}

class HomeScreen extends StatefulWidget {
  final String athleteName;

  const HomeScreen({
    super.key,
    this.athleteName = 'Javier',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  String _selectedCategory = 'All Classes';

  final List<String> _categories = [
    'All Classes',
    'Cardio',
    'Strength',
    'Morning',
    'HIIT',
  ];

  late List<FeaturedClassItem> _featuredClasses;
  late List<UpcomingClassItem> _upcomingClasses;

  @override
  void initState() {
    super.initState();
    _initData();
    UserSessionService.instance.addListener(_onSessionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncUserData();
    });
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _syncUserData() async {
    await UserSessionService.instance.syncUserRole();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    UserSessionService.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

  String get _greetingName {
    final session = UserSessionService.instance;
    final fullName = session.profile?.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }
    final sessionName = session.displayName.trim();
    if (sessionName.isNotEmpty &&
        sessionName != 'Atleta' &&
        sessionName != 'Admin') {
      return sessionName;
    }
    if (widget.athleteName.trim().isNotEmpty &&
        widget.athleteName != 'Javier') {
      return widget.athleteName.trim();
    }
    return sessionName.isNotEmpty ? sessionName : 'Atleta';
  }

  String? get _userAvatarUrl {
    final avatar = UserSessionService.instance.avatarUrl;
    if (avatar != null && avatar.trim().isNotEmpty) {
      return avatar.trim();
    }
    return null;
  }

  void _initData() {
    _featuredClasses = [
      // Card 1: CrossFit WOD (Primary Featured)
      FeaturedClassItem(
        id: '11111111-1111-1111-1111-111111111111',
        title: 'CrossFit WOD',
        tag: 'HIGH INTENSITY',
        tagColor: AppColors.primaryLight,
        tagBorderColor: AppColors.primaryContainer.withValues(alpha: 0.4),
        tagBgColor: AppColors.primaryContainer.withValues(alpha: 0.25),
        time: '18:00',
        duration: '60 min',
        spotsLabel: '4 spots',
        hasSpots: true,
        networkImage:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAJiiThq9ZWAuOiIvdMp-QgJ8RZUVNIzKYJGIOvEnWFNcakn6LTSaaawciBCWi0M49KnpJknXhhFn7GbexJlEKb8Kzh1TiugcWh2ZVo92q12rf42DiBFU9cpha44R_7Rsz7W-k0uUufLVVOagRrNbL7cQ6q2yt_J78lj3YUInRan4D1Hx3agxTYX-zA8ZqmMa4brJb3_RAq87J7K6XVSQ35zt-ydMGXIs-lbOzq_ZQ_DTGCTgXq8HPo9A',
        fallbackAsset: 'assets/images/crossfit_wod.jpg',
        buttonLabel: 'Reservar',
        isPrimaryCta: true,
      ),
      // Card 2: Power Yoga (Peeking Carousel Card)
      FeaturedClassItem(
        id: '22222222-2222-2222-2222-222222222222',
        title: 'Power Yoga',
        tag: 'FLEXIBILITY',
        tagColor: AppColors.tertiary,
        tagBorderColor: AppColors.tertiary.withValues(alpha: 0.3),
        tagBgColor: const Color(0xFFD58800).withValues(alpha: 0.2),
        time: '07:00',
        duration: '50 min',
        spotsLabel: 'Full',
        hasSpots: false,
        networkImage:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuALr1eGwFb7HyPA21l1-0mU4iip9aNYxPi5Q0oQaTkgmPOR6FX-Kc7Es6QNDyUY4e5TTPi2lPKWcI3w2z5LHYoaSyCFiXfRXCrJxDQGHDQElzOswgTnbGc03lyWqMNS7XJxls9SN-GiPmJlEEmEG7YXjEV1aiLUeFjOOnQJUFdIS8ssdnb-xglm18PUd5MhspqeEmMs61bRGkwSV0m8bJVOqyh-aZ_1VMoopj054RU_nuhKFH6enqrktA',
        fallbackAsset: 'assets/images/power_yoga.jpg',
        buttonLabel: 'Join Waitlist',
        isPrimaryCta: false,
      ),
    ];

    _upcomingClasses = [
      // Class Card 1: HIIT Advanced
      UpcomingClassItem(
        id: '33333333-3333-3333-3333-333333333333',
        dayLabel: 'TODAY',
        time: '19:00',
        title: 'HIIT Advanced',
        instructorOrLocation: 'Coach Sarah',
        durationOrInfo: '45m',
        status: UpcomingStatus.confirmed,
        category: 'HIIT',
      ),
      // Class Card 2: Spin Cycle
      UpcomingClassItem(
        id: '22222222-2222-2222-2222-222222222222',
        dayLabel: 'TOMORROW',
        time: '08:00',
        title: 'Spin Cycle',
        instructorOrLocation: 'Coach Mike',
        durationOrInfo: '50m',
        status: UpcomingStatus.waitlist,
        category: 'Cardio',
      ),
      // Class Card 3: Open Gym
      UpcomingClassItem(
        id: '11111111-1111-1111-1111-111111111111',
        dayLabel: 'FRI',
        time: '12:00',
        title: 'Open Gym',
        instructorOrLocation: 'Main Floor',
        isLocation: true,
        durationOrInfo: 'Pass Included',
        status: UpcomingStatus.open,
        category: 'Strength',
      ),
    ];
  }

  List<UpcomingClassItem> get _filteredUpcomingClasses {
    if (_selectedCategory == 'All Classes') {
      return _upcomingClasses;
    }
    return _upcomingClasses
        .where((c) => c.category.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
  }

  Future<void> _openClassDetails(FeaturedClassItem item) async {
    ClassScheduleModel? schedule;
    try {
      final schedules = await DatabaseService.instance.getSchedules();
      schedule = schedules.firstWhere(
        (s) => s.id == item.id || s.classId == item.id,
        orElse: () => ClassScheduleModel(
          id: item.id,
          classId: 'class-${item.id}',
          startTime: DateTime.now().add(const Duration(hours: 2)),
          endTime: DateTime.now().add(const Duration(hours: 3)),
          capacity: 20,
          confirmedBookingsCount: item.hasSpots ? 16 : 20,
          locationName: 'Main Arena • Studio A',
          gymClass: GymClassModel(
            id: 'class-${item.id}',
            name: item.title,
            imageUrl: item.networkImage,
            durationMinutes: int.tryParse(item.duration.replaceAll(RegExp(r'[^0-9]'), '')) ?? 45,
            intensity: item.tag.contains('HIGH')
                ? ClassIntensity.high
                : (item.tag.contains('LOW') ? ClassIntensity.low : ClassIntensity.medium),
            basePrice: 25.0,
            description:
                'Sesión de entrenamiento de alto impacto diseñada para maximizar fuerza, resistencia cardiovascular y quema de calorías.',
          ),
          instructor: const InstructorModel(
            id: 'inst-sarah',
            name: 'Coach Sarah',
            avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
            bio: 'Head Coach de acondicionamiento metabólico y circuitos de potencia.',
            rating: 4.9,
          ),
        ),
      );
    } catch (_) {
      // Fallback
    }

    if (!mounted || schedule == null) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClassDetailsScreen(
          schedule: schedule!,
          isInitialBooked: item.isBooked,
        ),
      ),
    );

    if (updated != null && mounted) {
      setState(() {
        item.isBooked = updated;
      });
    }
  }

  Future<void> _openUpcomingClassDetails(UpcomingClassItem item) async {
    ClassScheduleModel? schedule;
    try {
      final schedules = await DatabaseService.instance.getSchedules();
      schedule = schedules.firstWhere(
        (s) => s.id == item.id || s.classId == item.id,
        orElse: () => ClassScheduleModel(
          id: item.id,
          classId: 'class-${item.id}',
          startTime: DateTime.now().add(const Duration(hours: 3)),
          endTime: DateTime.now().add(const Duration(hours: 4)),
          capacity: 20,
          confirmedBookingsCount: 15,
          locationName: item.instructorOrLocation,
          gymClass: GymClassModel(
            id: 'class-${item.id}',
            name: item.title,
            imageUrl: 'https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800',
            durationMinutes: int.tryParse(item.durationOrInfo.replaceAll(RegExp(r'[^0-9]'), '')) ?? 45,
            intensity: ClassIntensity.medium,
            basePrice: 20.0,
            description: 'Sesión de entrenamiento de alto impacto en Iron Pulse.',
          ),
          instructor: InstructorModel(
            id: 'inst-${item.id}',
            name: item.instructorOrLocation,
            avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
            bio: 'Coach especialista en acondicionamiento físico.',
            rating: 4.9,
          ),
        ),
      );
    } catch (_) {}

    if (!mounted || schedule == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClassDetailsScreen(schedule: schedule!),
      ),
    );
  }

  void _showNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF111319),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0xFF3E4850), width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notificaciones',
                    style: AppTypography.style(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    '2 nuevas',
                    style: AppTypography.style(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildNotificationItem(
                title: 'Tu clase de CrossFit WOD está confirmada',
                time: 'Hace 15 min',
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.secondary,
              ),
              const SizedBox(height: 10),
              _buildNotificationItem(
                title: 'Spin Cycle tiene 1 cupo disponible',
                time: 'Hace 1 hora',
                icon: Icons.bolt_rounded,
                iconColor: AppColors.primaryLight,
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.style(
                    color: AppColors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: AppTypography.style(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget currentBody;
    switch (_currentNavIndex) {
      case 1:
        currentBody = const ScheduleView();
        break;
      case 2:
        currentBody = MyReservationsScreen(
          isFromBottomNav: true,
          onNavigateToHome: () => setState(() => _currentNavIndex = 0),
          onNavigateToExplore: () => setState(() => _currentNavIndex = 1),
        );
        break;
      case 3:
        currentBody = const ProfileView();
        break;
      case 0:
      default:
        currentBody = _buildHomeDashboard();
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: currentBody,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHomeDashboard() {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // 1. TopAppBar (Avatar + Saludo "Hola, Javier 👋" + Notificaciones)
            _buildTopAppBar(),
            const SizedBox(height: 24),

            // 2. Featured Classes Section (Title + See All + Swipeable Carousel)
            _buildFeaturedClassesSection(),
            const SizedBox(height: 20),

            // 3. Filter Pills Carousel (All Classes, Cardio, Strength, etc.)
            _buildFilterPillsCarousel(),
            const SizedBox(height: 24),

            // 4. Upcoming Classes Section (Header + Badge 13 + List of 3 Cards)
            _buildUpcomingClassesSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 1. TOP APP BAR (Avatar con estado + Hola, Javier 👋 + Notificaciones)
  // =========================================================================
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Avatar + Title & Subtitle
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with secondary status indicator (Tapping navigates to Profile)
                GestureDetector(
                  onTap: () => setState(() => _currentNavIndex = 3),
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surfaceContainerHigh,
                          border: Border.all(
                            color: const Color(0xFF00A3E0),
                            width: 1.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: _userAvatarUrl != null
                              ? Image.network(
                                  _userAvatarUrl!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(
                                    child: Icon(
                                      Icons.person_rounded,
                                      color: AppColors.primaryLight,
                                      size: 22,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: AppColors.primaryLight,
                                    size: 22,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF111319),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Greeting Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Hola, $_greetingName',
                              style: AppTypography.style(
                                color: AppColors.onSurface,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '👋',
                            style: TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ready to crush your goals today?',
                        style: AppTypography.style(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: Notifications Button & Logout Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: _showNotificationsSheet,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.onSurface,
                        size: 22,
                      ),
                      // Electric cyan indicator dot with glow
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00A3E0).withValues(alpha: 0.8),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Botón Cerrar Sesión (Cliente)
              GestureDetector(
                onTap: () => AuthService.instance.showLogoutDialog(context),
                behavior: HitTestBehavior.opaque,
                child: Tooltip(
                  message: 'Cerrar Sesión',
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFEF4444),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. FEATURED CLASSES SECTION (Title + See All + Horizontal Swipeable Carousel)
  // =========================================================================
  Widget _buildFeaturedClassesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Featured Classes',
                style: AppTypography.style(
                  color: AppColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentNavIndex = 1;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Mostrar todas',
                      style: AppTypography.style(
                        color: AppColors.primaryLight,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primaryLight,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Carousel of 2 Featured Cards (CrossFit WOD & Power Yoga)
        SizedBox(
          height: 360,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _featuredClasses.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = _featuredClasses[index];
              return _buildFeaturedCard(item, isPrimary: index == 0);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(FeaturedClassItem item, {required bool isPrimary}) {
    final cardWidth = isPrimary ? 290.0 : 240.0;

    return Container(
      width: cardWidth,
      height: 360,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image (Local asset with network fallback)
            Image.asset(
              item.fallbackAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.network(
                  item.networkImage,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) {
                    return Container(
                      color: AppColors.surfaceContainerHigh,
                      child: const Center(
                        child: Icon(
                          Icons.fitness_center_rounded,
                          color: AppColors.outlineVariant,
                          size: 48,
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Dark Vignette Gradient for Readability
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color(0xFF111319),
                    Color(0x99111319),
                    Color(0x4D111319),
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
              ),
            ),

            // Top Row Badges
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Category Tag
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: item.tagBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: item.tagBorderColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        item.tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.style(
                          color: item.tagColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Spots / Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: item.hasSpots
                            ? AppColors.secondary.withValues(alpha: 0.3)
                            : AppColors.outlineVariant.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.hasSpots) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4EDEA3).withValues(alpha: 0.8),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          item.spotsLabel,
                          style: AppTypography.style(
                            color: item.hasSpots
                                ? AppColors.secondary
                                : AppColors.onSurfaceVariant,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Card Bottom Content
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Class Title
                  Text(
                    item.title,
                    style: AppTypography.style(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Schedule Row: Clock + Time • Duration
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: isPrimary
                            ? AppColors.primaryLight
                            : AppColors.tertiary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.time,
                        style: AppTypography.style(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '•',
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.duration,
                        style: AppTypography.style(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Button CTA
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => _openClassDetails(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: item.isBooked
                            ? const Color(0xFF003824)
                            : (item.isPrimaryCta
                                ? AppColors.primaryContainer
                                : AppColors.surfaceContainerHigh.withValues(alpha: 0.9)),
                        foregroundColor: item.isBooked
                            ? AppColors.secondary
                            : (item.isPrimaryCta
                                ? Colors.white
                                : AppColors.onSurface),
                        elevation: 0,
                        shadowColor: item.isPrimaryCta
                            ? const Color(0x5900A3E0)
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: item.isBooked
                                ? AppColors.secondary
                                : (item.isPrimaryCta
                                    ? Colors.transparent
                                    : Colors.white.withValues(alpha: 0.1)),
                            width: 1,
                          ),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (item.isBooked) ...[
                            const Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            item.isBooked ? 'Reservado' : item.buttonLabel,
                            style: AppTypography.style(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: item.isBooked
                                  ? AppColors.secondary
                                  : (item.isPrimaryCta
                                      ? Colors.white
                                      : AppColors.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // 3. FILTER PILLS CAROUSEL (All Classes, Cardio, Strength, Morning, HIIT)
  // =========================================================================
  Widget _buildFilterPillsCarousel() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : Colors.white.withValues(alpha: 0.04),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0x5900A3E0),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                category,
                style: AppTypography.style(
                  color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // =========================================================================
  // 4. UPCOMING CLASSES SECTION (Header + Badge 13 + List of 3 Cards)
  // =========================================================================
  Widget _buildUpcomingClassesSection() {
    final classesToShow = _filteredUpcomingClasses;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title + 13 Badge + Link a Mis Reservas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Upcoming Classes',
                    style: AppTypography.style(
                      color: AppColors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.outlineVariant.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '13',
                      style: AppTypography.style(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _currentNavIndex = 2),
                child: Text(
                  'Mis Reservas',
                  style: AppTypography.style(
                    color: AppColors.primaryLight,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cards list
          if (classesToShow.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36),
              alignment: Alignment.center,
              child: Text(
                'No hay clases para "$_selectedCategory"',
                style: AppTypography.style(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: classesToShow.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = classesToShow[index];
                return _buildUpcomingClassCard(item);
              },
            ),

          const SizedBox(height: 14),

          // Botón explícito para mostrar todas las clases disponibles
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _currentNavIndex = 1),
              icon: const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primaryLight),
              label: Text(
                'Mostrar todas las clases',
                style: AppTypography.style(
                  color: AppColors.primaryLight,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primaryLight.withValues(alpha: 0.35), width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingClassCard(UpcomingClassItem item) {
    return GestureDetector(
      onTap: () => _openUpcomingClassDetails(item),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Time Capsule Container (Responsive capsule)
            Container(
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.04),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.dayLabel,
                    maxLines: 1,
                    style: AppTypography.style(
                      color: AppColors.outline,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.time,
                    maxLines: 1,
                    style: AppTypography.style(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // Center Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.style(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        item.isLocation
                            ? Icons.fitness_center_rounded
                            : Icons.person_rounded,
                        color: AppColors.primaryLight,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.instructorOrLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.style(
                            color: AppColors.primaryLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '•',
                        style: TextStyle(
                          color: AppColors.outlineVariant,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (!item.isLocation) ...[
                        const Icon(
                          Icons.timer_outlined,
                          color: AppColors.outline,
                          size: 13,
                        ),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        item.durationOrInfo,
                        style: AppTypography.style(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Right Status Badge Pill
            _buildStatusBadge(item.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(UpcomingStatus status) {
    Color textColor;
    Color bgColor;
    Color borderColor;
    String label;

    switch (status) {
      case UpcomingStatus.confirmed:
        label = 'CONFIRMED';
        textColor = AppColors.secondary;
        bgColor = AppColors.secondary.withValues(alpha: 0.15);
        borderColor = AppColors.secondary.withValues(alpha: 0.3);
        break;
      case UpcomingStatus.waitlist:
        label = 'WAITLIST';
        textColor = AppColors.tertiary;
        bgColor = AppColors.tertiary.withValues(alpha: 0.15);
        borderColor = AppColors.tertiary.withValues(alpha: 0.3);
        break;
      case UpcomingStatus.open:
        label = 'OPEN';
        textColor = AppColors.onSurfaceVariant;
        bgColor = AppColors.surfaceContainerHigh;
        borderColor = AppColors.outlineVariant.withValues(alpha: 0.3);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.style(
          color: textColor,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  // =========================================================================
  // 5. BOTTOM NAVIGATION BAR (Home [Active], Schedule, Profile, Settings)
  // =========================================================================
  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
              ),
              _buildBottomNavItem(
                index: 1,
                icon: Icons.calendar_month_rounded,
                label: 'Classes',
              ),
              _buildBottomNavItem(
                index: 2,
                icon: Icons.bookmark_border_rounded,
                label: 'Bookings',
              ),
              _buildBottomNavItem(
                index: 3,
                icon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentNavIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Destination Icon Capsule
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue.withValues(alpha: 0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.navInactive,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.style(
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.navInactive,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
