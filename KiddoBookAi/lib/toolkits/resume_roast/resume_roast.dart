import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResumeAnalysisPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final String backendUrl;

  const ResumeAnalysisPage({
    super.key,
    required this.onToggleTheme,
    required this.backendUrl,
  });

  @override
  State<ResumeAnalysisPage> createState() => _ResumeAnalysisPageState();
}

class _ResumeAnalysisPageState extends State<ResumeAnalysisPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  PlatformFile? _selectedFile;
  bool _isAnalyzing = false;
  bool _isFileUploaded = false;
  bool _isConnected = false;
  bool _isTestingConnection = false;

  // Analysis sections
  final List<String> _analysisSections = [
    'Strengths & Achievements',
    'Weaknesses & Gaps',
    'ATS Optimization',
    'Industry-Specific Recommendations',
  ];

  final Map<String, String> _analysisResults = {};
  String _resumePreview = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Test connection on init
    _testConnection();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
    });

    try {
      final response = await http
          .get(
            Uri.parse('${widget.backendUrl}/test'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _isConnected = true;
        });
      } else {
        setState(() {
          _isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        _isConnected = false;
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  Future<void> _pickFile() async {
    if (!_isConnected) {
      _showSnackBar('Out of Credits , Sorry ', Colors.red);
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'doc', 'docx'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          _showSnackBar('File size must be less than 5MB', Colors.red);
          return;
        }

        setState(() {
          _selectedFile = file;
          _isFileUploaded = true;
        });

        // Start analysis
        await _analyzeResume(file);
      }
    } catch (e) {
      _showSnackBar('Error picking file: $e', Colors.red);
    }
  }

  Future<void> _analyzeResume(PlatformFile file) async {
    setState(() {
      _isAnalyzing = true;
      _analysisResults.clear();
      _resumePreview = '';
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${widget.backendUrl}/analyze-resume'),
      );

      // Read file bytes
      final fileBytes = file.bytes;
      if (fileBytes == null) {
        throw Exception('Could not read file bytes');
      }

      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: file.name),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = json.decode(responseData);

        if (result['success'] == true) {
          setState(() {
            _analysisResults['Strengths & Achievements'] =
                result['sections']['Strengths & Achievements'] ?? 'No data';
            _analysisResults['Weaknesses & Gaps'] =
                result['sections']['Weaknesses & Gaps'] ?? 'No data';
            _analysisResults['ATS Optimization'] =
                result['sections']['ATS Optimization'] ?? 'No data';
            _analysisResults['Industry-Specific Recommendations'] =
                result['sections']['Industry-Specific Recommendations'] ??
                'No data';
            _resumePreview = result['resume_preview'] ?? '';
          });
          _showSnackBar('Analysis complete!', Colors.green);
        } else {
          throw Exception(result['error'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Server error: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showSnackBar('Error analyzing resume: $e', Colors.red);

      // Fallback to mock data for testing
      _showMockData();
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  void _showMockData() {
    setState(() {
      _analysisResults['Strengths & Achievements'] =
          "✅ Strong project experience with measurable results\n✅ Good technical skills listed\n✅ Clear career progression shown";
      _analysisResults['Weaknesses & Gaps'] =
          "⚠️ Action verbs need strengthening (used 'worked on' 8 times)\n⚠️ Missing quantifiable metrics in 60% of bullet points\n⚠️ Skills section not tailored for target industry";
      _analysisResults['ATS Optimization'] =
          "🔍 ATS Score: 78/100\n✅ Keywords: Good technical terms\n⚠️ Missing: 'Machine Learning', 'Agile', 'CI/CD'\n✅ Format: PDF preserves layout well";
      _analysisResults['Industry-Specific Recommendations'] =
          "🎯 For Tech Roles: Add GitHub link, mention specific frameworks\n🎯 For Management: Highlight team size, budget management\n🎯 Overall: Consider adding certifications section";
      _resumePreview = "Sample resume content would appear here...";
    });
  }

  void _resetFile() {
    setState(() {
      _selectedFile = null;
      _isFileUploaded = false;
      _analysisResults.clear();
      _resumePreview = '';
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildAnalysisSection(String sectionTitle, String? content) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getSectionIcon(sectionTitle),
                color: _getSectionColor(sectionTitle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sectionTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (content != null && content.isNotEmpty)
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 20,
                ),
            ],
          ),
          if (content != null && content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getSectionIcon(String section) {
    switch (section) {
      case 'Strengths & Achievements':
        return Icons.thumb_up;
      case 'Weaknesses & Gaps':
        return Icons.warning;
      case 'ATS Optimization':
        return Icons.search;
      case 'Industry-Specific Recommendations':
        return Icons.insights;
      default:
        return Icons.info;
    }
  }

  Color _getSectionColor(String section) {
    switch (section) {
      case 'Strengths & Achievements':
        return Colors.green;
      case 'Weaknesses & Gaps':
        return Colors.orange;
      case 'ATS Optimization':
        return Colors.blue;
      case 'Industry-Specific Recommendations':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildConnectionIndicator() {
    return Tooltip(
      message: _isConnected ? 'Backend connected' : 'Backend disconnected',
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isConnected ? Colors.green.shade600 : Colors.red.shade600,
        ),
        child: Center(
          child: _isTestingConnection
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: 20,
                ),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.deepPurple.shade200, width: 2),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_upload, size: 50, color: Colors.deepPurple.shade400),
          const SizedBox(height: 15),
          Text(
            'Upload Resume (PDF/TXT/DOC)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Max file size: 5MB',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),

          if (_selectedFile == null)
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose File'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
              ),
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedFile!.extension == 'pdf'
                            ? Icons.picture_as_pdf
                            : Icons.description,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFile!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _resetFile,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                if (_isAnalyzing)
                  Column(
                    children: [
                      const CircularProgressIndicator(color: Colors.deepPurple),
                      const SizedBox(height: 10),
                      Text(
                        'AI is analyzing your resume...',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Resume Roaster'),
        backgroundColor: Colors.deepPurple.shade700,
        actions: [
          IconButton(
            onPressed: _testConnection,
            icon: _buildConnectionIndicator(),
            tooltip: _isConnected
                ? 'Backend connected'
                : 'Click to test connection',
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section with Animation
              Center(
                child: Column(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Icon(
                        Icons.auto_stories,
                        size: 80,
                        color: Colors.deepPurple.shade400,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'AI Resume Analyzer',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Upload your resume for a detailed roast',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),

              // Centered Upload Section
              Center(
                child: Container(
                  width: double.infinity,
                  child: _buildUploadSection(),
                ),
              ),
              const SizedBox(height: 30),

              // Analysis Sections
              if (_isFileUploaded) ...[
                Text(
                  'Analysis Sections',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 15),
                ..._analysisSections.map((section) {
                  return _buildAnalysisSection(
                    section,
                    _analysisResults[section],
                  );
                }).toList(),
                const SizedBox(height: 30),
              ],

              // Results Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.deepPurple),
                        const SizedBox(width: 10),
                        Text(
                          'AI Analysis Results',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _isFileUploaded
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_analysisResults.isNotEmpty) ...[
                                  const Text(
                                    'Here\'s your resume roast:',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 15),

                                  // Resume Preview
                                  if (_resumePreview.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Resume Preview:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.8),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            _resumePreview,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                      ],
                                    ),

                                  // Analysis Results
                                  ..._analysisSections.map((section) {
                                    final content = _analysisResults[section];
                                    if (content != null && content.isNotEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              _getSectionIcon(section),
                                              color: _getSectionColor(section),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                content,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    return const SizedBox();
                                  }).toList(),
                                ] else if (_isAnalyzing)
                                  const Column(
                                    children: [
                                      LinearProgressIndicator(
                                        color: Colors.deepPurple,
                                      ),
                                      SizedBox(height: 10),
                                      Text('Analyzing your resume with AI...'),
                                    ],
                                  ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'How it works:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildFeatureItem(
                                  '1. Connect to backend server',
                                ),
                                _buildFeatureItem(
                                  '2. Upload your resume (PDF/TXT/DOC)',
                                ),
                                _buildFeatureItem(
                                  '3. AI analyzes in 4 sections',
                                ),
                                _buildFeatureItem('4. Get actionable feedback'),
                                const SizedBox(height: 15),
                                Text(
                                  'Our AI will analyze your resume and provide constructive feedback to help you improve!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButton: _isConnected && !_isAnalyzing
          ? FloatingActionButton.extended(
              onPressed: _selectedFile == null ? _pickFile : null,
              backgroundColor: Colors.deepPurple.shade600,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.auto_stories),
              label: const Text('Analyze Resume'),
            )
          : null,
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
