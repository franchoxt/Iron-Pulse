import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/neon_button.dart';
import '../widgets/social_buttons.dart';
import '../widgets/auth_segmented_switch.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onNavigateToRegister;
  final ValueChanged<AuthTab>? onTabChanged;

  const LoginScreen({
    super.key,
    required this.onNavigateToRegister,
    this.onTabChanged,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError
            ? const Color(0xFF2B1417)
            : const Color(0xFF102534),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isError ? const Color(0xFFFF4D4D) : AppColors.primaryCyan,
            width: 1.2,
          ),
        ),
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isError ? const Color(0xFFFF4D4D) : AppColors.primaryCyan,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.style(
                  color: AppColors.textWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(athleteName: 'Javier'),
        ),
      );
      return;
    }

    if (!SupabaseConfig.isConfigured) {
      _showFeedback(
        '⚙️ Configura tu URL y Anon Key en el archivo .env para conectar con Supabase',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );

      final userName =
          response.user?.userMetadata?['full_name'] ??
          (email.contains('@') ? email.split('@').first : email);

      if (!mounted) return;
      _showFeedback('Welcome back, $userName!');

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            athleteName: userName.isNotEmpty ? userName : 'Javier',
          ),
        ),
      );
    } on AuthException catch (e) {
      _showFeedback(e.message, isError: true);
    } catch (e) {
      _showFeedback('Error: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text.trim(),
    );
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111620),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Forgot Password?',
                        style: AppTypography.style(
                          color: AppColors.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textGray,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email to receive a secure recovery link.',
                    style: AppTypography.style(
                      color: AppColors.textGray,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  CustomTextField(
                    label: 'Email Address',
                    hintText: 'athlete@ironpulse.com',
                    controller: resetEmailController,
                    suffixWidget: const Icon(
                      Icons.mail_outline_rounded,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 22),
                  NeonButton(
                    text: 'SEND RESET LINK',
                    icon: Icons.send_rounded,
                    isLoading: isSending,
                    onPressed: () async {
                      final email = resetEmailController.text.trim();
                      if (email.isEmpty) return;

                      if (!SupabaseConfig.isConfigured) {
                        Navigator.pop(context);
                        _showFeedback(
                          'Configura tus credenciales de Supabase en el archivo .env',
                          isError: true,
                        );
                        return;
                      }

                      setModalState(() => isSending = true);
                      try {
                        await AuthService.instance.sendPasswordResetEmail(
                          email: email,
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _showFeedback(
                          'Password reset email sent. Check your inbox.',
                        );
                      } catch (e) {
                        setModalState(() => isSending = false);
                        _showFeedback('Failed to send link: $e', isError: true);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Hero Background Image with Gym Lighting
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Image.asset(
              'assets/images/gym_hero_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Gradient Overlay on Hero Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.5),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.65, 1.0],
                ),
              ),
            ),
          ),

          // 3. Scrollable Foreground Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Brand Header: Logo + "IRON PULSE"
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryCyan,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.fitness_center_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'IRON PULSE',
                        style: AppTypography.style(
                          color: AppColors.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 125),

                  // Headline: "Welcome back,\nAthlete."
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Welcome back,\n',
                          style: AppTypography.style(
                            color: AppColors.textWhite,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            height: 1.15,
                          ),
                        ),
                        TextSpan(
                          text: 'Athlete.',
                          style: AppTypography.style(
                            color: AppColors.primaryCyan,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.8,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Access your training schedule.',
                    style: AppTypography.style(
                      color: AppColors.textGray,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Field 1: Email Address
                  CustomTextField(
                    label: 'Email Address',
                    hintText: 'athlete@ironpulse.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    suffixWidget: const Icon(
                      Icons.mail_rounded,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Field 2: Password
                  CustomTextField(
                    label: 'Password',
                    topRightWidget: GestureDetector(
                      onTap: _showForgotPasswordDialog,
                      child: Text(
                        'Forgot Password?',
                        style: AppTypography.style(
                          color: AppColors.textGray,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    hintText: '••••••••',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    suffixWidget: GestureDetector(
                      onTap: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF6B7280),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Primary Button: "Sign In ➔"
                  NeonButton(
                    text: 'Sign In',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 28),

                  // Divider: "OR CONTINUE WITH"
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: Color(0xFF1E2532), thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'OR CONTINUE WITH',
                          style: AppTypography.style(
                            color: const Color(0xFF5A6678),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: Color(0xFF1E2532), thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Social Buttons: Google & Apple
                  SocialSignUpRow(
                    onGoogleTap: () {
                      _showFeedback('Google sign-in coming soon');
                    },
                    onAppleTap: () {
                      _showFeedback('Apple sign-in coming soon');
                    },
                  ),
                  const SizedBox(height: 32),

                  // Bottom Navigation Link: "Don't have an account? Sign Up"
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTypography.style(
                            color: AppColors.textGray,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onNavigateToRegister,
                          child: Text(
                            'Sign Up',
                            style: AppTypography.style(
                              color: AppColors.primaryCyan,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
