import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Brain extends ChangeNotifier {


  List<Map<String, dynamic>> _transactions = [];

  List<Map<String, dynamic>> get transactions => _transactions;

  StreamSubscription<DocumentSnapshot>? _transactionsSubscription;

  StreamSubscription<DocumentSnapshot>? _userDataSubscription;


  Future<bool> canAuthenticate() async {
    final LocalAuthentication auth = LocalAuthentication();
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await auth.isDeviceSupported();
    return canAuthenticate;
  }
  String passCode = '';
  String userName = '';
  String accountBalance = '0';
  String totalAccountBalance = '0';
  String phoneNumber = '';
  String accountReward = '0';

  double totalMonthlySpent = 0;

  double  airtimePercent = 0;
  double dataPercent = 0;
  double  cablePercent = 0;
  double  electricPercent = 0;
  double  waecPercent = 0;
  double  jambPercent = 0;
  double fundingFees = 0;
  double  rCPersonalPercent = 0;
  double  rCBusinessPercent = 0;
  double  internetPercent = 0;

  Map<String, bool> cableProviders = {};
  Map<String, bool> electricProviders = {};
  Map<String, bool> dataProviders = {};
  Map<String, bool> airtimeProviders = {};

  Map accountData = {};
  List<dynamic> availableJambServices = [];
  List<dynamic> availableWaecRegistration = [];
  List<dynamic> availableWaecPin = [];
  String pIN = '';
  String imagePath = '';
  bool _isLoading = true;

  String get localPasscode => passCode;
  String get localPIN => pIN;
  bool get isLoading => _isLoading;
  String get image => imagePath;
  String get user => userName;
  Map get userAccount => accountData;

  Future<String?> getIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  String baseURL = "https://everywhere-data-app.onrender.com";

}