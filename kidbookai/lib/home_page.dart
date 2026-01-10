import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:kidbookai/setting_drawer.dart';
import 'features/book_generation.dart';
import 'features/text_to_image.dart';
import 'features/language_conversion_page.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const HomePage({super.key, required this.onToggleTheme});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _heroAnimationController;
  late Animation<double> _heroFadeAnimation;
  late Animation<double> _heroSlideAnimation;

  User? get _user => FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> _filteredFeatures = [];
  final List<Map<String, dynamic>> _allFeatures = [
    {
      'title': 'Book Generation',
      'icon': Icons.auto_stories,
      'description': 'Create personalized children\'s books with AI',
      'color': Colors.orange,
      'gradient': [Color(0xFFFF9800), Color(0xFFFF5722)],
      'tags': ['book', 'story', 'generate', 'ai'],
      'page': BookGenerationPage(),
    },
    {
      'title': 'Text to Image',
      'icon': Icons.palette,
      'description': 'Generate illustrations from descriptions',
      'color': Colors.blue,
      'gradient': [Color(0xFF2196F3), Color(0xFF1976D2)],
      'tags': ['image', 'picture', 'art', 'generate'],
      'page': TextToImagePage(),
    },
    {
      'title': 'Language Conversion',
      'icon': Icons.translate,
      'description': 'Translate and adapt stories to multiple languages',
      'color': Colors.green,
      'gradient': [Color(0xFF4CAF50), Color(0xFF2E7D32)],
      'tags': ['language', 'translate', 'convert', 'adapt'],
      'page': LanguageConversionPage(),
    },
    {
      'title': 'Audio Stories',
      'icon': Icons.audiotrack,
      'description': 'Listen to stories with expressive AI narration',
      'color': Colors.purple,
      'gradient': [Color(0xFF9C27B0), Color(0xFF673AB7)],
      'tags': ['audio', 'listen', 'narration', 'voice'],
      'page': FeaturePlaceholderPage(
        title: 'Audio Stories',
        icon: Icons.audiotrack,
        color: Colors.purple,
      ),
    },
    {
      'title': 'Story Templates',
      'icon': Icons.dashboard,
      'description': 'Start with pre-made story structures',
      'color': Colors.teal,
      'gradient': [Color(0xFF009688), Color(0xFF00796B)],
      'tags': ['template', 'structure', 'premade'],
      'page': FeaturePlaceholderPage(
        title: 'Story Templates',
        icon: Icons.dashboard,
        color: Colors.teal,
      ),
    },
    {
      'title': 'Parent Dashboard',
      'icon': Icons.family_restroom,
      'description': 'Monitor and manage your child\'s progress',
      'color': Colors.pink,
      'gradient': [Color(0xFFE91E63), Color(0xFFC2185B)],
      'tags': ['parent', 'dashboard', 'monitor', 'progress'],
      'page': FeaturePlaceholderPage(
        title: 'Parent Dashboard',
        icon: Icons.family_restroom,
        color: Colors.pink,
      ),
    },
  ];

  @override
  void initState() {
    super.initState();
    _filteredFeatures = List.from(_allFeatures);

    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _heroFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _heroSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _heroAnimationController, curve: Curves.easeOut),
    );

    _heroAnimationController.forward();

    // Add search listener
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _filteredFeatures = List.from(_allFeatures);
      });
    } else {
      setState(() {
        _filteredFeatures = _allFeatures.where((feature) {
          final title = feature['title'].toString().toLowerCase();
          final description = feature['description'].toString().toLowerCase();
          final tags = List<String>.from(
            feature['tags'],
          ).map((tag) => tag.toLowerCase()).toList();

          return title.contains(query) ||
              description.contains(query) ||
              tags.any((tag) => tag.contains(query));
        }).toList();
      });
    }
  }

  @override
  void dispose() {
    _heroAnimationController.dispose();
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    await FirebaseAuth.instance.signInWithPopup(provider);
    setState(() {});
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {});
  }

  void _scrollToProducts() {
    _scrollController.animateTo(
      400,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
    );
  }

  void _navigateToFeature(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? Colors.orangeAccent : Colors.orange.shade700;
    final textColor = isDark ? Colors.white : Colors.black87;
    final lightBackground = isDark
        ? Colors.grey.shade900
        : Colors.orange.shade50;

    return Scaffold(
      drawer: SettingsDrawer(
        onToggleTheme: widget.onToggleTheme,
        onSignOut: _signOut,
        user: _user,
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          /// ================= STATIC APP BAR =================
          SliverAppBar(
            floating: false,
            pinned: true,
            snap: false,
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.1),
            backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
            title: Row(
              children: [
                Image.asset(
                  'assets/logo.png', // Add your logo asset
                  height: 32,
                  width: 32,
                  color: isDark ? Colors.white : Colors.black,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.auto_stories, color: accent),
                ),
                const SizedBox(width: 12),
                Text(
                  'KiddoBookAI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
            actions: [
              if (_user == null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Sign In'),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: _user!.photoURL != null
                            ? NetworkImage(_user!.photoURL!)
                            : null,
                        backgroundColor: accent,
                        child: _user!.photoURL == null
                            ? const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _user!.displayName?.split(' ').first ?? 'User',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          /// ================= HERO SECTION =================
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _heroAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _heroSlideAnimation.value),
                  child: Opacity(
                    opacity: _heroFadeAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 60,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Colors.black, Colors.grey.shade900]
                        : [Colors.orange.shade50, Colors.orange.shade100],
                  ),
                ),
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [accent, Colors.orange.shade600],
                        ).createShader(bounds);
                      },
                      child: Text(
                        'Create Stories.\nInspire Kids.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 600),
                      opacity: _heroFadeAnimation.value,
                      child: Text(
                        'AI-powered books, images, and language tools\nfor the next generation of storytellers.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedScale(
                      duration: const Duration(milliseconds: 400),
                      scale: _heroFadeAnimation.value,
                      child: ElevatedButton(
                        onPressed: _scrollToProducts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 4,
                          shadowColor: accent.withOpacity(0.3),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explore Products',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_downward, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// ================= SEARCH =================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search features...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                        ),
                        style: TextStyle(fontSize: 14, color: textColor),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          size: 20,
                          color: Colors.grey.shade500,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),

          /// ================= FEATURES GRID =================
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 1200
                    ? 4
                    : MediaQuery.of(context).size.width > 800
                    ? 3
                    : MediaQuery.of(context).size.width > 600
                    ? 2
                    : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8, // Smaller cards
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final feature = _filteredFeatures[index];
                return _FeatureCard(
                  feature: feature,
                  onTap: () => _navigateToFeature(context, feature['page']),
                );
              }, childCount: _filteredFeatures.length),
            ),
          ),

          /// ================= NO RESULTS =================
          if (_filteredFeatures.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No features found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try a different search term',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          /// ================= STATS SECTION =================
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: lightBackground,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.spaceEvenly,
                children: const [
                  _StatItem(
                    label: 'Users',
                    value: '12,430',
                    icon: Icons.people,
                  ),
                  _StatItem(label: 'Books', value: '8,920', icon: Icons.book),
                  _StatItem(
                    label: 'Languages',
                    value: '50+',
                    icon: Icons.language,
                  ),
                  _StatItem(
                    label: 'Happy Kids',
                    value: '∞',
                    icon: Icons.emoji_emotions,
                  ),
                ],
              ),
            ),
          ),

          /// ================= FOOTER =================
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.black, Colors.grey.shade900]
                      : [Colors.grey.shade900, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'KiddoBookAI',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Empowering young minds through AI storytelling',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _FooterIcon(icon: Icons.email, label: 'Contact'),
                      _FooterIcon(icon: Icons.privacy_tip, label: 'Privacy'),
                      _FooterIcon(icon: Icons.description, label: 'Terms'),
                      _FooterIcon(icon: Icons.help, label: 'Help'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '© 2024 KiddoBookAI. All rights reserved.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final Map<String, dynamic> feature;
  final VoidCallback onTap;

  const _FeatureCard({required this.feature, required this.onTap});

  @override
  State<_FeatureCard> createState() => __FeatureCardState();
}

class __FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = List<Color>.from(widget.feature['gradient']);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          transform: Matrix4.identity()
            ..translate(0.0, _isHovered ? -6.0 : 0.0)
            ..scale(_isHovered ? 1.03 : 1.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(_isHovered ? 0.4 : 0.2),
                blurRadius: _isHovered ? 25 : 15,
                spreadRadius: _isHovered ? 1 : 0,
                offset: Offset(0, _isHovered ? 10 : 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                /// Background Pattern
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),

                /// Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.feature['icon'],
                          size: 28,
                          color: Colors.white,
                        ),
                      ),

                      /// Text Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.feature['title'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.feature['description'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      /// CTA
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: _isHovered ? 1.0 : 0.7,
                        child: Row(
                          children: [
                            Text(
                              'Open',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                /// Overlay on hover
                if (_isHovered)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 120,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.orange.shade800 : Colors.orange.shade100,
              boxShadow: [
                BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 8),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: isDark ? Colors.white : Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.orange.shade800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterIcon extends StatefulWidget {
  final IconData icon;
  final String label;

  const _FooterIcon({required this.icon, required this.label});

  @override
  State<_FooterIcon> createState() => __FooterIconState();
}

class __FooterIconState extends State<_FooterIcon> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: 80,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isHovered ? Colors.orange : Colors.grey.shade800,
              ),
              child: Icon(widget.icon, color: Colors.white, size: 16),
            ),
            const SizedBox(height: 8),
            Text(
              widget.label,
              style: TextStyle(
                color: _isHovered ? Colors.orange : Colors.grey.shade400,
                fontSize: 11,
                fontWeight: _isHovered ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder for features without dedicated pages
class FeaturePlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const FeaturePlaceholderPage({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: color),
            const SizedBox(height: 20),
            Text(
              '$title Feature',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Coming soon! This feature is under development.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
