import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

//pages import
import 'toolkits/custom_agent_page.dart';
import 'toolkits/ai_slides_page.dart';
import 'toolkits/ai_docs_page.dart';
import 'toolkits/ai_developer_page.dart';
import 'toolkits/ai_designer_page.dart';
import 'toolkits/clip_genius_page.dart';
import 'toolkits/resume_roast/resume_roast.dart';
import 'toolkits/ai_image_page.dart';
import 'toolkits/ai_video_page.dart';
import 'toolkits/ai_meeting_notes_page.dart';
import 'toolkits/book_generation/book_generation.dart';

class LandingPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final User? currentUser;

  const LandingPage({super.key, required this.onToggleTheme, this.currentUser});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _allAiTools = [
    {
      'name': 'Custom Agent',
      'icon': Icons.smart_toy,
      'description': 'Create your own AI agent with custom instructions',
      'category': 'Agents',
      'color': Colors.blue,
      'page': CustomAgentPage(onToggleTheme: () {}),
    },
    {
      'name': 'AI Slides',
      'icon': Icons.slideshow,
      'description': 'Generate beautiful presentations instantly',
      'category': 'Productivity',
      'color': Colors.purple,
      'page': AISlidesPage(onToggleTheme: () {}),
    },
    {
      'name': 'AI Docs',
      'icon': Icons.description,
      'description': 'Write and edit documents with AI assistance',
      'category': 'Productivity',
      'color': Colors.green,
      'page': AIDocsPage(onToggleTheme: () {}),
    },
    {
      'name': 'AI Developer',
      'icon': Icons.code,
      'description': 'Code generation and programming help',
      'category': 'Development',
      'color': Colors.orange,
      'page': AIDeveloperPage(onToggleTheme: () {}),
    },
    {
      'name': 'AI Designer',
      'icon': Icons.design_services,
      'description': 'Design assistance and creative tools',
      'category': 'Design',
      'color': Colors.pink,
      'page': AIDesignerPage(onToggleTheme: () {}),
    },
    {
      'name': 'Clip Genius',
      'icon': Icons.video_library,
      'description': 'Video editing and content creation',
      'category': 'Media',
      'color': Colors.red,
      'page': ClipGeniusPage(onToggleTheme: () {}),
    },
    {
      'name': 'Resume Roast',
      'icon': Icons.chat,
      'description': 'Intelligent conversation with AI',
      'category': 'Communication',
      'color': Colors.teal,
      'page': ResumeAnalysisPage(
        onToggleTheme: () {},
        backendUrl: 'http://127.0.0.1:5000',
      ),
    },
    {
      'name': 'AI Image',
      'icon': Icons.image,
      'description': 'Generate and edit images with AI',
      'category': 'Media',
      'color': Colors.indigo,
      'page': AIImagePage(onToggleTheme: () {}),
    },
    {
      'name': 'AI Video',
      'icon': Icons.videocam,
      'description': 'Create and edit videos using AI',
      'category': 'Media',
      'color': Colors.blueGrey,
      'page': AIVideoPage(onToggleTheme: () {}),
    },
    {
      'name': 'AI Meeting Notes',
      'icon': Icons.notes,
      'description': 'Automatic meeting transcription and summaries',
      'category': 'Productivity',
      'color': Colors.cyan,
      'page': AIMeetingNotesPage(onToggleTheme: () {}),
    },
    {
      'name': 'Book Generatiom',
      'icon': Icons.group_work,
      'description': 'An AI tool to Generate Book Instantly',
      'category': 'Book',
      'color': Colors.amber,
      'page': BookGeneration(
        onToggleTheme: () {},
        backendUrl: 'https://book-generation.onrender.com',
      ),
    },
  ];

  late List<Map<String, dynamic>> _filteredAiTools;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Agents',
    'Productivity',
    'Development',
    'Design',
    'Media',
    'Communication',
  ];

  // New state variables for hover effects
  bool _isSearchBarHovered = false;
  bool _isFilterHovered = false;
  bool _showFilterOptions = false;

  @override
  void initState() {
    super.initState();
    _filteredAiTools = List.from(_allAiTools);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterTools();
    });
  }

  void _filterTools() {
    List<Map<String, dynamic>> filtered = _allAiTools;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tool) {
        final name = tool['name'].toString().toLowerCase();
        final description = tool['description'].toString().toLowerCase();
        final category = tool['category'].toString().toLowerCase();
        return name.contains(_searchQuery) ||
            description.contains(_searchQuery) ||
            category.contains(_searchQuery);
      }).toList();
    }

    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((tool) => tool['category'] == _selectedCategory)
          .toList();
    }

    setState(() {
      _filteredAiTools = filtered;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategory = 'All';
      _filteredAiTools = List.from(_allAiTools);
      _showFilterOptions = false;
    });
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _filterTools();
      _showFilterOptions = false;
    });
  }

  void _navigateToHomePage() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  void _navigateToSignIn() {
    Navigator.pushNamed(context, '/signin');
  }

  void _navigateToSignUp() {
    Navigator.pushNamed(context, '/signup');
  }

  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  void _navigateToFeaturePage(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 6
        : screenWidth > 800
        ? 4
        : screenWidth > 600
        ? 3
        : 2;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with navigation
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo and title
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade700,
                              Colors.orange.shade400,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.spa,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'KiddoBookAI',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (screenWidth > 600)
                        Text(
                          '- Tools That Create Impact',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),

                  // Navigation buttons and theme toggle
                  Row(
                    children: [
                      // Theme toggle
                      IconButton(
                        onPressed: widget.onToggleTheme,
                        icon: Icon(
                          isDark ? Icons.light_mode : Icons.dark_mode,
                          color: isDark
                              ? Colors.orange.shade300
                              : Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Profile or Auth buttons
                      if (widget.currentUser != null)
                        _buildUserProfile()
                      else ...[
                        // Sign in button
                        if (screenWidth > 500)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            child: OutlinedButton(
                              onPressed: _navigateToSignIn,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: isDark
                                    ? Colors.white
                                    : Colors.black,
                                side: BorderSide(color: Colors.grey.shade400),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text('Sign in'),
                            ),
                          ),
                        const SizedBox(width: 12),
                        // Sign up button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          child: ElevatedButton(
                            onPressed: _navigateToSignUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 4,
                              shadowColor: Colors.orange.shade300,
                            ),
                            child: Text(
                              screenWidth > 500 ? 'Get Started' : 'Start',
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar with Filter Hover
                    _buildSearchSection(isDark),

                    // URL bar (optional)
                    if (screenWidth > 800) _buildUrlBar(isDark),

                    // Main title
                    Center(
                      child: Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child:
                                _searchQuery.isEmpty &&
                                    _selectedCategory == 'All'
                                ? Text(
                                    'KiddoBookAI Workspace',
                                    key: const ValueKey('title'),
                                    style: TextStyle(
                                      fontSize: screenWidth > 600 ? 48 : 32,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : Text(
                                    _searchQuery.isEmpty &&
                                            _selectedCategory != 'All'
                                        ? '${_selectedCategory} Tools'
                                        : 'Search Results',
                                    key: ValueKey(
                                      _searchQuery.isEmpty
                                          ? 'category'
                                          : 'search',
                                    ),
                                    style: TextStyle(
                                      fontSize: screenWidth > 600 ? 48 : 32,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.orange.shade700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty && _selectedCategory == 'All'
                                ? 'Learn anything, create amazing stories'
                                : 'Found ${_filteredAiTools.length} tool${_filteredAiTools.length != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: screenWidth > 600 ? 24 : 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Category Filter Chips (only show when not in search mode)
                    if (_searchQuery.isEmpty && !_showFilterOptions)
                      _buildCategoryFilter(isDark),

                    const SizedBox(height: 20),

                    // AI Tools Grid or No Results
                    if (_filteredAiTools.isNotEmpty)
                      _buildAIToolsGrid(isDark, crossAxisCount)
                    else
                      _buildNoResultsWidget(isDark),

                    const SizedBox(height: 60),

                    // Featured Learning Section (only show when not searching)
                    if (_searchQuery.isEmpty && _selectedCategory == 'All')
                      _buildFeaturedLearning(isDark),

                    const SizedBox(height: 40),

                    // Call to action section(only show when not searching)
                    if (_searchQuery.isEmpty && _selectedCategory == 'All')
                      _buildCallToAction(isDark),

                    const SizedBox(height: 40),

                    // Footer
                    Center(
                      child: Text(
                        '© 2024 KiddoBookAI. All rights reserved.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _navigateToProfile,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange.shade700, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.shade300.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.orange.shade700,
            child: Text(
              widget.currentUser!.email![0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(bool isDark) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 40),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: MouseRegion(
                      onEnter: (_) =>
                          setState(() => _isSearchBarHovered = true),
                      onExit: (_) =>
                          setState(() => _isSearchBarHovered = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                _isSearchBarHovered ? 0.15 : 0.1,
                              ),
                              blurRadius: _isSearchBarHovered ? 20 : 15,
                              offset: const Offset(0, 6),
                            ),
                            if (_isSearchBarHovered)
                              BoxShadow(
                                color: Colors.orange.shade400.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                          ],
                          border: Border.all(
                            color:
                                _searchQuery.isNotEmpty || _isSearchBarHovered
                                ? Colors.orange.shade400
                                : Colors.transparent,
                            width: _isSearchBarHovered ? 3 : 2,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search AI tools, lessons, stories...',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            prefixIcon: Icon(
                              Icons.search,
                              color: _isSearchBarHovered
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade600,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    onPressed: _clearSearch,
                                    icon: Icon(
                                      Icons.clear,
                                      color: Colors.grey.shade600,
                                    ),
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _showFilterOptions = false;
                            });
                          },
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              // Handle search
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Filter Button with Hover Effects
                  MouseRegion(
                    onEnter: (_) => setState(() {
                      _isFilterHovered = true;
                      _showFilterOptions = true;
                    }),
                    onExit: (_) => setState(() => _isFilterHovered = false),
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isFilterHovered
                                  ? [
                                      Colors.orange.shade800,
                                      Colors.orange.shade500,
                                    ]
                                  : [
                                      Colors.orange.shade700,
                                      Colors.orange.shade400,
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.shade400.withOpacity(
                                  _isFilterHovered ? 0.6 : 0.4,
                                ),
                                blurRadius: _isFilterHovered ? 15 : 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: _isFilterHovered
                                  ? Colors.orange.shade300
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _showFilterOptions = !_showFilterOptions;
                              });
                            },
                            icon: Icon(
                              Icons.tune,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),

                        // Notification dot for active filter
                        if (_selectedCategory != 'All')
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _searchQuery.isNotEmpty ? 1.0 : 0.0,
                    child: Text(
                      'Searching for "$_searchQuery"',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Filter Options Dropdown
        if (_showFilterOptions)
          Positioned(
            top: 70,
            right: 12,
            child: MouseRegion(
              onEnter: (_) => setState(() => _showFilterOptions = true),
              onExit: (_) => setState(() {
                if (!_isFilterHovered) {
                  _showFilterOptions = false;
                }
              }),
              child: _buildFilterDropdown(isDark),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterDropdown(bool isDark) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _showFilterOptions ? 1.0 : 0.0,
      child: Transform.translate(
        offset: Offset(0, _showFilterOptions ? 0 : -10),
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          color: isDark ? Colors.grey.shade900 : Colors.white,
          child: Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.shade400.withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Filter by Category',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ..._categories.map((category) {
                  final isSelected = category == _selectedCategory;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _selectCategory(category),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange.shade100.withOpacity(0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.orange.shade700
                                    : Colors.grey.shade400,
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 12,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              category,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.orange.shade700
                                    : (isDark ? Colors.white : Colors.black),
                              ),
                            ),
                            const Spacer(),
                            if (category != 'All')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _allAiTools
                                      .where(
                                        (tool) => tool['category'] == category,
                                      )
                                      .length
                                      .toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      onPressed: () => _selectCategory('All'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Clear'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showFilterOptions = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((category) {
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = selected ? category : 'All';
                  _filterTools();
                });
              },
              backgroundColor: isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              selectedColor: Colors.orange.shade700,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black),
                fontWeight: FontWeight.w500,
              ),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide(
                color: isSelected
                    ? Colors.orange.shade700
                    : Colors.grey.shade400,
              ),
              elevation: isSelected ? 4 : 0,
              shadowColor: Colors.orange.shade300,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUrlBar(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 40),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'NO FUNDS TO KEEP BACKEND RUNNING',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIToolsGrid(bool isDark, int crossAxisCount) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.0,
      ),
      itemCount: _filteredAiTools.length,
      itemBuilder: (context, index) {
        final tool = _filteredAiTools[index];
        return _AIToolCard(
          name: tool['name'] as String,
          icon: tool['icon'] as IconData,
          description: tool['description'] as String,
          category: tool['category'] as String,
          color: tool['color'] as Color,
          isDark: isDark,
          onTap: () => _navigateToFeaturePage(tool['page'] as Widget),
        );
      },
    );
  }

  Widget _buildNoResultsWidget(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 20),
          Text(
            'No AI tools found',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Try searching with different keywords or clear filters',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _clearSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Clear All'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = 'All';
                    _filterTools();
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  side: BorderSide(color: Colors.orange.shade700),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Clear Category'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedLearning(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Learning',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 20),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _navigateToHomePage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade700,
                          Colors.orange.shade400,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.store_mall_directory,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Interactive Story Creator',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create personalized stories with AI',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.orange.shade700,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '4.8 (23 reviews)',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.orange.shade700,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCallToAction(bool isDark) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade50, Colors.orange.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.shade200.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              'Ready to start Building?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Join thousands of Automated Work Flow with amazing AI',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.currentUser != null
                    ? _navigateToHomePage
                    : _navigateToSignUp,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade700, Colors.orange.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.shade400.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.currentUser != null
                        ? 'Continue building'
                        : 'Start Unlimited now',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AIToolCard extends StatefulWidget {
  final String name;
  final IconData icon;
  final String description;
  final String category;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _AIToolCard({
    required this.name,
    required this.icon,
    required this.description,
    required this.category,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_AIToolCard> createState() => _AIToolCardState();
}

class _AIToolCardState extends State<_AIToolCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.2 : 0.1),
                blurRadius: _isHovered ? 20 : 10,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
              if (_isHovered)
                BoxShadow(
                  color: widget.color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
            border: Border.all(
              color: _isHovered ? widget.color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _isHovered ? 56 : 50,
                      height: _isHovered ? 56 : 50,
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: widget.color.withOpacity(0.3),
                          width: _isHovered ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: _isHovered ? 30 : 28,
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(_isHovered ? 0.3 : 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: widget.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _isHovered ? 1.0 : 0.0,
                  child: Row(
                    children: [
                      Text(
                        'Try Now',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward, size: 12, color: widget.color),
                    ],
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
