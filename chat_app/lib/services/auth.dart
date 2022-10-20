import 'package:chat_app/helper/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helper/helperfunctions.dart';
import '../modals/user.dart';
import '../views/chat.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Myuser? _userFromFirebaseUser(User user) {
    return user != null ? Myuser(uid: user.uid) : null;
  }

  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user!);
    } catch (e) {
      print(e.toString());
      Constants.error = e.toString();
      return null;
    }
  }

  Future signUpWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user!);
    } catch (e) {
      Constants.error = e.toString();
      return null;
    }
  }

  Future resetPass(String email) async {
    try {
      return await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    final GoogleSignIn _googleSignIn = new GoogleSignIn();

    final GoogleSignInAccount? googleSignInAccount =
    await _googleSignIn.signIn();
    final GoogleSignInAuthentication? googleSignInAuthentication =
    await googleSignInAccount?.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication?.idToken,
        accessToken: googleSignInAuthentication?.accessToken);

    UserCredential result = await _auth.signInWithCredential(credential);
    User? userDetails = result.user;

    if (result == null) {

    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => Chat(chatRoomId: '',)));
    }
  }

  Future signOut() async {
    try {
      HelperFunctions.saveUserLoggedInSharedPreference(false);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString('userId', 'no');
      //await prefs.clear();
      print("prefs: " + prefs.toString());
      print("prefs" + prefs.get('userId'));
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }
}