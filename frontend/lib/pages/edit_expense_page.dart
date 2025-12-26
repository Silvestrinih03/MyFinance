import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/input_formatters.dart';

class EditExpensePage extends StatefulWidget {
  const EditExpensePage({super.key});

  @override
  State<EditExpensePage> createState() => _EditExpensePageState();
}

class _EditExpensePageState extends State<EditExpensePage> {
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dueDateController = TextEditingController();
  final _recurrenceEndController = TextEditingController();

  DateTime? _dueDate;
  DateTime? _recurrenceEndDate;

  bool _isRecurring = false;

  int? _expenseId;
  int? _selectedMonth;
  int? _selectedYear;

  String _baseUrl = '';
  String _updateExpenseUrl = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        _expenseId = args['id'];
        _selectedMonth = args['month'];
        _selectedYear = args['year'];
      }

      _setupApi();
    });
  }

  Future<bool> _isRunningOnEmulator() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      return !(await deviceInfo.androidInfo).isPhysicalDevice;
    }
    if (Platform.isIOS) {
      return !(await deviceInfo.iosInfo).isPhysicalDevice;
    }
    return false;
  }

  Future<void> _setupApi() async {
    final isEmulator = await _isRunningOnEmulator();
    _baseUrl = isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';

    _updateExpenseUrl = '$_baseUrl/expenses';

    await _loadExpense();
  }

  Future<void> _loadExpense() async {
    if (_expenseId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/expense/$_expenseId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body);

      setState(() {
        _descriptionController.text = data['description'] ?? '';

        final amount = data['amount'];
        _amountController.text = amount != null
            ? NumberFormat.currency(
                locale: 'pt_BR',
                symbol: 'R\$ ',
              ).format(amount)
            : '';

        _dueDate = DateTime.tryParse(data['due_date'] ?? '');
        _dueDateController.text =
            _dueDate != null ? _formatDate(_dueDate!) : '';

        _isRecurring = data['is_recurring'] ?? false;

        if (data['recurrence_end_date'] != null) {
          _recurrenceEndDate = DateTime.tryParse(data['recurrence_end_date']);
          _recurrenceEndController.text = _recurrenceEndDate != null
              ? _formatDate(_recurrenceEndDate!)
              : '';
        } else {
          _recurrenceEndDate = null;
          _recurrenceEndController.clear();
        }
      });
    } catch (_) {}
  }

  Future<void> _updateExpense() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      _dueDate = _parseDate(_dueDateController.text);

      if (_isRecurring && _recurrenceEndController.text.isNotEmpty) {
        _recurrenceEndDate = _parseDate(_recurrenceEndController.text);

        if (!_recurrenceEndDate!.isAfter(_dueDate!)) {
          _showMessage('Recurrence end date must be after the due date.');
          return;
        }
      }
    } catch (_) {
      _showMessage('Invalid dates.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || _expenseId == null) return;

    final body = {
      'description': _descriptionController.text,
      'amount': _parseAmount(),
      'due_date': _dueDate!.toIso8601String().split('T')[0],
      'is_recurring': _isRecurring,
      'recurrence_end_date': _recurrenceEndDate != null
          ? _recurrenceEndDate!.toIso8601String().split('T')[0]
          : null,
    };

    try {
      final response = await http.put(
        Uri.parse('$_updateExpenseUrl/$_expenseId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _showMessage('Expense updated successfully');
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showMessage('Error reflects: ${response.body}');
      }
    } catch (e) {
      _showMessage('Connection error: $e');
    }
  }

  DateTime _parseDate(String value) =>
      DateFormat('dd/MM/yyyy').parseStrict(value);

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  double _parseAmount() {
    return double.tryParse(
          _amountController.text
              .replaceAll(RegExp(r'[^\d,]'), '')
              .replaceAll(',', '.'),
        ) ??
        0.0;
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      controller.text = _formatDate(date);
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                   UI                                      */
  /* -------------------------------------------------------------------------- */

  Widget _textField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      inputFormatters: formatters,
      validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
    );
  }

  Widget _dateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [DateInputFormatter()],
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _pickDate(controller),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required field';
        try {
          _parseDate(v);
        } catch (_) {
          return 'Invalid date';
        }
        return null;
      },
    );
  }

  Widget _recurrenceSwitch() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Recurring expense'),
            value: _isRecurring,
            onChanged: (v) => setState(() => _isRecurring = v),
          ),
          if (_isRecurring)
            _dateField('Recurrence end (optional)', _recurrenceEndController),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _textField('Description *', _descriptionController),
              const SizedBox(height: 12),
              _dateField('Due date *', _dueDateController),
              const SizedBox(height: 12),
              _textField(
                'Amount *',
                _amountController,
                keyboard: TextInputType.number,
                formatters: [
                  CurrencyInputFormatter(
                    locale: 'pt_BR',
                    symbol: 'R\$ ',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _recurrenceSwitch(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _updateExpense,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
