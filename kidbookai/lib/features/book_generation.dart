import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:open_file/open_file.dart';

class BookGenerationPage extends StatefulWidget {
  const BookGenerationPage({super.key});

  @override
  State<BookGenerationPage> createState() => _BookGenerationPageState();
}

class _BookGenerationPageState extends State<BookGenerationPage> {
  // API Key - Replace with your actual API key
  static const String GOOGLE_API_KEY =
      "AIzaSyAxkDOwgYE3qu_cDVuHsGupbAjXj6favyQ";

  // Field configurations
  static final Map<String, Map<String, dynamic>> FIELD_CONFIGS = {
    "Computer Science": {
      "text_prompt_prefix":
          "Focus on algorithms, programming, and computational thinking. ",
      "color_scheme": Color(0xFF2563EB),
      "icon": Icons.computer,
    },
    "Mathematics": {
      "text_prompt_prefix":
          "Focus on logical reasoning, problem-solving, and mathematical concepts. ",
      "color_scheme": Color(0xFFDC2626),
      "icon": Icons.calculate,
    },
    "Science": {
      "text_prompt_prefix":
          "Focus on scientific method, experiments, and evidence-based learning. ",
      "color_scheme": Color(0xFF059669),
      "icon": Icons.science,
    },
    "History": {
      "text_prompt_prefix":
          "Focus on historical context, timelines, and cause-effect relationships. ",
      "color_scheme": Color(0xFFD97706),
      "icon": Icons.history_edu,
    },
    "Literature": {
      "text_prompt_prefix":
          "Focus on narrative analysis, literary devices, and character development. ",
      "color_scheme": Color(0xFF7C3AED),
      "icon": Icons.menu_book,
    },
    "Art & Design": {
      "text_prompt_prefix":
          "Focus on creative expression, design principles, and artistic techniques. ",
      "color_scheme": Color(0xFFDB2777),
      "icon": Icons.palette,
    },
    "Business & Economics": {
      "text_prompt_prefix":
          "Focus on practical applications, case studies, and real-world scenarios. ",
      "color_scheme": Color(0xFF0891B2),
      "icon": Icons.business,
    },
    "Health & Medicine": {
      "text_prompt_prefix":
          "Focus on health education, preventive care, and medical knowledge. ",
      "color_scheme": Color(0xFF65A30D),
      "icon": Icons.medical_services,
    },
    "Engineering": {
      "text_prompt_prefix":
          "Focus on practical engineering principles, design thinking, and problem-solving. ",
      "color_scheme": Color(0xFF475569),
      "icon": Icons.engineering,
    },
    "Psychology": {
      "text_prompt_prefix":
          "Focus on human behavior, cognitive processes, and psychological theories. ",
      "color_scheme": Color(0xFFC026D3),
      "icon": Icons.psychology,
    },
    "Languages": {
      "text_prompt_prefix":
          "Focus on language acquisition, communication skills, and cultural context. ",
      "color_scheme": Color(0xFFEA580C),
      "icon": Icons.language,
    },
    "General Education": {
      "text_prompt_prefix":
          "Focus on comprehensive learning, critical thinking, and interdisciplinary connections. ",
      "color_scheme": Color(0xFF4F46E5),
      "icon": Icons.school,
    },
  };

  // Book type configurations
  static final Map<String, Map<String, dynamic>> BOOK_TYPE_CONFIGS = {
    "Textbook": {
      "structure":
          "1. Learning Objectives\n2. Key Terms\n3. Detailed Explanation\n4. Examples\n5. Practice Problems\n6. Summary",
      "tone": "Academic, formal",
    },
    "Exam-prep Notes": {
      "structure":
          "1. Quick Definition\n2. Key Formulas\n3. Common Questions\n4. Memory Tricks\n5. Mistakes to Avoid",
      "tone": "Concise, practical",
    },
    "Story-style Guide": {
      "structure":
          "1. Story Introduction\n2. Character Dialogues\n3. Real-world Analogy\n4. Practical Application\n5. Moral Lesson",
      "tone": "Narrative, engaging",
    },
    "Research Manual": {
      "structure":
          "1. Research Context\n2. Methodologies\n3. Case Studies\n4. Data Analysis\n5. References",
      "tone": "Technical, precise",
    },
    "Beginner's Handbook": {
      "structure":
          "1. Simple Definition\n2. Step-by-Step Guide\n3. Hands-on Exercise\n4. Common Questions\n5. Progress Checklist",
      "tone": "Friendly, simple",
    },
  };

  // Form controllers
  final TextEditingController _bookNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _topicsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // State variables
  String _selectedField = "General Education";
  String _selectedBookType = "Textbook";
  bool _isGenerating = false;
  double _generationProgress = 0.0;
  String _currentStatus = "";
  List<String> _topicsList = [];
  String _generatedContent = "";
  String? _pdfFilePath;
  bool _showPreview = false;

