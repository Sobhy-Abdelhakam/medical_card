import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../di/injection_container.dart';
import '../../../app/presentation/pages/main_app_shell.dart';
import '../cubit/auth/auth_cubit.dart';
import '../cubit/auth/auth_state.dart';

/// Login page for membership-based authentication
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _membershipController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _membershipController.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext blocContext) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final membershipNumber = _membershipController.text.trim().toUpperCase();
    blocContext.read<AuthCubit>().login(membershipNumber);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: Builder(
        builder: (blocContext) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is AuthAuthenticated) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainAppShell()),
                    );
                  } else if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    setState(() => _isLoading = false);
                  } else if (state is AuthLoading) {
                    setState(() => _isLoading = true);
                  }
                },
                builder: (context, state) {
                  return SingleChildScrollView(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 60.h),
                          // App Logo
                          Center(
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              width: 120.w,
                              height: 120.w,
                            ),
                          ),
                          SizedBox(height: 40.h),
                          // Title
                          Text(
                            'Member Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Subtitle
                          Text(
                            'Enter your membership number to continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 48.h),
                          // Membership Number Field
                          TextFormField(
                            controller: _membershipController,
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.done,
                            enabled: !_isLoading,
                            decoration: InputDecoration(
                              labelText: 'Membership Number',
                              hintText: 'Enter membership number',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your membership number';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _handleLogin(blocContext),
                          ),
                          SizedBox(height: 32.h),
                          // Continue Button
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _handleLogin(blocContext),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Continue',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

