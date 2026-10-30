import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lemon_ui/lemon_ui.dart';

import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/auth_session.dart';
import 'home_page.dart';

const _kCardRadius = 12.0;
const _kMuted = Color(0xFF8C8C8C);
const _kBorder = Color(0xFFE5E6EB);
const _kTitle = Color(0xFF1D2129);

/// 登录页（已迁 lemon_ui Hyper*，不再依赖 lemon_shadcn）。
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 根级已有 HyperTheme / HyperDeviceDetector（见 main.dart）。
    return const _LoginBody();
  }
}

class _LoginBody extends StatefulWidget {
  const _LoginBody();

  @override
  State<_LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<_LoginBody> {
  final _form = HyperFormController();
  final _authService = AuthService();
  final _codeCtrl = TextEditingController();

  var _rememberMe = true;
  var _captchaLoading = false;
  var _captchaEnabled = true;
  String? _captchaUuid;
  Uint8List? _captchaBytes;
  String? _captchaError;

  /// 按用户名查租户。
  Timer? _tenantDebounce;
  var _tenantLoading = false;
  var _tenantEnabled = false;
  var _tenantLookupGen = 0;
  List<DesktopTenantItem> _tenants = const [];
  String? _selectedTenantId;
  String? _tenantQueryError;

  bool get _showTenantSelect => _tenantEnabled && _tenants.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _refreshCaptcha();
    // 默认账号回填后拉一次租户。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduleTenantLookup('mm');
    });
  }

  @override
  void dispose() {
    _tenantDebounce?.cancel();
    _form.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  /// 先卸掉租户下拉，避免换账号时同名字段未注销又注册。
  void _clearTenantField() {
    _tenantEnabled = false;
    _tenants = const [];
    _selectedTenantId = null;
    _tenantQueryError = null;
  }

  void _scheduleTenantLookup(String? username) {
    _tenantDebounce?.cancel();
    // 作废进行中的查询，避免晚到的结果再次挂上 tenantId。
    final gen = ++_tenantLookupGen;
    final q = username?.trim() ?? '';
    if (q.isEmpty) {
      setState(() {
        _clearTenantField();
        _tenantLoading = false;
      });
      return;
    }
    // 账号一变先拆掉旧 tenantId 字段，再防抖请求。
    setState(_clearTenantField);
    _tenantDebounce = Timer(const Duration(milliseconds: 400), () {
      _lookupTenants(q, gen);
    });
  }

  Future<void> _lookupTenants(String username, int gen) async {
    if (gen != _tenantLookupGen) return;
    setState(() {
      _tenantLoading = true;
      _tenantQueryError = null;
      _clearTenantField();
    });
    final result = await _authService.fetchTenantsByUsername(username);
    if (!mounted || gen != _tenantLookupGen) return;
    final current = (_form.value<String>('username') ?? '').trim();
    // 请求返回时账号已变则丢弃（首屏默认 mm 尚未挂上字段时放行）。
    if (current.isNotEmpty && current != username.trim()) {
      setState(() => _tenantLoading = false);
      return;
    }
    setState(() {
      _tenantLoading = false;
      if (!result.success) {
        _tenantQueryError = result.message;
        _clearTenantField();
        return;
      }
      _tenantEnabled = result.tenantEnabled;
      _tenants = result.voList;
      if (!_tenantEnabled || _tenants.isEmpty) {
        _selectedTenantId = null;
      } else {
        _selectedTenantId = _tenants.first.tenantId;
      }
    });
  }

  Future<void> _refreshCaptcha() async {
    setState(() {
      _captchaLoading = true;
      _captchaError = null;
    });
    final result = await _authService.fetchCaptcha();
    if (!mounted) return;
    setState(() {
      _captchaLoading = false;
      if (!result.success) {
        _captchaError = result.message;
        _captchaBytes = null;
        _captchaUuid = null;
        return;
      }
      _captchaEnabled = result.captchaEnabled;
      _captchaUuid = result.uuid;
      _captchaBytes = result.imageBytes;
      _codeCtrl.clear();
      if (result.captchaEnabled && result.imageBytes == null) {
        _captchaError = '验证码图片为空';
      }
    });
  }

  Future<void> _onLogin() async {
    await _form.submit((values) async {
      final username = (values['username'] as String?)?.trim() ?? '';
      final password = values['password'] as String? ?? '';
      final code = _captchaEnabled
          ? ((values['code'] as String?)?.trim() ?? _codeCtrl.text.trim())
          : '';
      final uuid = _captchaEnabled ? (_captchaUuid?.trim() ?? '') : '';

      final tenantId = _showTenantSelect
          ? ((values['tenantId'] as String?)?.trim() ??
              _selectedTenantId?.trim() ??
              '')
          : ApiConfig.tenantId;

      if (_tenantEnabled && tenantId.isEmpty) {
        if (mounted) {
          showHyperToast(context, content: const Text('请选择租户'));
        }
        return;
      }

      if (_captchaEnabled && uuid.isEmpty) {
        if (mounted) {
          showHyperToast(
            context,
            content: const Text('验证码已失效，请点击图片刷新'),
          );
        }
        await _refreshCaptcha();
        return;
      }

      final result = await _authService.passwordLogin(
        username: username,
        password: password,
        code: code,
        uuid: uuid,
        tenantId: tenantId.isEmpty ? ApiConfig.tenantId : tenantId,
      );

      if (!mounted) return;

      if (result.success) {
        AuthSession.saveFromLogin(result.data);
        showHyperToast(context, content: Text(result.message));
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(loginData: result.data)),
        );
        return;
      }

      showHyperToast(
        context,
        content: Text(result.message),
        icon: Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
      );
      await _refreshCaptcha();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LoginBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: HyperCard(
                    style: HyperCardStyle(
                      borderRadius: BorderRadius.circular(_kCardRadius),
                      padding: const EdgeInsets.fromLTRB(36, 32, 36, 36),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: HyperForm(
                      controller: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '媒花易数管理系统',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: _kTitle,
                            ),
                          ),
                          const SizedBox(height: 28),
                          HyperFormField<String>(
                            name: 'username',
                            requiredIndicator: true,
                            initialValue: 'mm',
                            errorHandledByChild: true,
                            validator: (v) =>
                                (v == null || v.trim().isEmpty) ? '请输入账号' : null,
                            fieldBuilder: (field) => HyperTextField(
                              hintText: '账号',
                              initialValue: field.value,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              leading: const Icon(
                                Icons.person_outline,
                                size: 20,
                                color: _kMuted,
                              ),
                              trailing: _tenantLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : null,
                              errorText: field.displayError,
                              onChanged: (v) {
                                field.didChange(v);
                                _scheduleTenantLookup(v);
                              },
                            ),
                          ),
                          if (_showTenantSelect) ...[
                            const SizedBox(height: 14),
                            HyperSelectFormField<String>(
                              name: 'tenantId',
                              requiredIndicator: true,
                              initialValue: _selectedTenantId,
                              placeholder: '请选择租户',
                              options: [
                                for (final t in _tenants)
                                  HyperSelectOption(
                                    value: t.tenantId,
                                    label: t.displayLabel,
                                  ),
                              ],
                              validator: (v) => (v == null || v.isEmpty)
                                  ? '请选择租户'
                                  : null,
                              onChanged: (v) {
                                _selectedTenantId = v;
                              },
                            ),
                          ] else if (_tenantQueryError != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              _tenantQueryError!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFF4D4F),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          HyperFormField<String>(
                            name: 'password',
                            requiredIndicator: true,
                            initialValue: '123456',
                            errorHandledByChild: true,
                            validator: (v) =>
                                (v == null || v.isEmpty) ? '请输入密码' : null,
                            fieldBuilder: (field) => HyperTextField(
                              hintText: '密码',
                              initialValue: field.value,
                              obscureText: true,
                              leading: const Icon(
                                Icons.lock_outline,
                                size: 20,
                                color: _kMuted,
                              ),
                              errorText: field.displayError,
                              onChanged: field.didChange,
                            ),
                          ),
                          if (_captchaEnabled) ...[
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: HyperFormField<String>(
                                    name: 'code',
                                    requiredIndicator: true,
                                    errorHandledByChild: true,
                                    validator: (v) {
                                      final text =
                                          (v ?? _codeCtrl.text).trim();
                                      return text.isEmpty ? '请输入验证码' : null;
                                    },
                                    fieldBuilder: (field) => HyperTextField(
                                      controller: _codeCtrl,
                                      hintText: '验证码',
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _onLogin(),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.deny(
                                          RegExp(r'\s'),
                                        ),
                                      ],
                                      leading: const Icon(
                                        Icons.shield_outlined,
                                        size: 20,
                                        color: _kMuted,
                                      ),
                                      errorText: field.displayError,
                                      onChanged: field.didChange,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _CaptchaImage(
                                  loading: _captchaLoading,
                                  bytes: _captchaBytes,
                                  error: _captchaError,
                                  onTap: _captchaLoading
                                      ? null
                                      : _refreshCaptcha,
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              HyperCheckbox.rounded(
                                value: _rememberMe,
                                semanticLabel: '记住我',
                                onChanged: (v) {
                                  setState(() => _rememberMe = v ?? false);
                                },
                              ),
                              const SizedBox(width: 6),
                              HyperPressable(
                                onTap: () {
                                  setState(() => _rememberMe = !_rememberMe);
                                },
                                builder: (context, states, child) => child!,
                                child: const Text(
                                  '记住我',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4E5969),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          HyperButton.filled(
                            onPressed: _onLogin,
                            label: const Text(
                              '登录',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaptchaImage extends StatelessWidget {
  const _CaptchaImage({
    required this.loading,
    required this.bytes,
    required this.error,
    required this.onTap,
  });

  final bool loading;
  final Uint8List? bytes;
  final String? error;
  final VoidCallback? onTap;

  static const double width = 118;
  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (loading) {
      child = const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else if (bytes != null) {
      child = Image.memory(
        bytes!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else {
      child = Center(
        child: Text(
          error ?? '点击刷新',
          style: const TextStyle(fontSize: 11, color: _kMuted),
          textAlign: TextAlign.center,
        ),
      );
    }

    return HyperPressable(
      onTap: onTap,
      builder: (context, states, _) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE8F3FF),
            Color(0xFFF0F5FF),
            Color(0xFFF7F8FA),
          ],
        ),
      ),
    );
  }
}
