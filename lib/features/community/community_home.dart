import 'package:flutter/material.dart';
import 'mistral_community_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CommunityHome extends StatelessWidget {
  const CommunityHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.forum),
            title: const Text('Discussions'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const CommunityDiscussions(),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.announcement),
            title: const Text('News & Updates'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const CommunityNews(),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Events'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const CommunityEvents(),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('User Stories'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => const CommunityStories(),
              ));
            },
          ),
        ],
      ),
    );
  }
}

class CommunityDiscussions extends StatefulWidget {
  const CommunityDiscussions({super.key});

  @override
  State<CommunityDiscussions> createState() => _CommunityDiscussionsState();
}

class _CommunityDiscussionsState extends State<CommunityDiscussions> {
  String? content;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchContent();
  }

  Future<void> fetchContent() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await MistralCommunityService().fetchSectionContent(
        'Generate a list of trending community discussions in agriculture. Each discussion should have a title and a short description.'
      );
      setState(() {
        content = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load discussions.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Discussions')),
        body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
            ? Center(child: Text(error!))
            : Markdown(
              data: content ?? '',
              padding: const EdgeInsets.all(16),
            ),
    );
  }
}

class CommunityNews extends StatefulWidget {
  const CommunityNews({super.key});

  @override
  State<CommunityNews> createState() => _CommunityNewsState();
}

class _CommunityNewsState extends State<CommunityNews> {
  String? content;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchContent();
  }

  Future<void> fetchContent() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await MistralCommunityService().fetchSectionContent(
        'Provide the latest news and updates in the agriculture sector relevant for a farming community.'
      );
      setState(() {
        content = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load news.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('News & Updates')),
        body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
            ? Center(child: Text(error!))
            : Markdown(
              data: content ?? '',
              padding: const EdgeInsets.all(16),
            ),
    );
  }
}

class CommunityEvents extends StatefulWidget {
  const CommunityEvents({super.key});

  @override
  State<CommunityEvents> createState() => _CommunityEventsState();
}

class _CommunityEventsState extends State<CommunityEvents> {
  String? content;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchContent();
  }

  Future<void> fetchContent() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await MistralCommunityService().fetchSectionContent(
        'List upcoming agriculture-related events, webinars, or community meetups with a short description for each.'
      );
      setState(() {
        content = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load events.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
        body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
            ? Center(child: Text(error!))
            : Markdown(
              data: content ?? '',
              padding: const EdgeInsets.all(16),
            ),
    );
  }
}

class CommunityStories extends StatefulWidget {
  const CommunityStories({super.key});

  @override
  State<CommunityStories> createState() => _CommunityStoriesState();
}

class _CommunityStoriesState extends State<CommunityStories> {
  String? content;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchContent();
  }

  Future<void> fetchContent() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await MistralCommunityService().fetchSectionContent(
        'Share inspiring user stories or success stories from farmers who have benefited from technology or community support.'
      );
      setState(() {
        content = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Failed to load stories.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Stories')),
        body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
            ? Center(child: Text(error!))
            : Markdown(
              data: content ?? '',
              padding: const EdgeInsets.all(16),
            ),
    );
  }
}
