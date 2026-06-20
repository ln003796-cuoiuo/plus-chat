import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class VerifyScreen extends StatefulWidget {
  final String email;
  final String type;
  final Function(String code)? onVerified;
  final VoidCallback? onBack;

  const VerifyScreen({
    super.key,
    required this.email,
    required this.type,
    this.onVerified,
    this.onBack,
  });

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  int _resendTimer = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendTimer = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        t.cancel();
      }
    });
  }

  String _getCode() {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _verify() async {
    final code = _getCode();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите все 6 цифр')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.onVerified != null) {
        widget.onVerified!(code);
      } else {
        final res = await ApiService.verifyEmail(
          email: widget.email,
          code: code,
        );
        if (res['success'] == true && mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['error'] ?? 'Ошибка')),
          );
        }
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

  Future<void> _resendCode() async {
    if (_resendTimer > 0) return;
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.resendCode(
        email: widget.email,
        type: widget.type,
      );
      if (res['success'] == true && mounted) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Код отправлен повторно')),
        );
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

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Icon(Icons.email, size: 64, color: Color(0xFF075E54)),
          const SizedBox(height: 24),
          const Text(
            'Введите код из письма',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Код отправлен на ${widget.email}',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // 6 полей для кода
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 44,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      _focusNodes[index + 1].requestFocus();
                    }
                    if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                    if (_getCode().length == 6) {
                      _verify();
                    }
                  },
                ),
              );
            }),
          ),

          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : _verify,
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
                : const Text('Подтвердить', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _resendTimer > 0 || _isLoading ? null : _resendCode,
            child: _resendTimer > 0
                ? Text('Отправить код повторно через $_resendTimer сек')
                : const Text('Отправить код повторно'),
          ),
        ],
      ),
    );
  }
}