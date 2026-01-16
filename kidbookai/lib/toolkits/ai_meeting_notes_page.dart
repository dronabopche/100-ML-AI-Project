import 'package:flutter/material.dart';

class AIMeetingNotesPage extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const AIMeetingNotesPage({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Meeting Notes'),
        backgroundColor: Colors.orange.shade700,
        actions: [
          IconButton(
            onPressed: onToggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              color: isDark ? Colors.grey.shade900 : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notes,
                          color: Colors.orange.shade700,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'AI Meeting Assistant',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Record or upload meeting audio to get AI-generated notes, summaries, and action items.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.orange.shade100,
                              child: IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.mic,
                                  color: Colors.orange.shade700,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text('Record'),
                          ],
                        ),
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.orange.shade100,
                              child: IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.upload,
                                  color: Colors.orange.shade700,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text('Upload'),
                          ],
                        ),
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.orange.shade100,
                              child: IconButton(
                                onPressed: () {},
                                icon: Icon(
                                  Icons.text_fields,
                                  color: Colors.orange.shade700,
                                  size: 30,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text('Type'),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Recent Meeting Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.notes, color: Colors.orange),
                      title: Text('Meeting ${index + 1} - Project Discussion'),
                      subtitle: const Text(
                        'Date: Today | Duration: 45 minutes',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.summarize),
                        onPressed: () {},
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
