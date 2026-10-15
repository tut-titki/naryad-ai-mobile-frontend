import '../../master/widgets/master_ui.dart';
import 'package:flutter/material.dart';
import '../data/auth_session.dart';
import '../widgets/auth_scope.dart';
import 'package:mineral/l10n/app_localizations.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  bool _busy = false;
  bool _hideCurrent = true;
  bool _hideNew = true;
  String? _currentError;
  String? _newError;
  String? _error;
  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final session = AuthScope.maybeOf(context);
    if (session == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await session.changePassword(_current.text, _new.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).passwordChanged)),
      );
      Navigator.pop(context);
    } on ApiException catch (error) {
      if (!mounted) return;
      final s = AppLocalizations.of(context);
      setState(() {
        if (error.status == 400) {
          _newError = error.fieldMessage('newPassword');
          _currentError = error.fieldMessage('currentPassword');
          if (_newError == null && _currentError == null) {
            _currentError = error.message.isEmpty
                ? s.enterPassword
                : error.message;
          }
        } else {
          _error = error.message.isEmpty ? s.authNetworkError : error.message;
        }
      });
      _form.currentState!.validate();
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
    final s = AppLocalizations.of(context);
    return PopScope(
      canPop: !_busy,
      child: MasterScaffold(
        enabled: AuthScope.maybeOf(context)?.user?.role == 'MASTER',
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: Text(s.changePasswordTitle)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _current,
                  enabled: !_busy,
                  obscureText: _hideCurrent,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: s.currentPasswordLabel,
                    suffixIcon: IconButton(
                      tooltip: _hideCurrent ? s.showPassword : s.hidePassword,
                      onPressed: () =>
                          setState(() => _hideCurrent = !_hideCurrent),
                      icon: Icon(
                        _hideCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() => _currentError = null),
                  validator: (v) =>
                      _currentError ??
                      (v == null || v.isEmpty ? s.enterPassword : null),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _new,
                  enabled: !_busy,
                  obscureText: _hideNew,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onFieldSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    labelText: s.newPasswordLabel,
                    suffixIcon: IconButton(
                      tooltip: _hideNew ? s.showPassword : s.hidePassword,
                      onPressed: () => setState(() => _hideNew = !_hideNew),
                      icon: Icon(
                        _hideNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() => _newError = null),
                  validator: (v) =>
                      _newError ??
                      ((v?.length ?? 0) < 6 || (v?.length ?? 0) > 128
                          ? s.newPasswordLength
                          : null),
                ),
                const SizedBox(height: 16),
                Text(
                  s.passwordResetHint,
                  style: const TextStyle(color: Color(0xFF7A8597)),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  child: _busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(s.changePasswordButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
