import 'package:admin_panel/core/theme/app_theme.dart';
import 'package:admin_panel/features/sheel_screen.dart';
import 'package:admin_panel/screens/main/home.dart';
import 'package:admin_panel/screens/login.dart';
import 'package:admin_panel/services/brain.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/bootom_bar.dart';
import 'constraints/constants.dart';
import 'features/analytics/provider.dart';
import 'features/analytics/service.dart';
import 'features/dashboard/provider.dart';
import 'features/dashboard/service.dart';
import 'features/transaction/provider.dart';
import 'features/transaction/service.dart';
import 'features/users/provider.dart';
import 'features/users/service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}



class _MyAppState extends State<MyApp> {

  bool isSetUpDone = false;
  bool _isLoading = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _finish();
  }

  Future<void> _finish () async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        isSetUpDone  = prefs.getBool('isSetupDone') ?? false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          backgroundColor: Color(0xFF0F172A),
          body: Center(
            child: CircularProgressIndicator(
              value: 20,
              backgroundColor: kCardColor,
              color: kButtonColor,
            ),
          ),
        ),
      );
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => Brain()),
        // ChangeNotifierProvider(create: (_) => AuthProvider(AuthService(FirebaseAuth.instance))),
        ChangeNotifierProvider(create: (_) => DashboardProvider(DashboardService())..load()),
        ChangeNotifierProvider(create: (_) => UsersProvider(UsersService())),
        ChangeNotifierProvider(create: (_) => TransactionsProvider(TransactionsService())),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider(AnalyticsService())),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // theme: ThemeData(
        //   scaffoldBackgroundColor: Color(0xFF0F172A),
        //   inputDecorationTheme: InputDecorationTheme(
        //       floatingLabelStyle: TextStyle(
        //           color: Colors.white
        //       ),
        //       labelStyle: TextStyle(
        //         color:  Color(0x8AFFFFFF),
        //         fontSize: 13,
        //       ),
        //       helperStyle: TextStyle(
        //           color: Colors.white
        //       ),
        //       focusedBorder: OutlineInputBorder(
        //           borderSide: BorderSide(
        //               color: kButtonColor
        //           ),
        //           borderRadius: BorderRadius.circular(10)
        //       ),
        //       border: OutlineInputBorder(
        //           borderSide: BorderSide(
        //               color: Colors.white54
        //           ),
        //           borderRadius: BorderRadius.circular(10)
        //       ),
        //       focusColor: Colors.white,
        //       prefixIconColor: Colors.white,
        //       focusedErrorBorder: OutlineInputBorder(
        //           borderSide: BorderSide(
        //               color: Colors.red.shade400
        //           ),
        //           borderRadius: BorderRadius.circular(10)
        //       ),
        //       errorBorder: OutlineInputBorder(
        //           borderSide: BorderSide(
        //               color: Colors.red.shade400
        //           ),
        //           borderRadius: BorderRadius.circular(10)
        //       )
        //   ),
        //   textTheme: TextTheme(
        //     bodyMedium: TextStyle(color: Colors.white,),
        //
        //   ),
        //   iconTheme: IconThemeData(
        //     // color: Color(0xFF21D3ED)
        //       color: Colors.white
        //   ),
        //   buttonTheme: ButtonThemeData(
        //     buttonColor: Color(0xFF21D3ED),
        //   ),
        //   appBarTheme: AppBarTheme(
        //     backgroundColor: Color(0xFF177E85),
        //     titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
        //     iconTheme: IconThemeData(
        //       color: Colors.white,
        //     ),
        //   ),
        //   bottomSheetTheme: BottomSheetThemeData(
        //     showDragHandle: true,
        //     dragHandleSize: Size(70, 5),
        //     backgroundColor: Color(0xFF0F172A),
        //     dragHandleColor: Colors.white,
        //   ),
        //   elevatedButtonTheme: ElevatedButtonThemeData(
        //     style: ElevatedButton.styleFrom(
        //         side: BorderSide(
        //             color: kButtonColor
        //         ),
        //         shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(12)
        //         ),
        //         textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold)
        //     ),
        //   ),
        // ),
        theme: AppTheme.dark,
        home: isSetUpDone ? ShellScreen() : SignUpScreen(),
      ),
    );
  }
}
