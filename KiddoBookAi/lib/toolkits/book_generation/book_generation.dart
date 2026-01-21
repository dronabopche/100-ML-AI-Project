import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class BookGeneration extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final String backendUrl;

  const BookGeneration({
    super.key,
    required this.onToggleTheme,
    required this.backendUrl,
  });

  @override
  State<BookGeneration> createState() => _BookGenerationState();
}

class _BookGenerationState extends State<BookGeneration>
    with TickerProviderStateMixin {
  // Form controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _topicsController = TextEditingController();

  // Form state
  String _selectedField = 'General Education';
  String _selectedBookType = 'Textbook';

  // Generation state
  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String _currentStep = '';
  List<String> _generatedChapters = [];
  List<String> _topicsList = [];
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  bool _showDownloadButton = false;

  // Backend book tracking
  String? _generatedBookId;
  String? _generatedFilename;
  bool _isDownloading = false;

  // Backend status
  BackendStatus _backendStatus = BackendStatus.unknown;
  Timer? _statusCheckTimer;

  // Field configurations
  final Map<String, Map<String, dynamic>> _fieldConfigs = {
    'Computer Science': {'color': Colors.blue, 'icon': Icons.computer},
    'Mathematics': {'color': Colors.red, 'icon': Icons.calculate},
    'Science': {'color': Colors.green, 'icon': Icons.science},
    'History': {'color': Colors.amber, 'icon': Icons.history},
    'Literature': {'color': Colors.purple, 'icon': Icons.book},
    'Art & Design': {'color': Colors.pink, 'icon': Icons.palette},
    'General Education': {'color': Colors.indigo, 'icon': Icons.school},
  };

  // Book type configurations
  final Map<String, Map<String, dynamic>> _bookTypeConfigs = {
    'Textbook': {'icon': Icons.menu_book},
    'Exam-prep Notes': {'icon': Icons.assignment},
    'Story-style Guide': {'icon': Icons.spa},
    'Research Manual': {'icon': Icons.analytics},
    'Beginner\'s Handbook': {'icon': Icons.import_contacts},
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start checking backend status
    _checkBackendStatus();
    _startStatusCheckTimer();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _topicsController.dispose();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkBackendStatus() async {
    try {
      final response = await http
          .get(
            Uri.parse('${widget.backendUrl}/api/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _backendStatus = BackendStatus.healthy;
        });
      } else {
        setState(() {
          _backendStatus = BackendStatus.unhealthy;
        });
      }
    } catch (e) {
      setState(() {
        _backendStatus = BackendStatus.unhealthy;
      });
    }
  }

  void _startStatusCheckTimer() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkBackendStatus();
    });
  }

  Future<void> _generateBook() async {
    if (_titleController.text.isEmpty || _topicsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // Check backend status before generating
    if (_backendStatus != BackendStatus.healthy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Backend service is currently unavailable. Please try again later.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      await _checkBackendStatus(); // Refresh status
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationProgress = 0.0;
      _generatedChapters.clear();
      _topicsList = _topicsController.text
          .split('\n')
          .where((t) => t.trim().isNotEmpty)
          .toList();
      _showDownloadButton = false;
      _generatedBookId = null;
      _generatedFilename = null;
      _isDownloading = false;
    });

    try {
      // Simulate progress updates
      for (int i = 0; i < 10; i++) {
        if (!_isGenerating) break;
        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          _generationProgress = (i + 1) / 10;
          _currentStep = 'Generating chapter ${i + 1}/${_topicsList.length}...';
        });
      }

      setState(() {
        _currentStep = 'Finalizing book...';
      });

      // Call backend to generate complete book with PDF
      final response = await http.post(
        Uri.parse('${widget.backendUrl}/api/generate-book-pdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'topics': _topicsList,
          'book_type': _selectedBookType,
          'field': _selectedField,
          'book_name': _titleController.text,
          'book_description': _descriptionController.text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Get book ID and filename from backend
          final bookId = data['book_id'] as String? ?? '';
          final filename = data['filename'] as String? ?? 'book.pdf';
          final chapters = (data['book_info']?['total_chapters'] as int?) ?? 0;

          // Store chapters for display
          if (data['chapters'] != null) {
            final chaptersList = data['chapters'] as List;
            _generatedChapters = chaptersList
                .map(
                  (c) => (c['content']?.toString() ?? 'No content available'),
                )
                .toList();
          } else {
            _generatedChapters = List.filled(
              _topicsList.length,
              'Content generation in progress...',
            );
          }

          setState(() {
            _generatedBookId = bookId.isNotEmpty ? bookId : null;
            _generatedFilename = filename;
            _isGenerating = false;
            _currentStep = 'Book generation complete!';
            _showDownloadButton = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Generated $chapters chapters successfully! Book is ready for download.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception(data['error']?.toString() ?? 'Unknown error');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _currentStep = 'Error generating book';
      });

      // Update backend status on error
      await _checkBackendStatus();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadBook() async {
    if (_generatedBookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No book available to download')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      // Create download URL
      final downloadUrl =
          '${widget.backendUrl}/api/download-book/$_generatedBookId';

      // Check if we're on web or mobile
      final isWeb = identical(0, 0.0); // Simple web detection

      if (isWeb) {
        // For web, open in new tab
        await launchUrl(
          Uri.parse(downloadUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        // For mobile, download and save locally
        final response = await http.get(Uri.parse(downloadUrl));

        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;

          // Get downloads directory
          final directory = await getDownloadsDirectory();
          if (directory != null) {
            final safeTitle = _titleController.text
                .replaceAll(RegExp(r'[^\w\s-]'), '')
                .replaceAll(RegExp(r'\s+'), '_');
            final fileName =
                '${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
            final filePath = '${directory.path}/$fileName';

            // Save file
            final file = File(filePath);
            await file.writeAsBytes(bytes);

            // Open the file
            await OpenFilex.open(filePath);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Book saved to: $filePath'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            throw Exception('Could not access downloads directory');
          }
        } else {
          throw Exception('Failed to download file');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading book: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _previewBook() async {
    if (_generatedBookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No book available to preview')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      // Create preview URL
      final previewUrl =
          '${widget.backendUrl}/api/download-book/$_generatedBookId';

      // For preview, we'll open in browser/webview
      await launchUrl(
        Uri.parse(previewUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error previewing book: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  void _resetForm() {
    // Clear all form data and state
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _topicsController.clear();
      _selectedField = 'General Education';
      _selectedBookType = 'Textbook';
      _isGenerating = false;
      _generationProgress = 0.0;
      _generatedChapters.clear();
      _generatedBookId = null;
      _generatedFilename = null;
      _topicsList.clear();
      _showDownloadButton = false;
      _isDownloading = false;
      _currentStep = '';
    });

    // Clear any snackbars
    ScaffoldMessenger.of(context).clearSnackBars();

    // Show a confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Form cleared. Ready to create a new book!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiddo Book AI'),
        backgroundColor: Colors.orange.shade700,
        actions: [
          // Small backend status indicator button (just like theme button)
          IconButton(
            onPressed: _checkBackendStatus,
            icon: _buildBackendStatusIcon(),
            tooltip: _getBackendStatusTooltip(),
            color: Colors.white,
          ),
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _isGenerating
                  ? _buildGenerationScreen()
                  : _buildInputScreen(),
            ),
          ),
          if (_showDownloadButton && _generatedBookId != null) ...[
            Container(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Text(
                    'Your Book is Ready!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Preview or download your generated book:',
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isDownloading ? null : _previewBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                        ),
                        icon: const Icon(Icons.preview),
                        label: _isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Preview'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isDownloading ? null : _downloadBook,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                        ),
                        icon: const Icon(Icons.download),
                        label: _isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Download'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isDownloading ? null : _resetForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                          foregroundColor: isDark ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                        ),
                        icon: const Icon(Icons.refresh),
                        label: const Text('New Book'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Small backend status icon for the button
  Widget _buildBackendStatusIcon() {
    switch (_backendStatus) {
      case BackendStatus.healthy:
        return const Icon(Icons.check_circle, color: Colors.green);
      case BackendStatus.unhealthy:
        return const Icon(Icons.error, color: Colors.red);
      case BackendStatus.unknown:
        return const Icon(Icons.question_mark, color: Colors.orange);
    }
  }

  String _getBackendStatusTooltip() {
    switch (_backendStatus) {
      case BackendStatus.healthy:
        return 'Backend is connected';
      case BackendStatus.unhealthy:
        return 'Backend is offline - Click to retry';
      case BackendStatus.unknown:
        return 'Checking backend status';
    }
  }

  Widget _buildInputScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Title
          TextField(
            controller: _titleController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'Book Title *',
              labelStyle: TextStyle(
                color: isDark ? Colors.grey.shade400 : null,
              ),
              hintText: 'Enter your book title',
              hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : null),
              border: const OutlineInputBorder(),
              prefixIcon: Icon(
                Icons.title,
                color: isDark ? Colors.grey.shade400 : null,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orange.shade700),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Book Description
          TextField(
            controller: _descriptionController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Book Description',
              labelStyle: TextStyle(
                color: isDark ? Colors.grey.shade400 : null,
              ),
              hintText: 'Describe what your book is about...',
              hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : null),
              border: const OutlineInputBorder(),
              prefixIcon: Icon(
                Icons.description,
                color: isDark ? Colors.grey.shade400 : null,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orange.shade700),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Field of Study Dropdown
          DropdownButtonFormField<String>(
            value: _selectedField,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'Field of Study *',
              labelStyle: TextStyle(
                color: isDark ? Colors.grey.shade400 : null,
              ),
              border: const OutlineInputBorder(),
              prefixIcon: Icon(
                Icons.category,
                color: isDark ? Colors.grey.shade400 : null,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orange.shade700),
              ),
            ),
            dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
            items: _fieldConfigs.keys.map((field) {
              return DropdownMenuItem(
                value: field,
                child: Row(
                  children: [
                    Icon(
                      _fieldConfigs[field]!['icon'] as IconData,
                      color: _fieldConfigs[field]!['color'] as Color,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      field,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedField = value!;
              });
            },
          ),
          const SizedBox(height: 20),

          // Book Type Dropdown
          DropdownButtonFormField<String>(
            value: _selectedBookType,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'Book Type *',
              labelStyle: TextStyle(
                color: isDark ? Colors.grey.shade400 : null,
              ),
              border: const OutlineInputBorder(),
              prefixIcon: Icon(
                Icons.menu_book,
                color: isDark ? Colors.grey.shade400 : null,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orange.shade700),
              ),
            ),
            dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
            items: _bookTypeConfigs.keys.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      _bookTypeConfigs[type]!['icon'] as IconData,
                      color: isDark ? Colors.white : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      type,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedBookType = value!;
              });
            },
          ),
          const SizedBox(height: 20),

          // Topics Input
          TextField(
            controller: _topicsController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Topics *',
              labelStyle: TextStyle(
                color: isDark ? Colors.grey.shade400 : null,
              ),
              hintText:
                  'Enter topics (one per line)\nExample:\nIntroduction to Algebra\nQuadratic Equations\nTrigonometry Basics',
              hintStyle: TextStyle(color: isDark ? Colors.grey.shade500 : null),
              border: const OutlineInputBorder(),
              prefixIcon: Icon(
                Icons.list,
                color: isDark ? Colors.grey.shade400 : null,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.orange.shade700),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Enter each topic on a new line. Each topic will become a chapter in your book.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 30),

          // Generate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  (_isGenerating || _backendStatus == BackendStatus.unhealthy)
                  ? null
                  : _generateBook,
              style: ElevatedButton.styleFrom(
                backgroundColor: _backendStatus == BackendStatus.unhealthy
                    ? Colors.grey
                    : Colors.orange.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.auto_stories),
              label: _isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _backendStatus == BackendStatus.unhealthy
                          ? 'Backend Offline'
                          : 'Generate Book',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),

          // Generated Chapters Preview
          if (_generatedChapters.isNotEmpty && !_showDownloadButton) ...[
            const SizedBox(height: 30),
            const Text(
              'Generated Chapters Preview:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._generatedChapters.asMap().entries.map(
              (entry) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Text('${entry.key + 1}'),
                  ),
                  title: Text(
                    _topicsList.length > entry.key
                        ? _topicsList[entry.key]
                        : 'Chapter ${entry.key + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    (entry.value ?? '').isNotEmpty &&
                            (entry.value ?? '').length > 100
                        ? '${(entry.value ?? '').substring(0, 100)}...'
                        : (entry.value ?? 'No content available'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerationScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -20 * _progressAnimation.value),
                child: Icon(
                  Icons.auto_stories,
                  size: 100,
                  color: Colors.orange.shade700,
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: _generationProgress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${(_generationProgress * 100).toStringAsFixed(0)}% Complete',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _currentStep,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 30),
          if (_topicsList.isNotEmpty)
            Text(
              'Chapter ${(_generationProgress * _topicsList.length).ceil()}/${_topicsList.length}',
              style: const TextStyle(fontSize: 16),
            ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isGenerating = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade300,
              foregroundColor: Colors.black,
            ),
            child: const Text('Cancel Generation'),
          ),
        ],
      ),
    );
  }
}

enum BackendStatus { healthy, unhealthy, unknown }