  @override
  void dispose() {
    _bookNameController.dispose();
    _descriptionController.dispose();
    _topicsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Clean and parse topics from user input
  List<String> cleanTopics(String rawText) {
    final List<String> topics = [];
    final lines = rawText.split('\n');

    for (final line in lines) {
      // Remove leading numbers, bullets, etc.
      String cleanedLine = line
          .replaceAll(RegExp(r'^[\d\.\)\-\•\s]+'), '')
          .trim();

      if (cleanedLine.isNotEmpty) {
        // Split by commas or "and"
        final parts = cleanedLine.split(RegExp(r',| and '));

        for (final part in parts) {
          final topic = part.trim();
          if (topic.isNotEmpty) {
            topics.add(topic);
          }
        }
      }
    }

    return topics;
  }

  /// Generate field-specific prompt for content generation
  String generateFieldSpecificPrompt({
    required String topic,
    required String bookType,
    required String field,
    required String bookName,
    String bookDescription = "",
  }) {
    final fieldConfig =
        FIELD_CONFIGS[field] ?? FIELD_CONFIGS["General Education"]!;
    final bookTypeConfig =
        BOOK_TYPE_CONFIGS[bookType] ?? BOOK_TYPE_CONFIGS["Textbook"]!;

    return """
Write a chapter on "$topic" for a $bookType in the field of $field.

Book: $bookName
Field: $field
${bookDescription.isNotEmpty ? "Description: $bookDescription" : ""}

${fieldConfig['text_prompt_prefix']}

Structure this chapter with:
${bookTypeConfig['structure']}

Tone: ${bookTypeConfig['tone']}
Style: Educational, engaging, and practical for $field students.

Focus on:
1. Core concepts relevant to $field
2. Practical applications in $field
3. Common challenges and solutions
4. Real-world examples from $field
5. Connections to broader $field knowledge

Make it comprehensive yet accessible, with clear explanations suitable for learners.""";
  }

  /// Call Google Gemini API to generate content
  Future<String> generateChapterContent({
    required String topic,
    required String bookType,
    required String field,
    required String bookName,
    String bookDescription = "",
  }) async {
    try {
      final prompt = generateFieldSpecificPrompt(
        topic: topic,
        bookType: bookType,
        field: field,
        bookName: bookName,
        bookDescription: bookDescription,
      );

      // Google Gemini API call
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$GOOGLE_API_KEY',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
          "generationConfig": {
            "temperature": 0.7,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 2048,
          },
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final candidates = data['candidates'];
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          if (content != null) {
            final parts = content['parts'];
            if (parts != null && parts.isNotEmpty) {
              return parts[0]['text'] ?? "No content generated";
            }
          }
        }
        return "Error: Invalid response format";
      } else {
        return "Error: API request failed with status ${response.statusCode}";
      }
    } catch (e) {
      return "Error generating content: $e";
    }
  }

  /// Generate complete book
  Future<void> generateBook() async {
    if (_bookNameController.text.isEmpty) {
      showError("Please enter a book title");
      return;
    }

    if (_topicsController.text.isEmpty) {
      showError("Please enter at least one topic");
      return;
    }

    setState(() {
      _isGenerating = true;
      _generationProgress = 0.0;
      _topicsList = cleanTopics(_topicsController.text);
      _generatedContent = "";
      _pdfFilePath = null;
      _showPreview = false;
    });

    // Start book content
    final fieldConfig = FIELD_CONFIGS[_selectedField]!;
    final Color fieldColor = fieldConfig['color_scheme'] as Color;

    String bookContent = "📚 ${_bookNameController.text}\n";
    bookContent += "=" * 50 + "\n";
    bookContent += "Field: $_selectedField\n";
    bookContent += "Book Type: $_selectedBookType\n";
    if (_descriptionController.text.isNotEmpty) {
      bookContent += "Description: ${_descriptionController.text}\n";
    }
    bookContent += "Generated with KiddoBookAI\n";
    bookContent += "=" * 50 + "\n\n";

    // Generate each chapter
    for (int i = 0; i < _topicsList.length; i++) {
      final topic = _topicsList[i];

      setState(() {
        _currentStatus =
            "Generating Chapter ${i + 1}/${_topicsList.length}: $topic";
        _generationProgress = (i) / _topicsList.length;
      });

      // Generate chapter content
      final chapterContent = await generateChapterContent(
        topic: topic,
        bookType: _selectedBookType,
        field: _selectedField,
        bookName: _bookNameController.text,
        bookDescription: _descriptionController.text,
      );

      bookContent += "\n" + "=" * 40 + "\n";
      bookContent += "Chapter ${i + 1}: $topic\n";
      bookContent += "=" * 40 + "\n";
      bookContent += chapterContent + "\n";

      setState(() {
        _generatedContent = bookContent;
        _generationProgress = (i + 1) / _topicsList.length;
      });
    }

    // Generate PDF
    await generatePDF(bookContent, fieldColor);

    setState(() {
      _isGenerating = false;
      _currentStatus = "Book generated successfully!";
      _showPreview = true;
    });

    // Scroll to preview
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  /// Generate PDF from content
  Future<void> generatePDF(String content, Color fieldColor) async {
    try {
      final pdf = pw.Document();

      // Convert Flutter Color to PDF Color
      // Extract RGB values from Flutter Color
      final int colorValue = fieldColor.value;
      final int red = (colorValue >> 16) & 0xFF;
      final int green = (colorValue >> 8) & 0xFF;
      final int blue = colorValue & 0xFF;

      // Create PDF color from RGB values (0-1 range)
      final pdfColor = PdfColor.fromInt(colorValue); // This is the correct way

      // Add a cover page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'KiddoBookAI',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: pdfColor, // Use the created PDF color
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  _bookNameController.text,
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'A $_selectedBookType for $_selectedField',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 20),
                if (_descriptionController.text.isNotEmpty)
                  pw.Text(
                    _descriptionController.text,
                    style: pw.TextStyle(fontSize: 14),
                  ),
                pw.Spacer(),
                pw.Text(
                  'Generated with KiddoBookAI',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Add content pages
      final lines = content.split('\n');
      final List<String> currentPageLines = [];
      int lineCount = 0;

      for (final line in lines) {
        currentPageLines.add(line);
        lineCount++;

        // Start new page after 40 lines
        if (lineCount >= 40 || line.contains('Chapter')) {
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return pw.Padding(
                  padding: pw.EdgeInsets.all(40),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: currentPageLines.map((text) {
                      return pw.Padding(
                        padding: pw.EdgeInsets.only(bottom: 8),
                        child: pw.Text(
                          text,
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: pdfColor, // Use the created PDF color
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          );
          currentPageLines.clear();
          lineCount = 0;
        }
      }

      // Add remaining lines
      if (currentPageLines.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Padding(
                padding: pw.EdgeInsets.all(40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: currentPageLines.map((text) {
                    return pw.Padding(
                      padding: pw.EdgeInsets.only(bottom: 8),
                      child: pw.Text(
                        text,
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: pdfColor, // Use the created PDF color
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        );
      }

      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/book_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _pdfFilePath = file.path;
      });
    } catch (e) {
      showError("Failed to generate PDF: $e");
    }
  }

  /// Download PDF
  Future<void> downloadPDF() async {
    if (_pdfFilePath == null) {
      showError("No PDF generated yet");
      return;
    }

    try {
      await OpenFile.open(_pdfFilePath!);
    } catch (e) {
      showError("Failed to open PDF: $e");
    }
  }

  /// Show error dialog
  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Reset form
  void resetForm() {
    _bookNameController.clear();
    _descriptionController.clear();
    _topicsController.clear();
    setState(() {
      _selectedField = "General Education";
      _selectedBookType = "Textbook";
      _isGenerating = false;
      _generatedContent = "";
      _pdfFilePath = null;
      _showPreview = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Book Generation"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _pdfFilePath != null ? downloadPDF : null,
            tooltip: "Download PDF",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Field Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select Field of Study",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: FIELD_CONFIGS.keys.map((field) {
                          final config = FIELD_CONFIGS[field]!;
                          final isSelected = _selectedField == field;
                          return ChoiceChip(
                            label: Text(field),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedField = field;
                              });
                            },
                            backgroundColor: config['color_scheme']!
                                .withOpacity(0.1),
                            selectedColor: config['color_scheme'],
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : config['color_scheme'],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Book Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Book Details",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _bookNameController,
                        decoration: InputDecoration(
                          labelText: "Book Title *",
                          hintText: "Enter book title",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Description (Optional)",
                          hintText: "Describe your book",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedBookType,
                        decoration: InputDecoration(
                          labelText: "Book Style *",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.style),
                        ),
                        items: BOOK_TYPE_CONFIGS.keys.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedBookType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 16),

              // Topics Input
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Topics",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Enter topics (one per line or comma separated)",
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: _topicsController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText:
                              "Topic 1\nTopic 2\nTopic 3\n\nOr: Topic 1, Topic 2, Topic 3",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.list),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),

              // Generate Button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : generateBook,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      child: _isGenerating
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text("Generating..."),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.auto_stories),
                                SizedBox(width: 8),
                                Text("Generate Book"),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(width: 12),
                  OutlinedButton(onPressed: resetForm, child: Text("Reset")),
                ],
              ),

              // Progress Indicator
              if (_isGenerating) ...[
                SizedBox(height: 20),
                LinearProgressIndicator(
                  value: _generationProgress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _currentStatus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              // Generated Content Preview
              if (_showPreview && _generatedContent.isNotEmpty) ...[
                SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_stories,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Generated Book Preview",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Spacer(),
                            if (_pdfFilePath != null)
                              ElevatedButton.icon(
                                onPressed: downloadPDF,
                                icon: Icon(Icons.download),
                                label: Text("Download PDF"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color.fromARGB(255, 227, 183, 183),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _generatedContent,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Monospace',
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
