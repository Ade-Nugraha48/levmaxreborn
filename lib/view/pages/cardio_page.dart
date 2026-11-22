import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../controller/cardio_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/stat_calculator.dart';
import '../widgets/grid_background.dart';

/// Screen 4: Map & Cardio Tracking Page (Mobile Tab 1)
/// Features OpenStreetMap with dark color matrix, Neon Pink polyline route,
/// real-time Open-Meteo weather HUD, GPS tracking with distanceFilter: 5m,
/// anti-cheat protection (<= 24 km/h), demo simulation (+500m), and telemetry drawer.
/// Conforms to `stitch_exports/02_cardio_tracking.html` and `docs/design_blueprint.md`.
class CardioPage extends StatelessWidget {
  const CardioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<CardioController>()
        ? Get.find<CardioController>()
        : Get.put(CardioController());

    final mapController = MapController();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: GridBackground(
          child: Column(
            children: [
              // 1. Top Bar: MAP title + Tactical Terminal Emblem
              _buildTopBar(),

              // 2. Main Layout (Scrollable for smaller viewports)
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 8),
                  child: Obx(() {
                    return Column(
                      children: [
                        // Upper Section: 61.8% Focus Map Canvas
                        _buildMapCanvas(controller, mapController),
                        const SizedBox(height: 14),

                        // Lower Section: 38.2% Telemetry Drawer
                        _buildTelemetryDrawer(context, controller, mapController),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 1. TOP BAR
  // ==========================================

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 21),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderHairline, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'MAP',
            style: GoogleFonts.cinzel(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
              color: AppColors.textPrimary,
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceElevated,
              border: Border.all(color: AppColors.borderHairline),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.terminal,
                size: 17,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. UPPER SECTION: MAP CANVAS
  // ==========================================

  Widget _buildMapCanvas(
    CardioController controller,
    MapController mapController,
  ) {
    final LatLng centerPoint = controller.routePoints.isNotEmpty
        ? controller.routePoints.last
        : const LatLng(-7.7828, 110.3670); // Default Yogyakarta coordinates

    return Container(
      height: 360,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0B0E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // FlutterMap with Cyberpunk Inverted Matrix
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: centerPoint,
                initialZoom: 15.5,
                minZoom: 10.0,
                maxZoom: 18.0,
              ),
              children: [
                // Dark Matrix Filtered OpenStreetMap Tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.levmax.app',
                  tileBuilder: (context, tileWidget, tile) {
                    return ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        -0.8, 0, 0, 0, 255,
                        0, -0.8, 0, 0, 255,
                        0, 0, -0.8, 0, 255,
                        0, 0, 0, 1, 0,
                      ]),
                      child: tileWidget,
                    );
                  },
                ),

                // Neon Pink Polyline Layer (Glow + Solid Core)
                if (controller.routePoints.length >= 2) ...[
                  // Outer Glow Line
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: controller.routePoints.toList(),
                        strokeWidth: 8.0,
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                  // Core Solid Line
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: controller.routePoints.toList(),
                        strokeWidth: 3.5,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ],

                // Live Beacon Marker at Latest Position
                if (controller.routePoints.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: controller.routePoints.last,
                        width: 32,
                        height: 32,
                        child: _buildPulsingBeacon(),
                      ),
                    ],
                  ),
              ],
            ),

