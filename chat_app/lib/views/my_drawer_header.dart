//@dart=2.9
import 'dart:io';

import 'package:chat_app/helper/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/helperfunctions.dart';
import '../services/auth.dart';
import '../services/database.dart';
import '../widgets/widget.dart';
import 'chatRoomsScreen.dart';

class MyHeaderDrawer extends StatefulWidget {
  @override
  _MyHeaderDrawerState createState() => _MyHeaderDrawerState();

  String email = FirebaseAuth.instance.currentUser?.email as String;
}

class _MyHeaderDrawerState extends State<MyHeaderDrawer> {
  FirebaseStorage storage = FirebaseStorage.instance;
  TextEditingController usernameEditingController = new TextEditingController();
  TextEditingController userintroEditingController =
      new TextEditingController();
  File _userImageFile;
  String _userImageUrl = '';
  String userId;
  String image = 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT2pVWhgXilxQ894sH6mDq-V-oDhoPLEYWUd7m-fh4f0lZIzzGeLaUEObGOsMouGlRA0XM&usqp=CAU';
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getOldValue();
  }

  getOldValue() async {
    QuerySnapshot searchSnapshot;
    databaseMethods.searchByName(Constants.myName).then((val){
      searchSnapshot = val;
      _userImageUrl = searchSnapshot.docs[0].get('userImageUrl').toString();
      userintroEditingController.text = searchSnapshot.docs[0].get('intro').toString();
      usernameEditingController.text = searchSnapshot.docs[0].get('name').toString();
      userId = searchSnapshot.docs[0].get('userId').toString();
    });

    final ListResult result = await FirebaseStorage.instance
        .ref()
        .child('file')
        .child(_userImageUrl)
        .list();
    final List<Reference> allFiles = result.items;
    print(allFiles.length);
    String fileUrl;

    await Future.forEach<Reference>(allFiles, (file) async {
      if(file.fullPath.substring(5) == _userImageUrl) {
        fileUrl = await file.getDownloadURL();
      }
    });
    print("last time:" + fileUrl.toString());
    this.image = fileUrl;

    setState(() {});


  }

  final ImagePicker _picker = ImagePicker();

  Future imgFromGallery() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _userImageFile = File(pickedFile.path);
        final filename = p.basename(_userImageFile.path);
        _userImageUrl = '$filename';
        //uploadFile();
      } else {
        print('No image selected.');
      }
    });
  }

  Future imgFromCamera() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _userImageFile = File(pickedFile.path);
        final filename = p.basename(_userImageFile.path);
        _userImageUrl = '$filename';
        //uploadFile();
      } else {
        print('No image selected.');
      }
    });
  }

  Future uploadFile() async {
    if (_userImageFile == null) return;
    final fileName = p.basename(_userImageFile.path);

    try {
      final ref = FirebaseStorage.instance.ref().child('file/$fileName');
      await ref.putFile(_userImageFile);
    } catch (e) {
      print('error occured');
    }
  }

  AuthService authService = new AuthService();
  DatabaseMethods databaseMethods = new DatabaseMethods();

  final formKey = GlobalKey<FormState>();

  update() async {
    var val = formKey.currentState?.validate();
    if (val != null && val) {

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('userId',userId);
      String userEmail = widget.email;
      String userName = usernameEditingController.text;
      String userIntro = userintroEditingController.text;
      databaseMethods.saveUserDataToFirebaseDatabase(
          userEmail, userId, userName, userIntro, _userImageUrl);
      //databaseMethods.addUserInfo(userDataMap);
      uploadFile();

      HelperFunctions.saveUserLoggedInSharedPreference(true);
      HelperFunctions.saveUserNameSharedPreference(
          usernameEditingController.text);
      Constants.myName = await HelperFunctions.getUserNameSharedPreference();
      Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (context) => ChatRoom()
      ));
    }
  }

  @override
  Widget build(BuildContext context) {

    return Container(
      color: Colors.blue,
      width: MediaQuery.of(context).size.width,
      height: 650,
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //Spacer(),
          Form(
            key: formKey,
            child: Column(
              children: <Widget>[
                Center(
                  child: GestureDetector(
                    onTap: () {
                      _showPicker(context);
                    },
                    child: CircleAvatar(
                        radius: 95,
                        child: _userImageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.file(
                                  _userImageFile,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.fitHeight,
                                ),
                              )

                            : ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: Image.network(
                                  image,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.fitHeight,
                                ),
                              )),
                  ),
                ),
                SizedBox(
                  height: 80,
                ),
                TextFormField(
                  style: simpleTextStyle(),
                  controller: usernameEditingController,
                  validator: (val) {
                    return val != null && (val.isEmpty || val.length < 3)
                        ? "Enter Username 3+ characters"
                        : null;
                  },
                  decoration: textFieldInputDecoration("username"),
                ),

                TextFormField(
                  style: simpleTextStyle(),
                  controller: userintroEditingController,
                  validator: (val) {
                    return val != null &&
                            (val.isEmpty || val.length < 3 || val.length > 50)
                        ? "Enter >3 and <50 character"
                        : null;
                  },
                  decoration: textFieldInputDecoration("About me"),
                ),

              ],
            ),
          ),
          SizedBox(
            height: 30,
          ),
          GestureDetector(
            onTap: () {
              update();
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                color: Colors.white
                  ),
              width: MediaQuery.of(context).size.width,
              child: Text(
                "Update",
                style: TextStyle(color: Colors.black, fontSize: 17, ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );

  }

  void _showPicker(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              child: new Wrap(
                children: <Widget>[
                  new ListTile(
                      leading: new Icon(Icons.photo_library),
                      title: new Text('Gallery'),
                      onTap: () {
                        imgFromGallery();
                        Navigator.of(context).pop();
                      }),
                  new ListTile(
                    leading: new Icon(Icons.photo_camera),
                    title: new Text('Camera'),
                    onTap: () {
                      imgFromCamera();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }
}

