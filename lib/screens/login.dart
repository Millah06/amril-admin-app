import 'dart:io';
import 'package:admin_panel/screens/main/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../components/bootom_bar.dart';
import '../components/flush_bar_message.dart';
import '../components/pin_entry.dart';
import '../constraints/constants.dart';
import '../services/auth.dart';
import '../services/brain.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController _email = TextEditingController();
  TextEditingController _password = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: 50, left: 15, right: 15),
        child: Column(
          children: [
            TextFormField(
              controller: _email,
              style: TextStyle(color: Colors.white),

            ),
            SizedBox(height: 60,),
            TextFormField(
              controller: _password,
              style: TextStyle(color: Colors.white),
            ),
            ElevatedButton(onPressed: () async {

              showDialog(context: context,
                  barrierDismissible: false, builder: (_) => const Dialog(
                    backgroundColor: Colors.blueAccent,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.blueAccent,),
                          SizedBox(width: 16),
                          Text("Updating status..."),
                        ],
                      ),
                    ),
                  ));
              await Authentication().signUp(_email.text, _password.text);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
                child: Text('Sign Up')
            )
          ],
        ),
      ),
    );
  }
}

class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {

  bool obscureText = true;

  void _auth(Future<bool> canAuth) async {
    final LocalAuthentication auth = LocalAuthentication();
    if (await canAuth) {
      final result = await auth.authenticate(
          localizedReason: 'Use Fingerprint to login',
          options: const AuthenticationOptions(biometricOnly: true)
      );
      result ? Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => Home()),
              (route) => false) :
      FlushBarMessage.showFlushBar(
        context: context,
        message: 'Your device does\'nt support this method, use passcode instead.',
        title: 'Ops',
        icon: Icon(Icons.error_outline,
          color: kErrorIconColor, size: 30,),
      );
    }
    else {
      FlushBarMessage.showFlushBar(
        context: context,
        message: 'Your device does\'nt support this method, use passcode instead.',
        title: 'Ops',
        icon: Icon(Icons.error_outline,
          color: kErrorIconColor, size: 30,),
      );
    }
  }

  final TextEditingController _controller = TextEditingController();
  String textDigit = '';

  Color buttonColor = Color(0x3321DEED);
  Color textColor = Colors.white60;

  @override
  Widget build(BuildContext context) {
    final pov = Provider.of<Brain>(context);
    return Scaffold(
      body: Container(
        padding: EdgeInsets.only(top: 50, bottom: 0, left: 0, right: 0),
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 0, left: 15, right: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 30,),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color:  Colors.white,
                            width: 3
                        )
                    ),
                    child: ClipOval(
                        child: Image.asset('images/profile.png', fit: BoxFit.cover,)
                    ),
                  ),
                  SizedBox(height: 20,),
                  Text(pov.user, style: GoogleFonts.inter(fontWeight: FontWeight.w900,
                      fontSize: 18, letterSpacing: 0.5, height: 0),),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black38
                      ),
                      child: TextFormField(
                        controller: _controller,
                        readOnly: true,
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        obscureText: obscureText,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.email_outlined),
                          hintText: 'email',
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscureText = !obscureText;
                                });
                              },
                              icon: Icon(obscureText ? FontAwesomeIcons.eyeSlash :
                              FontAwesomeIcons.eye, size: 18,)
                          ),
                        ),
                        onChanged: (value) {
                          textDigit = value;
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 30,),
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.black38
                      ),
                      child: TextFormField(
                        controller: _controller,
                        readOnly: true,
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        obscureText: obscureText,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.security),
                          hintText: '6-digit PassCode',
                          suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  obscureText = !obscureText;
                                });
                              },
                              icon: Icon(obscureText ? FontAwesomeIcons.eyeSlash :
                              FontAwesomeIcons.eye, size: 18,)
                          ),
                        ),
                        onChanged: (value) {
                          textDigit = value;
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'This field is required';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 15),
              child: GestureDetector(
                onTap: () {},
                child: Text(
                  "Forgot PassCode?",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: kButtonColor,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_controller.text.length == 6) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Center(
                        child: CircularProgressIndicator(
                          value: 20,
                          backgroundColor: kCardColor,
                          color: kButtonColor,
                        ),
                      ),
                    );
                    if (pov.localPasscode != _controller.text) {

                      Navigator.pushAndRemoveUntil(
                        context, MaterialPageRoute(builder: (_) => BottomBar()),
                            (route) => false,);
                    }
                    else {
                      Navigator.pop(context);
                      FlushBarMessage.showFlushBar(
                        context: context,
                        message: 'Incorrect PassCode',
                        title: 'Ops',
                        icon: Icon(Icons.error_outline,
                          color: kErrorIconColor, size: 30,),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                    side: BorderSide.none
                ),
                child: Text('Login Now', style:
                GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w700, fontSize: 18)),
              ),
            ),
            CustomPinKeyboard(
              onKeyTap: (digit ) {
                if (_controller.text.length < 6) {
                  _controller.text += digit;
                }
                if (_controller.text.length == 6) {
                  setState(() {
                    buttonColor = Color(0xFF21D3ED);
                    textColor = Colors.black;
                  });
                }
              },
              onBackspace: () {
                if (_controller.text.isNotEmpty) {
                  _controller.text = _controller.text.substring(0, _controller.text.length - 1);
                  setState(() {
                    buttonColor = Color(0x3321DEED);
                    textColor = Colors.white60;
                  });
                }
              },
              onBiometric: () {
                _auth(pov.canAuthenticate());
              },
            )
          ],
        ),
      ),
    );
  }
}


