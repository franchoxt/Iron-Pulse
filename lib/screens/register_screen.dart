import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/neon_button.dart';
import '../widgets/neon_checkbox.dart';
import '../widgets/social_buttons.dart';
import '../widgets/auth_segmented_switch.dart';
import '../widgets/password_strength_indicator.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onNavigateToLogin;
  final ValueChanged<AuthTab>? onTabChanged;

  const RegisterScreen({
    super.key,
    required this.onNavigateToLogin,
    this.onTabChanged,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptTerms = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            isError ? const Color(0xFF2B1417) : const Color(0xFF102534),
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

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_acceptTerms) {
      _showFeedback(
        'Please accept the Terms of Service and Privacy Policy to continue',
        isError: true,
      );
      return;
    }

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      // Direct demo preview of the new home screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const HomeScreen(athleteName: 'Javier'),
        ),
      );
      return;
    }

    if (password.length < 6) {
      _showFeedback(
        'Password must contain at least 6 characters',
        isError: true,
      );
      return;
    }

    if (!SupabaseConfig.isConfigured) {
      _showFeedback(
        'Configura tus credenciales de Supabase en el archivo .env',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.instance.signUpWithEmail(
        email: email,
        password: password,
        fullName: name,
      );

      if (!mounted) return;

      if (response.session == null) {
        _showFeedback(
          'Account created for $name! Check your email ($email) to verify.',
        );
      } else {
        _showFeedback(
          'Welcome to the team, $name! Account activated.',
        );
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            athleteName: name.isNotEmpty ? name : 'Javier',
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

                  // Headline: "Create account,\nAthlete."
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Create account,\n',
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
                    'Start your personalized training journey.',
                    style: AppTypography.style(
                      color: AppColors.textGray,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Field 1: Full Name
                  CustomTextField(
                    label: 'Full Name',
                    hintText: 'Alex Rivera',
                    controller: _nameController,
                    suffixWidget: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Field 2: Email Address
                  CustomTextField(
                    label: 'Email Address',
                    hintText: 'alex.rivera@ironpulse.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    suffixWidget: const Icon(
                      Icons.mail_rounded,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Field 3: Password
                  CustomTextField(
                    label: 'Password',
                    hintText: '••••••••',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    onChanged: (val) {
                      setState(() {});
                    },
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
                  PasswordStrengthIndicator(
                    password: _passwordController.text,
                  ),
                  const SizedBox(height: 20),

                  // Terms and conditions checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: NeonCheckbox(
                          value: _acceptTerms,
                          onChanged: (val) {
                            setState(() {
                              _acceptTerms = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: AppTypography.style(
                              color: const Color(0xFFCBD5E1),
                              fontSize: 12.5,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: AppTypography.style(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: AppTypography.style(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Primary Button: "Sign Up ➔"
                  NeonButton(
                    text: 'Sign Up',
                    icon: Icons.arrow_forward_rounded,
                    isLoading: _isLoading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 26),

                  // Divider: "OR CONTINUE WITH"
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          color: Color(0xFF1E2532),
                          thickness: 1,
                        ),
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
                        child: Divider(
                          color: Color(0xFF1E2532),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Social Buttons: Google & Apple
                  SocialSignUpRow(
                    onGoogleTap: () {
                      _showFeedback('Google sign-up coming soon');
                    },
                    onAppleTap: () {
                      _showFeedback('Apple sign-up coming soon');
                    },
                  ),
                  const SizedBox(height: 28),

                  // Bottom Navigation Link: "Already have an account? Sign In"
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTypography.style(
                            color: AppColors.textGray,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onNavigateToLogin,
                          child: Text(
                            'Sign In',
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
