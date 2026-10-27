import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iron_pulse/theme/app_theme.dart';
import 'package:iron_pulse/screens/auth_screen.dart';
import 'package:iron_pulse/screens/home_screen.dart';

void main() {
  testWidgets('Smoke test: Verify new LoginScreen and RegisterScreen flow',
      (WidgetTester tester) async {
    // Set screen size for standard mobile testing
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const AuthScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Login screen elements
    expect(find.text('IRON PULSE'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText().contains('Athlete.'),
      ),
      findsOneWidget,
    );
    expect(find.text('Access your training schedule.'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Google'), findsOneWidget);
    expect(find.text('Apple'), findsOneWidget);

    // 2. Navigate to Register by tapping "Sign Up" link
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // 3. Verify Register screen elements
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Sign Up'), findsWidgets); // button & link
    expect(find.text('Already have an account? '), findsOneWidget);

    // 4. Navigate back to Login by tapping "Sign In" link
    await tester.tap(find.text('Sign In').last);
    await tester.pumpAndSettle();

    // Verify back on Login
    expect(find.text('Access your training schedule.'), findsOneWidget);
  });

  testWidgets('Verify HomeScreen renders with athlete greeting and classes',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const HomeScreen(athleteName: 'Javier'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hola, Javier'), findsOneWidget);
    expect(find.text('Ready to crush your goals today?'), findsOneWidget);
    expect(find.text('Featured Classes'), findsOneWidget);
    expect(find.text('CrossFit WOD'), findsOneWidget);
    expect(find.text('Upcoming Classes'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
