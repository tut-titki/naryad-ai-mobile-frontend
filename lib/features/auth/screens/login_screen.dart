import 'dart:async';
import '../data/auth_session.dart';
import '../widgets/auth_scope.dart';
import 'package:mineral/l10n/app_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mineral/l10n/app_localizations.dart';

import 'package:mineral/features/auth/formatters/phone_input_formatter.dart';
import 'package:mineral/features/auth/widgets/auth_page.dart';

import 'package:mineral/features/auth/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _busy = false;
  bool _submitted = false;
  String? _error;
  String? _phoneError;
  String? _passwordError;
  Timer? _timer;
  AuthSession? _session;
  bool _phoneEdited = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = AuthScope.maybeOf(context);
    if (session != _session) {
      _session = session;
      if (session != null) unawaited(_restorePhone(session));
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _session?.blockedUntil != null) setState(() {});
    });
  }

  bool get _blocked => _session?.blockedUntil?.isAfter(DateTime.now()) ?? false;

  Future<void> _restorePhone(AuthSession session) async {
    final phone = await session.loadLastPhone();
    if (!mounted || _session != session || _phoneEdited || phone == null) {
      return;
    }
    final value = const ApiPhoneInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(
        text: phone,
        selection: TextSelection.collapsed(offset: phone.length),
      ),
    );
    _phone.value = value;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy || _blocked) return;
    setState(() => _submitted = true);
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final session = _session;
    if (session == null) {
      Navigator.of(context).pushNamedAndRemoveUntil('/executor', (_) => false);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _phoneError = null;
      _passwordError = null;
    });
    try {
      final user = await session.login(_phone.text, _password.text);
      if (!mounted) return;
      TextInput.finishAutofillContext();
      appLocale.value = Locale(user.language == 'kk' ? 'kk' : 'ru');
      Navigator.of(context).pushNamedAndRemoveUntil(
        user.mobileRoute!,
        (_) => false,
        arguments: user.id,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      final s = AppLocalizations.of(context);
      setState(() {
        if (error.status == 400) {
          _phoneError = error.fieldMessage('phone');
          if (_phoneError == null) {
            _passwordError = error.message.isEmpty
                ? s.enterPassword
                : error.message;
          }
          _error = null;
        } else {
          _error = switch (error.status) {
            429 => error.retryAfter == null ? s.authRateLimited : null,
            403 => error.message.isEmpty ? s.authMobileRole : error.message,
            _ => error.message.isEmpty ? s.authNetworkError : error.message,
          };
        }
      });
      if (error.status == 400) _formKey.currentState!.validate();
    } catch (_) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).authNetworkError);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = _session != null;
    final s = AppLocalizations.of(context);
    final until = _session?.blockedUntil;
    final blockMessage = _blocked && until != null
        ? s.authRetryMinutes(
            '${(until.difference(DateTime.now()).inSeconds + 59) ~/ 60}',
          )
        : null;
    return AuthPage(
      title: AppLocalizations.of(context).loginTitle,
      subtitle: api ? s.authSubtitle : s.loginSubtitle,
      showLogo: true,
      footer: api
          ? Text(
              s.authAccountHint,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF7A8597)),
            )
          : TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: Text(AppLocalizations.of(context).createAccount),
            ),
      child: AutofillGroup(
        onDisposeAction: AutofillContextAction.cancel,
        child: Form(
          key: _formKey,
          autovalidateMode: _submitted
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _phone,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: api
                    ? const [ApiPhoneInputFormatter()]
                    : const [PhoneInputFormatter()],
                autofillHints: const [
                  AutofillHints.username,
                  AutofillHints.telephoneNumber,
                ],
                decoration: InputDecoration(
                  labelText: s.phoneLabel,
                  hintText: '+7 700 123 45 67',
                ),
                onChanged: (_) {
                  _phoneEdited = true;
                  if (_phoneError != null || _error != null) {
                    setState(() {
                      _phoneError = null;
                      _error = null;
                    });
                  }
                },
                validator: (value) {
                  if (!api) {
                    return validatePhone(
                      value,
                      emptyMessage: s.enterPhone,
                      incompleteMessage: s.incompletePhone,
                    );
                  }
                  if (_phoneError != null) return _phoneError;
                  if (value == null || value.trim().isEmpty) {
                    return s.enterPhone;
                  }
                  final digits = value.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10 || digits.length > 15) {
                    return s.authInvalidPhone;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _password,
                enabled: !_busy,
                obscureText: _hidePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: s.passwordLabel,
                  suffixIcon: IconButton(
                    tooltip: _hidePassword
                        ? AppLocalizations.of(context).showPassword
                        : AppLocalizations.of(context).hidePassword,
                    onPressed: () =>
                        setState(() => _hidePassword = !_hidePassword),
                    icon: Icon(
                      _hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                  ),
                ),
                onChanged: (_) {
                  if (_passwordError != null || _error != null) {
                    setState(() {
                      _passwordError = null;
                      _error = null;
                    });
                  }
                },
                validator: (value) =>
                    _passwordError ??
                    (value == null || value.isEmpty ? s.enterPassword : null),
              ),
              const SizedBox(height: 28),
              if (blockMessage != null || _error != null) ...[
                Text(
                  blockMessage ?? _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: _busy || _blocked ? null : _login,
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(s.loginButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
