import 'package:admin_panel/core/network/dio_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:everywhere/services/notification_service.dart';
// import 'package:everywhere/services/purchase_service.dart';
// import 'package:everywhere/services/transaction_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Authentication {
  final _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> userSignIn(String email, String password,) async {
    UserCredential ? result;
    try {
      result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      // await PushNotificationService().saveTokenToFirestore();
      return result.user;
    }
    catch(e) {
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {

    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);

    print(result.user!.uid);

    // print(result);
    //
    // final userId = result.user!.uid;
    //
    //
    // await DioClient.post('/auth/register', data:  {
    //   'name': 'Super Admin',
    //   "email": email,
    //   "password": password
    // });

    // await _firestore.collection('users').doc(userId).set({
    //   'name': 'Super Admin',
    //   'email': email,
    //   'role' : 'superAdmin',
    //
    //   'createdAt': FieldValue.serverTimestamp(),
    // });

    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('isSetupDone', true);
  }
}