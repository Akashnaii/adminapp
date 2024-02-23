import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'dart:io';

import 'image_pick.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

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
  String? dropdownvalue;
  String? select = 'movies';

  var items = ['movies', 'Standup comedy', 'Concert'];
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController ratingController = TextEditingController();
  File? _selectedImage;
  List<Map<String, dynamic>> castList = [];
  List<QueryDocumentSnapshot> movies = [];

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

  Future<void> _uploadImage(BuildContext context, String movieId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        String filePath = file.path!;
        File newImage = File(filePath);
        debugPrint("newImage ${newImage}");

        final Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('movie_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageReference.putFile(newImage);

        final String imageUrl = await storageReference.getDownloadURL();
        // debugPrint("imageUrl ${imageUrl}");

        // double rating = 0.0;
        // if (ratingController.text.isNotEmpty) {
        //   rating = double.tryParse(ratingController.text) ?? 0.0;
        // }

        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Image updated successfully!')),
        // );

        debugPrint("imageUrl:${imageUrl}");
        await FirebaseFirestore.instance
            .collection(select.toString())
            .doc(movieId)
            .update({
          'image_url': imageUrl,
          // 'rating': rating,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a new image.')),
        );
      }
    } catch (error) {
      print("Error uploading image: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update image: $error'),
        ),
      );
    }
  }

  void _addMovie(BuildContext context) async {
    print("add the movie..");
    try {
      if (_selectedImage != null) {
        final Reference storageReference = FirebaseStorage.instance
            .ref()
            .child('movie_images/${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageReference.putFile(_selectedImage!);
        final String imageUrl = await storageReference.getDownloadURL();
        double rating = double.tryParse(ratingController.text) ?? 0.0;

        await FirebaseFirestore.instance.collection(dropdownvalue.toString()).add({
          'name': nameController.text,
          'description': descriptionController.text,
          'ticket_price': double.parse(priceController.text),
          'image_url': imageUrl,
          'Cast': castList,
          'rating': rating,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Movie added successfully!')),
        );

        nameController.clear();
        descriptionController.clear();
        priceController.clear();
        setState(() {
          _selectedImage = null;
          castList.clear();
        });
        ratingController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image first.')),
        );
      }
    } catch (error) {
      print("Error adding movie: $error");
    }
  }

  Future<void> refreshData() async {
    try {
      await FirebaseFirestore.instance
          .collection('movies')
          .get()
          .then((QuerySnapshot querySnapshot) {
        movies = querySnapshot.docs;
        setState(() {});
      });
    } catch (error) {
      print("Error refreshing data: $error");
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
        title: const Text("MovieMate", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              nameController.clear();
              priceController.clear();
              descriptionController.clear();
              ratingController.clear();
              _selectedImage = null;
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(builder: (context, setState) {
                    return SingleChildScrollView(
                      child: AlertDialog(
                        scrollable: true,
                        title: const Text('Select Show'),
                        content: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            _selectedImage != null
                                ? Image.file(_selectedImage!)
                                : const SizedBox.shrink(),
                            DropdownButtonFormField<String>(
                              isExpanded: true,
                              hint: const Text("Choose"),
                              value: dropdownvalue,
                              icon: const Icon(Icons.arrow_drop_down),
                              style: const TextStyle(color: Colors.black),
                              items: items.map((String items) {
                                return DropdownMenuItem(
                                  alignment: Alignment.center,
                                  value: items,
                                  child: Text(items),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  dropdownvalue = newValue!;
                                  print("val$dropdownvalue");
                                });
                              },
                            ),
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(labelText: 'Title'),
                            ),
                            TextFormField(
                              controller: descriptionController,
                              decoration: const InputDecoration(labelText: 'Description'),
                            ),
                            TextFormField(
                              controller: priceController,
                              decoration: const InputDecoration(labelText: 'Ticket Price'),
                              keyboardType: TextInputType.number,
                            ),
                            TextFormField(
                              controller: ratingController,
                              decoration: const InputDecoration(labelText: 'Rating'),
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(RegExp(r'^[0-5]'))
                              ],
                            ),
                            Row(
                              children: [
                                const Spacer(),
                                ElevatedButton(
                                  onPressed: _pickImage,
                                  child: const Text('Pick Image'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        actions: [
                          ElevatedButton(
                            onPressed: () {
                              _addMovie(context);
                              Navigator.of(context).pop();
                            },
                            child: const Text('Add Show'),
                          ),
                        ],
                      ),
                    );
                  });
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              alignment: Alignment.center,
              isExpanded: true,
              hint: const Center(child: Text("Choose")),
              value: select,
              icon: const Icon(Icons.arrow_drop_down),
              style: const TextStyle(color: Colors.black),
              items: items.map((String items) {
                return DropdownMenuItem(
                  alignment: Alignment.center,
                  value: items,
                  child: Center(child: Text(items)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  select = newValue!;
                  print("val$select");
                });
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection(select.toString()).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<QueryDocumentSnapshot> movies = snapshot.data!.docs;

                return RefreshIndicator(
                  onRefresh: refreshData,
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: movies.length,
                    itemBuilder: (context, index) {
                      var movieData = movies[index].data() as Map<String, dynamic>?;

                      if (movieData == null) {
                        return const ListTile(
                          title: Text("Invalid Movie Data"),
                          subtitle: Text("Movie data is missing."),
                        );
                      }

                      String name = movieData['name'] ?? 'N/A';
                      String description = movieData['description'] ?? 'N/A';
                      String ticketPrice = movieData['ticket_price']?.toString() ?? "0.0";
                      String imageUrl = movieData['image_url'] ?? '';

                      if (name.isEmpty || description.isEmpty) {
                        return const ListTile(
                          title: Text("Invalid Movie Data"),
                          subtitle: Text("Movie data is missing or invalid."),
                        );
                      }

                      return ListTile(
                        title: Text(name),
                        subtitle: Text(description),
                        trailing: Container(
                          width: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      final nameController =
                                      TextEditingController(text: movieData['name']);
                                      final descriptionController =
                                      TextEditingController(text: movieData['description']);
                                      final priceController =
                                      TextEditingController(text: movieData['ticket_price'].toString());
                                      final ratingController =
                                      TextEditingController(text: movieData['rating'].toString());

                                      return AlertDialog(
                                        scrollable: true,
                                        title: const Text('Edit Movie'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Image.network(imageUrl),
                                            TextFormField(
                                              controller: nameController,
                                              decoration: const InputDecoration(labelText: 'Movie Name'),
                                            ),
                                            TextFormField(
                                              controller: descriptionController,
                                              decoration: const InputDecoration(labelText: 'Description'),
                                            ),
                                            TextFormField(
                                              controller: priceController,
                                              decoration: const InputDecoration(labelText: 'Ticket Price'),
                                              keyboardType: TextInputType.number,
                                            ),
                                            TextFormField(
                                              controller: ratingController,
                                              decoration: const InputDecoration(labelText: 'Rating'),
                                              keyboardType: TextInputType.number,
                                            ),
                                            ElevatedButton(
                                              onPressed: ()  {
                                                 _uploadImage(context, movies[index].id);
                                                Navigator.of(context).pop(); // Close the dialog
                                              },
                                              child: const Text('Update Image'),
                                            ),

                                          ],
                                        ),
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              if (context == null) {
                                                print("Error: Context is null.");
                                                return;
                                              }

                                              Navigator.of(context).pop();

                                              try {
                                                await FirebaseFirestore.instance
                                                    .collection(select.toString())
                                                    .doc(movies[index].id)
                                                    .update({
                                                  'name': nameController.text,
                                                  'description': descriptionController.text,
                                                  'ticket_price': double.parse(priceController.text),
                                                  'rating': double.parse(ratingController.text),
                                                  'image_url': imageUrl,
                                                });

                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Movie updated successfully!'),
                                                  ),
                                                );
                                              } catch (error) {
                                                print("Error updating movie: $error");
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed to update movie: $error'),
                                                  ),
                                                );
                                              }
                                            },
                                            child: Text('Update $select'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              FirebaseFirestore.instance
                                                  .collection(select.toString())
                                                  .doc(movies[index].id)
                                                  .delete()
                                                  .then((_) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('$select deleted successfully!'),
                                                  ),
                                                );
                                              }).catchError((error) {
                                                print("Error deleting movie: $error");
                                              });
                                            },
                                            child:  Text('Delete ${select}'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                icon: const Icon(Icons.remove_red_eye),
                              ),
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MyImagePickerScreen(
                                        movieId: movies[index].id,
                                        selectId: select.toString(),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.person),
                              )
                            ],
                          ),
                        ),
                        leading: imageUrl.isNotEmpty
                            ? Image.network(imageUrl)
                            : const Center(
                          child: SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
