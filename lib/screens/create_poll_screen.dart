// lib/screens/create_poll_screen.dart
import 'package:flutter/material.dart';

class CreatePollScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const CreatePollScreen({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<CreatePollScreen> createState() => _CreatePollScreenState();
}

class _CreatePollScreenState extends State<CreatePollScreen> {
  final TextEditingController _questionController = TextEditingController();
  List<TextEditingController> _optionControllers = [TextEditingController(), TextEditingController()];
  bool _isQuiz = false;
  int? _correctOptionIndex; // null если не викторина или не выбран

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) { // Минимум 2 опции
      setState(() {
        _optionControllers.removeAt(index);
        if (_correctOptionIndex != null && _correctOptionIndex! > index) {
            _correctOptionIndex = _correctOptionIndex! - 1;
        } else if (_correctOptionIndex != null && _correctOptionIndex == index) {
            _correctOptionIndex = null; // Сбросить, если удалена выбранная
        }
      });
    }
  }

  void _submit() {
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .where((option) => option.isNotEmpty)
        .toList();

    if (question.isEmpty || options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите вопрос и минимум 2 варианта ответа.')),
        backgroundColor: Colors.red,
      );
      return;
    }

    if (_isQuiz && _correctOptionIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите правильный ответ для викторины.')),
        backgroundColor: Colors.red,
      );
      return;
    }

    widget.onSubmit({
      'question': question,
      'options': options,
      'isQuiz': _isQuiz,
      'correctOptionId': _isQuiz ? _correctOptionIndex : null, // ID опции (index)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создать опрос'),
        actions: [
          TextButton(
            onPressed: _submit,
            child: const Text('Готово', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Вопрос',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Это викторина'),
              value: _isQuiz,
              onChanged: (value) {
                setState(() {
                  _isQuiz = value;
                  if (!value) _correctOptionIndex = null; // Сбросить выбор правильного ответа
                });
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _optionControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Flexible(
                          child: TextField(
                            controller: _optionControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Вариант ${index + 1}',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => _removeOption(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_isQuiz)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: DropdownButtonFormField<int>(
                  value: _correctOptionIndex,
                  hint: const Text('Выберите правильный ответ'),
                  onChanged: (value) {
                    setState(() {
                      _correctOptionIndex = value;
                    });
                  },
                  items: _optionControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    TextEditingController controller = entry.value;
                    return DropdownMenuItem(
                      value: index,
                      child: Text(controller.text.isEmpty ? 'Вариант ${index + 1}' : controller.text),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add),
              label: const Text('Добавить вариант'),
            ),
          ],
        ),
      ),
    );
  }
}