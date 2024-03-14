import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'image_pick.dart';

class movies extends StatelessWidget {
  const movies({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movie Admin App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MovieListPage(),
    );
  }
}

class MovieListPage extends StatefulWidget {
  @override
  _MovieListPageState createState() => _MovieListPageState();
}

class _MovieListPageState extends State<MovieListPage> {
  String? dropdownValue;
  String? selectedCategory = 'movies';

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController ratingController = TextEditingController();
  File? _selectedImage;
  List<Map<String, dynamic>> castList = [];

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      String filePath = file.path!;
      File pickedImage = File(filePath);

      setState(() {
        _selectedImage = pickedImage;
      });
    }
  }

  Future<void> _addMovie(BuildContext context) async {
    try {
      if (_selectedImage != null) {
        final Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('movies/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageReference.putFile(_selectedImage!);
        final String imageUrl = await storageReference.getDownloadURL();

        // Add movie to the "movies" collection
        await FirebaseFirestore.instance.collection('movies').add({
          'name': nameController.text,
          'description': descriptionController.text,
          'ticket_price': double.parse(priceController.text),
          'image_url': imageUrl,
          'Cast': castList,
          'rating': double.tryParse(ratingController.text) ?? 0.0,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movie added successfully!')),
        );

        // Clear form fields and image selection
        nameController.clear();
        descriptionController.clear();
        priceController.clear();
        ratingController.clear();
        setState(() {
          _selectedImage = null;
          castList.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image first.')),
        );
      }
    } catch (error) {
      print("Error adding movie: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text(
          "MovieMate",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: 200,
              child: DropdownButtonFormField<String>(
                alignment: Alignment.center,
                isExpanded: true,
                hint: Center(child: const Text("Choose")),
                value: selectedCategory,
                icon: const Icon(Icons.arrow_drop_down),
                style: const TextStyle(color: Colors.black),
                items: ['movies', 'standup_comedy', 'concert'].map((String category) {
                  return DropdownMenuItem(
                    alignment: Alignment.center,
                    value: category,
                    child: Center(child: Text(category)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCategory = newValue!;
                    print("Category selected: $selectedCategory");
                  });
                },
              ),
            ),
            // Your other UI elements and widgets
            // For example, add movie form, list of movies, etc.
          ],
        ),
      ),
    );
  }
}
