import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../router/app_router.dart';
import '../../config/theme.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _entranceController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;

  final List<AppFeature> _features = [
    AppFeature(
      title: 'Smart Analytics',
      description:
          'AI-powered insights for weight prediction and health monitoring',
      icon: Icons.auto_graph,
      color: const Color(0xFF2E7D32),
    ),
    AppFeature(
      title: 'Livestock Tracking',
      description:
          'Comprehensive digital records for every animal on your farm',
      icon: Icons.pets,
      color: const Color(0xFF1565C0),
    ),
    AppFeature(
      title: 'Breeding Management',
      description: 'Optimize breeding cycles and improve herd genetics',
      icon: Icons.favorite,
      color: const Color(0xFFD81B60),
    ),
    AppFeature(
      title: 'Financial Health',
      description:
          'Track expenses, feed costs, and profit margins in real-time',
      icon: Icons.monetization_on,
      color: const Color(0xFFF9A825),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _entranceController.forward();

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _features.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Animated Background
          const Positioned.fill(child: _AnimatedBackground()),

          SafeArea(
            child: isDesktop
                ? _buildDesktopLayout(size)
                : _buildMobileLayout(size),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(Size size) {
    return Stack(
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(60.0),
                child: _buildHeroContent(centered: false),
              ),
            ),
            Expanded(
              flex: 6,
              child: Center(
                child: SizedBox(
                  height: 500,
                  child: _buildFeatureCards(isDesktop: true),
                ),
              ),
            ),
          ],
        ),
        // Documentation link at bottom
        Positioned(
          bottom: 24,
          left: 60,
          child: TextButton.icon(
            onPressed: () => coordinator.push(DocumentationRoute()),
            icon: const Icon(Icons.menu_book, size: 20),
            label: Text(
              'View Documentation',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
            style: TextButton.styleFrom(foregroundColor: AppTheme.farmGreen),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(Size size) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: _buildHeroContent(centered: true),
          ),
          SizedBox(height: 420, child: _buildFeatureCards(isDesktop: false)),
          const SizedBox(height: 20),
          // Documentation link
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _buildDocumentationLink(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDocumentationLink() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.farmGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book,
              color: AppTheme.farmGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Documentation',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Learn how to use Farm Manager with our comprehensive guide',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => coordinator.push(DocumentationRoute()),
            icon: const Icon(Icons.arrow_forward_ios),
            color: AppTheme.farmGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroContent({required bool centered}) {
    final align = centered
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 50 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.farmGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.agriculture,
                  color: AppTheme.farmGreen,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Farm Manager',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.farmGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 100, // Increased height to prevent text overflow overlap
            child: AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'Future of Farming',
                  textStyle: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                  speed: const Duration(milliseconds: 100),
                ),
                TypewriterAnimatedText(
                  'Data Driven Growth',
                  textStyle: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                  speed: const Duration(milliseconds: 100),
                ),
                TypewriterAnimatedText(
                  'Smarter Decisions',
                  textStyle: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              totalRepeatCount: 100,
              pause: const Duration(milliseconds: 2000),
              displayFullTextOnTap: true,
              stopPauseOnTap: true,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Manage your livestock, track growth, and optimize production with intelligent analytics—all in one place.',
            textAlign: textAlign,
            style: GoogleFonts.inter(
              fontSize: 18,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: centered ? WrapAlignment.center : WrapAlignment.start,
            children: [
              _buildPrimaryButton(
                'Get Started',
                () => coordinator.push(RegisterRoute()),
              ),
              _buildSecondaryButton(
                'Sign In',
                () => coordinator.push(LoginRoute()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCards({required bool isDesktop}) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: _features.length,
      itemBuilder: (context, index) {
        return _FeatureCard(
          feature: _features[index],
          isActive: index == _currentPage,
          isDesktop: isDesktop,
        );
      },
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.farmGreen,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
        shadowColor: AppTheme.farmGreen.withValues(alpha: 0.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        side: const BorderSide(color: AppTheme.farmGreen, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.farmGreen,
        ),
      ),
    );
  }
}

class AppFeature {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  AppFeature({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _FeatureCard extends StatelessWidget {
  final AppFeature feature;
  final bool isActive;
  final bool isDesktop;

  const _FeatureCard({
    required this.feature,
    required this.isActive,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final double scale = isActive ? 1.0 : 0.9;
    final double elevation = isActive ? 12 : 2;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: scale, end: scale),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isDesktop ? 20 : 10,
          vertical: 20,
        ),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: feature.color.withValues(alpha: 0.2),
              blurRadius: elevation * 2,
              offset: Offset(0, elevation),
            ),
          ],
          border: Border.all(
            color: isActive
                ? feature.color.withValues(alpha: 0.1)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: feature.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(feature.icon, size: 48, color: feature.color),
            ),
            const SizedBox(height: 24),
            Text(
              feature.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              feature.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  const _AnimatedBackground();

  @override
  Widget build(BuildContext context) {
    return MirrorAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 20),
      builder: (context, value, child) {
        return CustomPaint(painter: _BackgroundPainter(value));
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double progress;

  _BackgroundPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.farmGreen.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    final path = Path();

    // Create flowing organic shapes
    for (int i = 0; i < 3; i++) {
      final offset = i * 100.0;
      final waveHeight = 50.0 + (i * 20);

      path.reset();
      path.moveTo(0, size.height * 0.7 + offset);

      for (double x = 0; x <= size.width; x += 10) {
        final sine = sin((x / size.width * 2 * pi) + (progress * 2 * pi) + i);
        final y = (size.height * 0.7) + (sine * waveHeight) + offset;
        if (x == 0) path.moveTo(x, y);
        path.lineTo(x, y);
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => true;
}
