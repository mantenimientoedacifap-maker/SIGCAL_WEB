import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../data/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final supabaseInfo = SupabaseConfig.runtimeInfo;
    final canLogin = supabaseInfo.isReady;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.institutionalBlue, Color(0xFF1E3A8A)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Card(
                elevation: 0,
                color: AppColors.white,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final useColumns = constraints.maxWidth >= 820;

                    final form = Padding(
                      padding: const EdgeInsets.all(32),
                      child: _LoginForm(
                        formKey: _formKey,
                        obscurePassword: _obscurePassword,
                        isLoading: _isLoading,
                        canLogin: canLogin,
                        errorMessage: _errorMessage,
                        supabaseMessage: supabaseInfo.message,
                        onTogglePassword: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        onSubmit: _submit,
                        onForgotPassword: _showForgotPasswordDialog,
                      ),
                    );

                    if (!useColumns) {
                      return Column(children: [const _LoginHero(), form]);
                    }

                    return Row(
                      children: [
                        const Expanded(flex: 5, child: _LoginHero()),
                        Expanded(flex: 4, child: form),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;

    if (formState == null || !formState.saveAndValidate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final values = formState.value;
    final repository = ref.read(authRepositoryProvider);

    try {
      await repository.signInWithPassword(
        email: values['email'] as String,
        password: values['password'] as String,
      );

      if (!mounted) {
        return;
      }

      context.go(AppRoutes.dashboard);
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = _mapLoginError(error.message);
      });
    } on Object catch (error) {
      setState(() {
        _errorMessage = _mapLoginError(error.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _mapLoginError(String error) {
    final lower = error.toLowerCase();

    if (lower.contains('invalid login') || lower.contains('invalid credentials')) {
      return 'Correo o contrasena incorrectos.';
    }

    if (lower.contains('email not confirmed')) {
      return 'Debes confirmar tu correo electronico antes de iniciar sesion.';
    }

    if (lower.contains('rate') || lower.contains('limit')) {
      return 'Demasiados intentos fallidos. Espera unos segundos.';
    }

    return error;
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    var sending = false;
    String? feedbackMessage;
    bool feedbackIsError = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Recuperar contrasena'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ingresa tu correo electronico y te enviaremos un '
                      'enlace para restablecer tu contrasena.',
                      style: TextStyle(height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: emailController,
                      enabled: !sending,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Correo electronico',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    if (feedbackMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (feedbackIsError
                                  ? AppColors.danger
                                  : AppColors.success)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          feedbackMessage!,
                          style: TextStyle(
                            color: feedbackIsError
                                ? AppColors.danger
                                : AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      sending ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text(''),
                ),
                FilledButton.icon(
                  onPressed: sending
                      ? null
                      : () async {
                          final email = emailController.text.trim();

                          if (email.isEmpty ||
                              !email.contains('@') ||
                              !email.contains('.')) {
                            setDialogState(() {
                              feedbackMessage =
                                  'Ingresa un correo electronico valido.';
                              feedbackIsError = true;
                            });
                            return;
                          }

                          setDialogState(() {
                            sending = true;
                            feedbackMessage = null;
                          });

                          try {
                            final repository =
                                ref.read(authRepositoryProvider);
                            final redirectUrl =
                                '${Uri.base.origin}/reset-password';
                            await repository.resetPasswordForEmail(
                              email: email,
                              redirectTo: redirectUrl,
                            );

                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              sending = false;
                              feedbackMessage =
                                  'Correo enviado. Revisa tu bandeja de entrada '
                                  'y sigue el enlace para restablecer tu contrasena.';
                              feedbackIsError = false;
                            });
                          } on Exception catch (error) {
                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              sending = false;
                              feedbackMessage =
                                  _mapResetError(error.toString());
                              feedbackIsError = true;
                            });
                          }
                        },
                  icon: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(sending ? 'Enviando...' : 'Enviar enlace'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(emailController.dispose);
  }

  String _mapResetError(String error) {
    final lower = error.toLowerCase();

    if (lower.contains('email') ||
        lower.contains('user') ||
        lower.contains('not found')) {
      return 'No se encontro una cuenta con ese correo. Verifica e intenta de nuevo.';
    }

    if (lower.contains('rate') || lower.contains('limit')) {
      return 'Demasiados intentos. Espera unos minutos y vuelve a intentarlo.';
    }

    return 'No se pudo enviar el correo. Intenta de nuevo.';
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(34),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.horizontal(left: Radius.circular(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.actionBlue,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.precision_manufacturing_outlined,
              color: AppColors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            AppStrings.appName,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.institutionalBlue,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.appFullName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.actionBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Acceso protegido para controlar calibraciones, vencimientos, envios y trazabilidad documental.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.obscurePassword,
    required this.isLoading,
    required this.canLogin,
    required this.supabaseMessage,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onForgotPassword,
    this.errorMessage,
  });

  final GlobalKey<FormBuilderState> formKey;
  final bool obscurePassword;
  final bool isLoading;
  final bool canLogin;
  final String supabaseMessage;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Iniciar sesion',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.institutionalBlue,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ingresa con tu usuario autorizado de Supabase Auth.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          FormBuilderTextField(
            name: 'email',
            enabled: canLogin && !isLoading,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Correo electronico',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(errorText: 'Campo obligatorio'),
              FormBuilderValidators.email(errorText: 'Correo no valido'),
            ]),
          ),
          const SizedBox(height: 16),
          FormBuilderTextField(
            name: 'password',
            enabled: canLogin && !isLoading,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: 'Contrasena',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: FormBuilderValidators.required(
              errorText: 'Campo obligatorio',
            ),
          ),
          const SizedBox(height: 18),
          if (errorMessage != null)
            _InlineMessage(message: errorMessage!, color: AppColors.danger)
          else if (!canLogin)
            _InlineMessage(message: supabaseMessage, color: AppColors.warning),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canLogin && !isLoading ? onSubmit : null,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login_outlined),
              label: Text(isLoading ? 'Validando...' : 'Acceder'),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed:
                  canLogin && !isLoading ? onForgotPassword : null,
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('Olvide mi contrasena'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityPill extends StatelessWidget {
  const _SecurityPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.institutionalBlue,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        message,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
