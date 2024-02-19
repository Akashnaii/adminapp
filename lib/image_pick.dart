import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class MyImagePickerScreen extends StatefulWidget {
  final String movieId;
  final String selectId;
  const MyImagePickerScreen({Key?key,required this.movieId , required this.selectId}): super(key: key);
  @override
  _MyImagePickerScreenState createState() => _MyImagePickerScreenState();
}

class _MyImagePickerScreenState extends State<MyImagePickerScreen> {
  String imageName = '';
  List<ImageData> _imageDataList = [];
  TextEditingController nameController = TextEditingController();
  bool isLoading = false;
  void addDocument(String castImage, String castName) async {
    DocumentReference movieDocument = FirebaseFirestore.instance.collection(widget.selectId).doc(widget.movieId);

    try {
      DocumentSnapshot movieSnapshot = await movieDocument.get();

      if (movieSnapshot.exists) {
        // Movie document doesn't exist, create it
        // await movieDocument.set({});
        List<Map<String, dynamic>> castData = List<Map<String, dynamic>>.from((movieSnapshot.data() as Map<String, dynamic>)['Cast'] ?? []);
        castData.add({
          'cast_image': castImage,
          'cast_name': castName,
        });
        await movieDocument.update({"Cast": castData});
      }
    } catch (e) {
      print('Error adding document: $e');
    }
  }






  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? imagePaths = prefs.getStringList('cast_image');
    List<String>? imageNames = prefs.getStringList('cast_name');

    if (imagePaths != null && imageNames != null) {
      for (int i = 0; i < imagePaths.length; i++) {
        _imageDataList.add(ImageData(imagePaths[i], imageNames[i]));
      }
    }
  }


  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      final Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('movie_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

      setState(() {
        isLoading =true;
      });
      await storageReference.putFile(imageFile);

      final String imageUrl = await storageReference.getDownloadURL();
      setState(() {
        isLoading =false;
      });
      _showNameInputDialog(imageUrl);
      // addDocument(imageUrl, imageName);
    }
  }

  Future<void> _showNameInputDialog(String imagePath) async {
    String imageName = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Image Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Image Name'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  addDocument(imagePath, nameController.text.trim());
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

  }

  void _deleteImage(int index) async {
    try {
      // Get a reference to the 'movies' collection
      CollectionReference moviesCollection = FirebaseFirestore.instance.collection('movies');

      // Get the document reference for the specific movie
      DocumentReference movieDocument = moviesCollection.doc(widget.movieId);

      // Fetch the current data of the movie document
      DocumentSnapshot movieSnapshot = await movieDocument.get();

      // Extract the existing 'Cast' data or initialize an empty list
      List<Map<String, dynamic>> castData = List<Map<String, dynamic>>.from((movieSnapshot.data() as Map<String, dynamic>)['Cast'] ?? []);

      // Check if the index is within the valid range
      if (index >= 0 && index < castData.length) {
        // Remove the item at the specified index
        castData.removeAt(index);

        // Update the 'Cast' field in the 'movies' document
        await movieDocument.update({'Cast': castData});
        print('Data deleted successfully!');
      } else {
        print('Invalid index for deletion.');
      }
    } catch (e) {
      print('Error deleting data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Multiple Image Picker'),
      ),
      body:isLoading? Center(child: CircularProgressIndicator()) : Column(
        children: [
          SizedBox(
            height: 250,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _imageDataList.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Image.file(
                        File(_imageDataList[index].path),
                        height: 100,
                        width: 100,
                      ),
                      SizedBox(height: 8),
                      Text(_imageDataList[index].name),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          _deleteImage(index);
                        },
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Pick Image'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text("data will be added successfully")
                  ));
          Navigator.pop(context);
            },
            child: Text('Submit'),
          ),

        ],
      ),
    );
  }
}

class ImageData {
  final String path;
  final String name;

  ImageData(this.path, this.name);
}
