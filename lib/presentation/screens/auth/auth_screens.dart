import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/validators.dart';
import '../../providers/state_providers.dart';
import '../../widgets/brand/qmax_logo.dart';
import '../../widgets/common/qmax_common.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).login(_id.text, _password.text);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      context.showSnack(ref.read(authProvider).error ?? context.l10n.loginFailed, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final loading = ref.watch(authProvider).isLoading;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: AppSpacing.lg),
          children: [
            const QmaxLogo(size: 72),
            const SizedBox(height: 20),
            Text(l10n.loginTitle, style: context.texts.headlineSmall),
            Text(l10n.welcomeBack, style: context.texts.bodyMedium),
            const SizedBox(height: 24),
            Form(
              key: _form,
              child: Column(
                children: [
                  QmaxTextField(
                    label: l10n.phoneOrEmail,
                    controller: _id,
                    prefixIcon: Icons.person_outline,
                    validator: (v) => Validators.phoneOrEmail(v, l10n),
                  ),
                  const SizedBox(height: 12),
                  QmaxTextField(
                    label: l10n.password,
                    controller: _password,
                    obscure: _obscure,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) => Validators.password(v, l10n),
                    suffix: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => context.push('/forgot-password'), child: Text(l10n.forgotPassword)),
            ),
            QmaxButton(label: l10n.login, loading: loading, onPressed: _login),
            const SizedBox(height: 12),
            QmaxButton(
              label: l10n.continueAsGuest,
              outlined: true,
              onPressed: () => context.go('/home'),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.dontHaveAccount),
                TextButton(onPressed: () => context.push('/register'), child: Text(l10n.register)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final ok = await ref.read(authProvider.notifier).register(
          name: _name.text,
          phone: _phone.text,
          email: _email.text,
          password: _password.text,
        );
    if (!mounted) return;
    if (ok) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.register)),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: context.pagePadding, vertical: AppSpacing.lg),
        children: [
          Text(l10n.createYourAccount, style: context.texts.headlineSmall),
          const SizedBox(height: 20),
          Form(
            key: _form,
            child: Column(
              children: [
                QmaxTextField(label: l10n.fullName, controller: _name, prefixIcon: Icons.badge_outlined, validator: (v) => Validators.requiredField(v, l10n)),
                const SizedBox(height: 12),
                QmaxTextField(label: l10n.phoneNumber, controller: _phone, keyboardType: TextInputType.phone, prefixIcon: Icons.phone_outlined, validator: (v) => Validators.phone(v, l10n)),
                const SizedBox(height: 12),
                QmaxTextField(label: l10n.email, controller: _email, keyboardType: TextInputType.emailAddress, prefixIcon: Icons.email_outlined, validator: (v) => Validators.email(v, l10n)),
                const SizedBox(height: 12),
                QmaxTextField(label: l10n.password, controller: _password, obscure: true, prefixIcon: Icons.lock_outline, validator: (v) => Validators.password(v, l10n)),
                const SizedBox(height: 12),
                QmaxTextField(label: l10n.confirmPassword, controller: _confirm, obscure: true, prefixIcon: Icons.lock_outline, validator: (v) => Validators.confirmPassword(v, _password.text, l10n)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          QmaxButton(label: l10n.register, loading: ref.watch(authProvider).isLoading, onPressed: _submit),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.alreadyHaveAccount),
              TextButton(onPressed: () => context.go('/login'), child: Text(l10n.login)),
            ],
          ),
        ],
      ),
    );
  }
}

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _step = 0;
  final _id = TextEditingController();
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _form = GlobalKey<FormState>();

  @override
  void dispose() {
    _id.dispose();
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_form.currentState!.validate()) return;
    if (_step == 0) {
      await ref.read(authProvider.notifier).sendOtp(_id.text);
      setState(() => _step = 1);
    } else if (_step == 1) {
      final ok = await ref.read(authProvider.notifier).verifyOtp(_id.text, _otp.text);
      if (ok) {
        setState(() => _step = 2);
      } else if (mounted) {
        context.showSnack(context.l10n.pleaseTryAgain, error: true);
      }
    } else {
      final ok = await ref.read(authProvider.notifier).resetPassword(_id.text, _password.text);
      if (!mounted) return;
      if (ok) {
        context.showSnack(context.l10n.passwordResetSuccess);
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.forgotPassword)),
      body: Padding(
        padding: EdgeInsets.all(context.pagePadding),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.forgotPasswordHint),
              const SizedBox(height: 20),
              if (_step == 0)
                QmaxTextField(label: l10n.phoneOrEmail, controller: _id, validator: (v) => Validators.phoneOrEmail(v, l10n)),
              if (_step == 1)
                QmaxTextField(label: '${l10n.otp} (123456)', controller: _otp, keyboardType: TextInputType.number, validator: (v) => Validators.otp(v, l10n)),
              if (_step == 2) ...[
                QmaxTextField(label: l10n.newPassword, controller: _password, obscure: true, validator: (v) => Validators.password(v, l10n)),
                const SizedBox(height: 12),
                QmaxTextField(label: l10n.confirmPassword, controller: _confirm, obscure: true, validator: (v) => Validators.confirmPassword(v, _password.text, l10n)),
              ],
              const Spacer(),
              QmaxButton(
                label: _step == 0 ? l10n.sendOtp : _step == 1 ? l10n.verifyOtp : l10n.resetPassword,
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
