import 'package:flutter/material.dart';
import '../widgets/auth_segmented_switch.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class AuthScreen extends StatefulWidget {
  final AuthTab initialTab;

  const AuthScreen({
    super.key,
    this.initialTab = AuthTab.login,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late PageController _pageController;
  late AuthTab _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _pageController = PageController(
      initialPage: widget.initialTab == AuthTab.login ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToTab(AuthTab tab) {
    if (_currentTab == tab) return;
    setState(() {
      _currentTab = tab;
    });
    _pageController.animateToPage(
      tab == AuthTab.login ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (pageIndex) {
          setState(() {
            _currentTab = pageIndex == 0 ? AuthTab.login : AuthTab.register;
          });
        },
        children: [
          LoginScreen(
            onNavigateToRegister: () => _goToTab(AuthTab.register),
            onTabChanged: _goToTab,
          ),
          RegisterScreen(
            onNavigateToLogin: () => _goToTab(AuthTab.login),
            onTabChanged: _goToTab,
          ),
        ],
      ),
    );
  }
}
