import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Contest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Photo Contest'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> images = [];

  Future<void> fetchImages() async {
    final response = await http.get(Uri.parse('http://stsepilov.pythonanywhere.com/images'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        images = List<Map<String, dynamic>>.from(data);
        images.sort((a, b) => b['rating'].compareTo(a['rating']));
      });
    } else {
      throw Exception('Failed to load images');
    }
  }

  Future<void> updateRating(int imageId, int newRating) async {
    final response = await http.post(
      Uri.parse('http://stsepilov.pythonanywhere.com/images/$imageId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'rating': newRating}),
    );

    if (response.statusCode == 200) {
      fetchImages();
    } else {
      throw Exception('Failed to send vote');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
          minimum: const EdgeInsets.all(5),
          child: Column(children: [
            Expanded(child: _listView(images, updateRating)),
          ])),
    );
  }
}

Widget _listView(List<Map<String, dynamic>> images, Function updateRating) {
  return ListView.separated(
    itemCount: images.length,
    itemBuilder: (context, index) {
      final image = images[index];
      const baseUrl = 'http://stsepilov.pythonanywhere.com/';
      return Stack(
        children: [
          Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Image.network(
              '$baseUrl${image["url"]}',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 30,
            child: IconButton(
              onPressed: () => updateRating(image["id"], image['rating'] + 1),
              icon: const Icon(Icons.thumb_up, color: Colors.white),
            ),
          ),
          Positioned(
            right: 0,
            child: IconButton(
              onPressed: () => updateRating(image["id"], image['rating'] - 1),
              icon: const Icon(Icons.thumb_down, color: Colors.white),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Text(
                'Rating: ${image["rating"]}',  // Доступ к ключу 'rating' для отображения рейтинга
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      );
    },
    separatorBuilder: (context, index) {
      return const SizedBox(height: 10);
    },
  );
}
