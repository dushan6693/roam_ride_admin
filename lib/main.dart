import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'login.dart';

void main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
    );
  }
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  UploadScreenState createState() => UploadScreenState();
}

class UploadScreenState extends State<UploadScreen> {
  File? _image;
  String? _selectedDistrict;
  String? _selectedType;
  double _rating = 0;
  bool _isLoading = false;
  final TextEditingController _placeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> districts = [
    'Ampara',
    'Anuradhapura',
    'Badulla',
    'Batticaloa',
    'Colombo',
    'Galle',
    'Gampaha',
    'Hambantota',
    'Jaffna',
    'Kalutara',
    'Kandy',
    'Kegalle',
    'Kilinochchi',
    'Kurunegala',
    'Mannar',
    'Matale',
    'Matara',
    'Moneragala',
    'Mullaitivu',
    'Nuwara Eliya',
    'Polonnaruwa',
    'Puttalam',
    'Ratnapura',
    'Trincomalee',
    'Vavuniya'
  ];

  final Map<String, int> types = {
    'Religious': 1,
    'Hotel': 2,
    'Villa': 3,
    'Nature': 4,
    'Historical': 5,
    'Museum': 6,
    'Beach': 7,
  };

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadData() async {
    if (_image == null ||
        _placeController.text.isEmpty ||
        _selectedDistrict == null ||
        _selectedType == null ||
        _durationController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields and upload an image')),
      );
      return;
    }

    final duration = int.tryParse(_durationController.text);

    if (_rating < 0 || _rating > 5 || duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Please provide valid inputs for Rating and Duration')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Rename image with current timestamp
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      TaskSnapshot snapshot = await FirebaseStorage.instance
          .ref('images/$fileName')
          .putFile(_image!);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Save data to Firestore
      await FirebaseFirestore.instance.collection('places').add({
        'id': fileName,
        'place': _placeController.text,
        'district': _selectedDistrict,
        'type': types[_selectedType],
        'image_url': downloadUrl,
        'rating': _rating,
        'duration': duration,
        'description': _descriptionController.text
      });
      await FirebaseFirestore.instance.collection('districts').add({
        'district': _selectedDistrict,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data uploaded successfully')),
      );
      _placeController.clear();
      _durationController.clear();
      setState(() {
        _image = null;
        _selectedDistrict = null;
        _selectedType = null;
        _rating = 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload to Firebase')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _pickImage,
                child: Text('Pick Image'),
              ),
              if (_image != null)
                Image.file(
                  _image!,
                  height: 150,
                ),
              SizedBox(height: 16),
              TextField(
                controller: _placeController,
                decoration: InputDecoration(
                  labelText: 'Enter place',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              DropdownButton<String>(
                hint: Text('Select Type'),
                value: _selectedType,
                items: types.keys.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('Rating: ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Row(
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setState(() {
                              _rating = index + 1.0;
                            });
                          },
                        );
                      }),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter duration (minutes)',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              DropdownButton<String>(
                hint: Text('Select District'),
                value: districts.contains(_selectedDistrict)
                    ? _selectedDistrict
                    : null,
                items: districts.map((district) {
                  return DropdownMenuItem(
                    value: district,
                    child: Text(district),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDistrict = value;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  minLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Explain about this place',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(3.0),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                  ),
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(height: 16),
              ),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _uploadData,
                      child: Text('Upload Data'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user != null) {
            // User is signed in, load the home page
            return UploadScreen();
          } else {
            // User is not signed in, load the login page
            return Login();
          }
        } else {
          // Show a loading indicator while checking the authentication state
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
