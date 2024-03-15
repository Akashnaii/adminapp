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
  TextEditingController updateNameController = TextEditingController();
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
        nameController.clear();
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
  
  Future<void> _updatepickImage(index,String name) async {
    updateNameController.text = name;
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
      _updateshowNameInputDialog(index,imageUrl);
      // addDocument(imageUrl, imageName);
    }
  }
  
  Future<void> _updateshowNameInputDialog(index,String imagePath) async {
    String imageName = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter Cast Name'),
          content: TextField(
            controller: updateNameController,
            decoration: InputDecoration(labelText: 'Cast Name'),
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
                _updateimage(index,imagePath, updateNameController.text.trim());
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

  }

  Future<void> _deleteshowNameInputDialog(index) async {
    String imageName = '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete cast'),
          content: Text("Are you sure you want delete this Cast?"),
          actions: [
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.normal,
                  color: Colors.white,
                ),
              ),
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
              ),
              onPressed: () async {
                _deleteImage(index);
                Navigator.pop(context);
              },
              child: Text('delete',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.normal,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

  }


  void _deleteImage(int index) async {
    try {
      // Get a reference to the 'movies' collection
      CollectionReference moviesCollection = FirebaseFirestore.instance.collection(widget.selectId);

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
  void _updateimage(int index,castImage,castName) async {
    try {
      // Get a reference to the 'movies' collection
      CollectionReference moviesCollection = FirebaseFirestore.instance.collection(widget.selectId);

      // Get the document reference for the specific movie
      DocumentReference movieDocument = moviesCollection.doc(widget.movieId);

      // Fetch the current data of the movie document
      DocumentSnapshot movieSnapshot = await movieDocument.get();

      // Extract the existing 'Cast' data or initialize an empty list
      List<Map<String, dynamic>> castData = List<Map<String, dynamic>>.from((movieSnapshot.data() as Map<String, dynamic>)['Cast'] ?? []);

      // Check if the index is within the valid range
      if (index >= 0 && index < castData.length) {
        // Remove the item at the specified index
        // castData.removeAt(index);

        castData[index]['cast_image'] = castImage;
        castData[index]['cast_name'] = castName;

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
        title: Text('Cast'),
      ),
      body:isLoading? Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(width: 10,),
              Expanded(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
                  ),
                  onPressed: _pickImage,
                  child: Text('Add Cast',
                    style: TextStyle(
                    fontSize: 17,
                    fontStyle: FontStyle.normal,
                    color: Colors.white,
                  ),
                  ),
                ),
              ),
              SizedBox(width: 10,),
              Expanded(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text("data will be added successfully")
                        ));
                    Navigator.pop(context);
                  },
                  child: Text('Submit',
                    style: TextStyle(
                      fontSize: 17,
                      fontStyle: FontStyle.normal,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10,),
            ],
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(widget.selectId)
                  .doc(widget.movieId)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                Map<String, dynamic>? movieData = snapshot.data!.data();
                if (movieData == null || !movieData.containsKey('Cast')) {
                  return Center(child: Text('No cast data available.'));
                }
                List<dynamic>? castData = movieData['Cast'];
                if (castData == null || castData.isEmpty) {
                  return Center(child: Text('No cast data available.'));
                }
                return ListView(
                  physics: BouncingScrollPhysics(),
                  children: List.generate(castData.length, (index) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 12,vertical: 10),
                      alignment: Alignment.center,
                      margin: EdgeInsets.symmetric(horizontal: 16,vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey[350],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.black38
                        )
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width*0.2,
                                height:  MediaQuery.of(context).size.height*0.09,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black),
                                  // Add any additional styling you need for the container here
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    castData[index]['cast_image'],
                                    fit: BoxFit.cover,
                                    width: 80,
                                    height: 80,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10,),
                              SizedBox(
                                  width: 75,
                                  child: Text(castData[index]['cast_name'] , textAlign: TextAlign.center,)),
                            ],
                          ),
                          SizedBox(width: 15,),
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
                            ),
                            onPressed: () {
                              _deleteshowNameInputDialog(index);
                            },
                            child: Text('Delete',
                              style: TextStyle(
                                fontSize: 15,
                                fontStyle: FontStyle.normal,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 15,),
                          ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(Colors.black),

                            ),
                            onPressed: () {
                              _updatepickImage(index,castData[index]['cast_name']);
                            },
                            child: Text('Update',
                              style: TextStyle(
                                fontSize: 15,
                                fontStyle: FontStyle.normal,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 10,),

                        ],
                      ),
                    );
                  }),
                );
              },
            ),
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
