import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'verify_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;
  final _pageController = PageController();

  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _usernameAvailable = true;
  bool _usernameChecked = false;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep = step);
  }

  Future<void> _checkUsername() async {
    final u = _usernameController.text.trim();
    if (u.length < 3) return;
    final res = await ApiService.checkUsername(u);
    if (mounted) {
      setState(() {
        _usernameAvailable = res['available'] == true;
        _usernameChecked = true;
      });
    }
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Некорректный email')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.resendCode(email: email, type: 'registration');
      if (res['success'] == true && mounted) {
        _goToStep(1);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? 'Ошибка')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode(String code) async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.verifyEmail(
        email: _emailController.text.trim(),
        code: code,
      );
      if (res['success'] == true && mounted) {
        _goToStep(2);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? 'Ошибка')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _goToUsername() async {
    if (_firstNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите имя')),
      );
      return;
    }
    _goToStep(3);
  }

  Future<void> _goToPassword() async {
    final u = _usernameController.text.trim();
    if (u.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username минимум 3 символа')),
      );
      return;
    }
    if (!_usernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Этот username занят')),
      );
      return;
    }
    _goToStep(4);
  }

  Future<void> _register() async {
    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пароль минимум 8 символов')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final res = await ApiService.register(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (res['success'] == true && mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? 'Ошибка регистрации')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: List.generate(5, (index) {
                final isActive = index == _currentStep;
                final isDone = index < _currentStep;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: isDone
                          ? const Color(0xFF075E54)
                          : isActive
                              ? const Color(0xFF075E54).withOpacity(0.5)
                              : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Text(
            'Шаг ${_currentStep + 1} из 5',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildEmailStep(),
                _buildVerifyStep(),
                _buildNameStep(),
                _buildUsernameStep(),
                _buildPasswordStep(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.email_outlined, size: 64, color: Color(0xFF075E54)),
          const SizedBox(height: 24),
          const Text(
            'Введите ваш email',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'На него будет отправлен код подтверждения',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : _sendCode,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size.fromHeight(50),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Далее', style: TextStyle(fontSize: 16)),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: const Text('Уже есть аккаунт? Войти'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyStep() {
    return VerifyScreen(
      email: _emailController.text.trim(),
      type: 'registration',
      onVerified: (code) => _verifyCode(code),
      onBack: () => _goToStep(0),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.person_outline, size: 64, color: Color(0xFF075E54)),
          const SizedBox(height: 24),
          const Text(
            'Как вас зовут?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _firstNameController,
            decoration: const InputDecoration(
              labelText: 'Имя *',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lastNameController,
            decoration: const InputDecoration(
              labelText: 'Фамилия',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _goToUsername,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Далее', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.alternate_email, size: 64, color: Color(0xFF075E54)),
          const SizedBox(height: 24),
          const Text(
            'Придумайте username',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Его смогут найти ваши друзья',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _usernameController,
            onChanged: (_) {
              setState(() => _usernameChecked = false);
            },
            decoration: InputDecoration(
              labelText: 'Username',
              prefixText: '@',
              border: const OutlineInputBorder(),
              errorText: _usernameChecked && !_usernameAvailable
                  ? 'Этот username занят'
                  : null,
              suffixIcon: _usernameController.text.length >= 3
                  ? IconButton(
                      icon: Icon(
                        _usernameAvailable
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: _usernameAvailable ? Colors.green : Colors.red,
                      ),
                      onPressed: _checkUsername,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _goToPassword,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Далее', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.lock_outline, size: 64, color: Color(0xFF075E54)),
          const SizedBox(height: 24),
          const Text(
            'Создайте пароль',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Пароль',
              border: OutlineInputBorder(),
              helperText: 'Минимум 8 символов',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : _register,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              minimumSize: const Size.fromHeight(50),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Зарегистрироваться',
                    style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}