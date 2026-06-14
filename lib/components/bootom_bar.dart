
import 'package:admin_panel/features/analytics/screen.dart';
import 'package:admin_panel/features/dashboard/screen.dart';
import 'package:admin_panel/features/users/users_screen.dart';
import 'package:admin_panel/screens/main/market_place.dart';
import 'package:admin_panel/screens/main/support_chat.dart';

import 'package:admin_panel/screens/notification.dart';
import 'package:admin_panel/screens/user_data.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/transaction/screen.dart';
import '../screens/main/home.dart';


class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {

  final PageController _pageController = PageController();

  int selectedIndex = 0;
  final List<Widget> screens = [
    const DashboardScreen(),
    const UsersScreen(),
    const TransactionsScreen(),
    const AnalyticsScreen()
  ];

  void _onPageChange(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void _onItemTapped(int indexSelected) {
    _pageController.jumpToPage(indexSelected);
  }

  Color selectedColor = Color(0xFF6F7E90);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:  PageView(
        controller: _pageController,
        onPageChanged: _onPageChange,
        children: screens,
      ),
      bottomNavigationBar: _bottomNavigationBar(),
    );
  }

  CurvedNavigationBar _bottomNavigationBar () {
    return CurvedNavigationBar(
        color: Color(0xFF334155),
        backgroundColor: Colors.transparent,
        // backgroundColor: Color(0xFF0F172A),
        animationCurve: Curves.decelerate,
        height: 55,
        index: selectedIndex,
        onTap: _onItemTapped,
        items:
        [
          Container(
            margin: EdgeInsets.only(bottom: selectedIndex == 0 ? 0 : 25),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(FontAwesomeIcons.house,
                    size: selectedIndex == 0 ? 15 : 20,
                    color: selectedIndex == 0 ? Color(0xFF21D3ED) :
                    Colors.white38,),
                  Visibility(
                    visible: selectedIndex == 0,
                      child: Text('Home', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900),)
                  )
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: selectedIndex == 1 ? 0 : 25),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(FontAwesomeIcons.users,
                    size: selectedIndex == 1 ? 15 : 20, color: selectedIndex == 1 ? Color(0xFF21D3ED) :
                    Colors.white38,),
                  Visibility(
                      visible: selectedIndex == 1,
                      child: Text('Users', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900),)
                  )
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: selectedIndex == 2 ? 0 : 25),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(FontAwesomeIcons.database,
                    size: selectedIndex == 2 ? 15 : 20, color: selectedIndex == 2 ? Color(0xFF21D3ED) :
                      Colors.white38),
                  Visibility(
                      visible: selectedIndex == 2,
                      child: Text('Data', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900),)
                  )
                ],
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: selectedIndex == 3 ? 0 : 25),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.notification_add,
                    size: selectedIndex == 3 ? 20 : 25, color: selectedIndex == 3 ? Color(0xFF21D3ED) :
                      Colors.white38),
                  Visibility(
                      visible: selectedIndex == 3,
                      child: Text('Note', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900),)
                  )
                ],
              ),
            ),
          ),
        ]
    );
  }
}