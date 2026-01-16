import 'package:flutter/material.dart';

class ClipGeniusPage extends StatelessWidget {
  final VoidCallback onToggleTheme;

  const ClipGeniusPage({super.key, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clip Genius'),
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
                          Icons.video_library,
                          color: Colors.orange.shade700,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Video Clip Creator',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        hintText:
                            'Paste YouTube URL or describe video content...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField(
                            decoration: InputDecoration(
                              labelText: 'Clip Length',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items:
                                [
                                      '30 seconds',
                                      '1 minute',
                                      '2 minutes',
                                      '5 minutes',
                                    ]
                                    .map(
                                      (length) => DropdownMenuItem(
                                        value: length,
                                        child: Text(length),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {},
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: DropdownButtonFormField(
                            decoration: InputDecoration(
                              labelText: 'Focus',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items:
                                [
                                      'Educational',
                                      'Entertaining',
                                      'Summary',
                                      'Highlights',
                                    ]
                                    .map(
                                      (focus) => DropdownMenuItem(
                                        value: focus,
                                        child: Text(focus),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Create Clip',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Clips',
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
                      leading: const Icon(Icons.videocam, color: Colors.red),
                      title: Text('Clip ${index + 1} - Math Tutorial'),
                      subtitle: const Text('Duration: 2:30'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.download),
                            onPressed: () {},
                          ),
                        ],
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