            // Floating Weather & Target Overlay HUD Pill
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _buildFloatingWeatherPill(controller),
            ),

            // Bottom Map Sector Label
            Positioned(
              bottom: 10,
              left: 14,
              child: Text(
                'GRID SECTOR 09 · DOWNTOWN ROUTE',
                style: GoogleFonts.cinzel(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.textSecondary.withValues(alpha: 0.75),
                ),
              ),
            ),

            // Anti-Cheat Warning Badge
            if (controller.antiCheatWarning.value)
              Positioned(
                bottom: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(color: AppColors.errorRed),
                  ),
                  child: Text(
                    'SPEED > 24 KM/H · FILTERED',
                    style: GoogleFonts.dotGothic16(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.errorRed,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulsingBeacon() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.25),
              border: Border.all(color: AppColors.primary, width: 1.2),
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.8),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingWeatherPill(CardioController controller) {
    final weather = controller.weather.value;
    final weatherText = weather != null
        ? weather.displayTelemetry
        : '28°C · CLEAR SKY';
    final targetKm = controller.targetKm.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Weather readout
          Row(
            children: [
              const Icon(
                Icons.wb_sunny_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                weatherText,
                style: GoogleFonts.dotGothic16(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          // Target distance in Yellow
          Text(
            'TARGET: $targetKm KM',
            style: GoogleFonts.dotGothic16(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: AppColors.highlightYellow,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. LOWER SECTION: TELEMETRY DRAWER
  // ==========================================

  Widget _buildTelemetryDrawer(
    BuildContext context,
    CardioController controller,
    MapController mapController,
  ) {
    final isTracking = controller.isTracking.value;
    final isPaused = controller.isPaused.value;
    final isDone = controller.isAlreadyCompletedToday;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer Header Row: Label & Status Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SESSION TELEMETRY',
                style: GoogleFonts.dotGothic16(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isTracking
                          ? (isPaused ? AppColors.highlightYellow : AppColors.primary)
                          : (isDone ? AppColors.secondary : AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isTracking
                        ? (isPaused ? 'PAUSED' : 'ACTIVE LOG')
                        : (isDone ? 'COMPLETED' : 'STANDBY PROTOCOL'),
                    style: GoogleFonts.dotGothic16(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isTracking
                          ? (isPaused ? AppColors.highlightYellow : AppColors.primary)
                          : (isDone ? AppColors.secondary : AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3-Metrics Telemetry Grid
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Row(
              children: [
                // DISTANCE
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'DISTANCE',
                        style: GoogleFonts.dotGothic16(
                          fontSize: 9.5,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      RichText(
                        text: TextSpan(
                          text: controller.distanceKm.toStringAsFixed(2),
                          style: GoogleFonts.dotGothic16(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.highlightYellow,
                          ),
                          children: [
                            TextSpan(
                              text: ' km',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.highlightYellow,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 1,
                  height: 36,
                  color: AppColors.borderHairline,
                ),

                // AVG PACE
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'AVG PACE',
                        style: GoogleFonts.dotGothic16(
                          fontSize: 9.5,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        controller.formattedPace,
                        style: GoogleFonts.dotGothic16(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Vertical Divider
                Container(
                  width: 1,
                  height: 36,
                  color: AppColors.borderHairline,
                ),

                // DURATION
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'DURATION',
                        style: GoogleFonts.dotGothic16(
                          fontSize: 9.5,
                          letterSpacing: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        controller.formattedDuration,
                        style: GoogleFonts.dotGothic16(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Cyan Progress Bar Track
          LayoutBuilder(
            builder: (context, constraints) {
              final double trackWidth = constraints.maxWidth;
              final double fillWidth =
                  (trackWidth * controller.progressRatio).clamp(0.0, trackWidth);

              return Container(
                width: double.infinity,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2538),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      width: fillWidth,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.secondary.withValues(alpha: 0.6),
                            blurRadius: 6,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 6),

          // Progress percentage and remaining km
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${controller.percentage}% COMPLETED',
                style: GoogleFonts.dotGothic16(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${controller.remainingKm.toStringAsFixed(2)} KM REMAINING',
                style: GoogleFonts.dotGothic16(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Buttons Dock
          if (!isTracking) ...[
            // Standby Mode: Start Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: isDone ? null : () => controller.startCardio(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDone ? AppColors.surfaceElevated : AppColors.primary,
                  disabledBackgroundColor: AppColors.surfaceElevated,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                    side: BorderSide(
                      color: isDone ? AppColors.borderHairline : AppColors.primary,
                    ),
                  ),
                  elevation: isDone ? 0 : 4,
                  shadowColor: isDone ? null : AppColors.primary.withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isDone ? Icons.done_all : Icons.play_arrow,
                      size: 20,
                      color: isDone ? AppColors.secondary : const Color(0xFF05060A),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isDone ? 'CARDIO PROTOCOL COMMITTED' : 'START CARDIO',
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                        color: isDone ? AppColors.secondary : const Color(0xFF05060A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Tracking Mode: Pause & Finish Run Buttons
            Row(
              children: [
                // Pause / Resume Button
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => controller.togglePause(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.surfaceElevated,
                        side: BorderSide(
                          color: isPaused ? AppColors.primary : AppColors.borderHairline,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPaused ? Icons.play_arrow : Icons.pause,
                            size: 18,
                            color: isPaused ? AppColors.primary : AppColors.textPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPaused ? 'RESUME' : 'PAUSE',
                            style: GoogleFonts.dotGothic16(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: isPaused ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Finish Run Button
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => _handleFinishRun(context, controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.stop,
                            size: 18,
                            color: Color(0xFF05060A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'FINISH RUN',
                            style: GoogleFonts.cinzel(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: const Color(0xFF05060A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // Developer / Demo Mode Simulation Button (+500m)
          Center(
            child: TextButton.icon(
              onPressed: () {
                controller.simulateAddDistance(meters: 500.0);
                if (controller.routePoints.isNotEmpty) {
                  mapController.move(controller.routePoints.last, 16.0);
                }
              },
              icon: const Icon(
                Icons.speed_outlined,
                size: 15,
                color: AppColors.secondary,
              ),
              label: Text(
                'SIMULATE +500M (DEMO BOOST)',
                style: GoogleFonts.dotGothic16(
                  fontSize: 10.5,
                  letterSpacing: 1.2,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. FINISH RUN & LEVEL UP DIALOG
  // ==========================================

  Future<void> _handleFinishRun(
    BuildContext context,
    CardioController controller,
  ) async {
    // Check if target distance is met and duration > 0
    if (controller.distanceKm < controller.targetKm || controller.durationSeconds.value <= 0) {
      _showIncompleteRunDialog(context, controller);
      return;
    }

    final result = await controller.finishRun();
    if (result != null) {
      if (result.levelUpResult.didLevelUp) {
        if (context.mounted) {
          _showLevelUpDialog(context, result.levelUpResult);
        }
      } else {
        Get.snackbar(
          'CARDIO PROTOCOL COMMITTED',
          '+2 END · +${result.statRewards['SPD'] ?? 1} SPD · +25 EXP ACQUIRED',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surfaceElevated,
          colorText: AppColors.primary,
          borderWidth: 1,
          borderColor: AppColors.primary.withValues(alpha: 0.4),
        );
      }
    }
  }

  void _showIncompleteRunDialog(
    BuildContext context,
    CardioController controller,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.borderHairline, width: 1.0),
        ),
        title: Center(
          child: Text(
            'TARGET BELUM TERCAPAI',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.highlightYellow,
              letterSpacing: 2.0,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${controller.distanceKm.toStringAsFixed(2)} / ${controller.targetKm.toStringAsFixed(2)} KM',
              style: GoogleFonts.dotGothic16(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Target jarak belum tercapai. Menghentikan sesi sekarang tidak akan memberikan EXP, Stats, atau catatan riwayat.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    controller.cancelRun();
                    Get.snackbar(
                      'SESI CARDIO DIBATALKAN',
                      'Sesi cardio dibatalkan tanpa reward.',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: AppColors.surfaceElevated,
                      colorText: AppColors.textSecondary,
                      borderWidth: 1,
                      borderColor: AppColors.borderHairline,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF33343A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    'BATALKAN SESI\n(TANPA REWARD)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.errorRed,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'LANJUTKAN\nLARI',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF05060A),
                      letterSpacing: 0.5,
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

  void _showLevelUpDialog(BuildContext context, LevelUpResult levelUp) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        title: Center(
          child: Text(
            'LEVEL UP PROTOCOL',
            style: GoogleFonts.cinzel(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 2.0,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ASCENSION ATTAINED',
              style: GoogleFonts.cinzel(
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'LV. ${levelUp.newLevel}',
              style: GoogleFonts.dotGothic16(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.highlightYellow,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Text(
                '+2 ALL ATTRIBUTES · LIMIT BREAK',
                style: GoogleFonts.dotGothic16(
                  fontSize: 12,
                  color: AppColors.secondary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Text(
                'CLAIM ASCENSION',
                style: GoogleFonts.cinzel(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF05060A),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
