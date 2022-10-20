//@dart=2.9
import 'dart:io';

import 'package:chat_app/helper/helperfunctions.dart';
import 'package:chat_app/helper/theme.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/views/chatRoomsScreen.dart';
import 'package:chat_app/widgets/widget.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

import '../helper/constants.dart';

class SignUp extends StatefulWidget {
  final Function toggleView;
  SignUp(this.toggleView);

  @override
  _SignUpState createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {

  FirebaseStorage storage = FirebaseStorage.instance;
  TextEditingController emailEditingController = new TextEditingController();
  TextEditingController passwordEditingController = new TextEditingController();
  TextEditingController usernameEditingController =
  new TextEditingController();
  TextEditingController userintroEditingController = new TextEditingController();
  File _userImageFile ;
  String _userImageUrl = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print(_userImageFile);
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
      final ref = FirebaseStorage.instance
          .ref()
          .child('file/$fileName');
      await ref.putFile(_userImageFile);
    } catch (e) {
      print('error occured');
    }
  }


  AuthService authService = new AuthService();
  DatabaseMethods databaseMethods = new DatabaseMethods();

  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  singUp() async {

    var val = formKey.currentState?.validate();
    if (val != null && val) {
      setState(() {
        isLoading = true;
      });

      await authService.signUpWithEmailAndPassword(emailEditingController.text,
          passwordEditingController.text).then((result){
        if(result != null){

          print("user id: " + result.uid);

          String userEmail = emailEditingController.text;
          String userId = result.uid;
          String userName = usernameEditingController.text;
          String userIntro = userintroEditingController.text;
          databaseMethods.saveUserDataToFirebaseDatabase(userEmail, userId, userName, userIntro, _userImageUrl);
          //databaseMethods.addUserInfo(userDataMap);
          uploadFile();
          HelperFunctions.saveUserLoggedInSharedPreference(true);
          HelperFunctions.saveUserNameSharedPreference(usernameEditingController.text);
          HelperFunctions.saveUserEmailSharedPreference(emailEditingController.text);

          Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (context) => ChatRoom()
          ));
        }
        else{
          setState(() {
            isLoading = false;
          });
          showSnackbar(context, Colors.redAccent, Constants.error);
        }
      });
    }
    else{
      showSnackbar(context, Colors.redAccent, "Invalid values");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: appBarMain(context),
      ),
      body: isLoading ? Container(child: Center(child: CircularProgressIndicator(),),) :  ListView(
        padding: EdgeInsets.symmetric(horizontal: 24),


            children: <Widget>[
              Spacer(),
              SizedBox(
                height: 30,
              ),
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
                          radius: 85,

                          child: _userImageFile != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(80),
                            child: Image.file(
                              _userImageFile,
                              width: 150,
                              height: 150,
                              fit: BoxFit.fitHeight,
                            ),
                          )
                          //     : Container(
                          //   decoration: BoxDecoration(
                          //       color: Colors.grey[200],
                          //       borderRadius: BorderRadius.circular(50)),
                          //   width: 100,
                          //   height: 100,
                          //   child: Icon(
                          //     Icons.camera_alt,
                          //     color: Colors.grey[800],
                          //   ),
                          // ),
                          : ClipRRect(
                            borderRadius: BorderRadius.circular(80),
                            child: Image.network(
                              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT2pVWhgXilxQ894sH6mDq-V-oDhoPLEYWUd7m-fh4f0lZIzzGeLaUEObGOsMouGlRA0XM&usqp=CAU',
                              width: 150,
                              height: 150,
                              fit: BoxFit.fitHeight,
                            ),
                          )
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    TextFormField(
                      style: simpleTextStyle(),
                      controller: usernameEditingController,
                      validator: (val){
                        return val != null && (val.isEmpty || val.length < 3) ? "Enter Username 3+ characters" : null;
                      },
                      decoration: textInputDecoration.copyWith(
                        labelText: "Username",
                        prefixIcon: Icon(
                          Icons.face,
                          color: Color(0xff007EF4),
                        )
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    TextFormField(
                      controller: emailEditingController,
                      style: simpleTextStyle(),
                      validator: (val){
                        return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(val) ?
                        null : "Enter correct email";
                      },
                        decoration: textInputDecoration.copyWith(
                            labelText: "Email",
                            prefixIcon: Icon(
                              Icons.email,
                              color: Color(0xff007EF4),
                            )
                        ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    TextFormField(
                      style: simpleTextStyle(),
                      controller: userintroEditingController,
                      validator: (val){
                        return val != null && (val.isEmpty || val.length < 3 || val.length > 20) ? "Enter >3 and <20 character" : null;
                      },
                      decoration: textInputDecoration.copyWith(
                          labelText: "About me",
                          prefixIcon: Icon(
                            Icons.messenger,
                            color: Color(0xff007EF4),
                          )
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    TextFormField(
                      obscureText: true,
                      style: simpleTextStyle(),
                      decoration: textInputDecoration.copyWith(
                          labelText: "Password",
                          prefixIcon: Icon(
                            Icons.lock,
                            color: Color(0xff007EF4),
                          )
                      ),
                      controller: passwordEditingController,
                      validator:  (val){
                        return val != null && val.length < 6 ? "Enter Password 6+ characters" : null;
                      },

                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 16,
              ),
              GestureDetector(
                onTap: (){
                  singUp();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        colors: [const Color(0xff007EF4), const Color(0xff2A75BC)],
                      )),
                  width: MediaQuery.of(context).size.width,
                  child: Text(
                    "Sign Up",
                    style: biggerTextStyle(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(
                height: 16,
              ),
              Container(
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30), color: Colors.white),
                width: MediaQuery.of(context).size.width,
                child: Text(
                  "Sign Up with Google",
                  style: TextStyle(fontSize: 17, color: CustomTheme.textColor),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(
                height: 16,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: simpleTextStyle(),
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.toggleView();
                    },
                    child: Text(
                      "SignIn now",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 50,
              )
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