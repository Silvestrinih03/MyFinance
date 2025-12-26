import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/input_formatters.dart';

class EditIncomePage extends StatefulWidget {
  const EditIncomePage({super.key});

  @override
  State<EditIncomePage> createState() => _EditIncomePageState();
}

class _EditIncomePageState extends State<EditIncomePage> {
  final _formKey = GlobalKey<FormState>();

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _receivedDateController = TextEditingController();
  final _recurrenceEndController = TextEditingController();

  DateTime? _receivedDate;
  DateTime? _recurrenceEndDate;

  bool _isRecurring = false;

  int? _incomeId;
  int? _selectedMonth;
  int? _selectedYear;

  String _baseUrl = '';
  String _updateIncomeUrl = '';

  /* -------------------------------------------------------------------------- */
  /*                                   LIFECYCLE                                */
  /* -------------------------------------------------------------------------- */

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

      if (args != null) {
        _incomeId = args['id'];
        _selectedMonth = args['month'];
        _selectedYear = args['year'];
      }

      _setupApi();
    });
  }

  /* -------------------------------------------------------------------------- */
  /*                                   API SETUP                                */
  /* -------------------------------------------------------------------------- */

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

    _updateIncomeUrl = '$_baseUrl/incomes';

    await _loadIncome();
  }

  /* -------------------------------------------------------------------------- */
  /*                                 LOAD INCOME                                */
  /* -------------------------------------------------------------------------- */

  Future<void> _loadIncome() async {
    if (_incomeId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getString('userId');

    if (token == null || userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/income/$_incomeId?user_id=$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200) return;

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      setState(() {
        _descriptionController.text = data['description'] ?? '';

        final amount = data['amount'];
        _amountController.text = amount != null
            ? NumberFormat.currency(
                locale: 'pt_BR',
                symbol: 'R\$ ',
              ).format(amount)
            : '';

        _receivedDate = DateTime.tryParse(data['received_date'] ?? '');
        _receivedDateController.text =
            _receivedDate != null ? _formatDate(_receivedDate!) : '';

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

  /* -------------------------------------------------------------------------- */
  /*                                UPDATE INCOME                               */
  /* -------------------------------------------------------------------------- */

  Future<void> _updateIncome() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      _receivedDate = _parseDate(_receivedDateController.text);

      if (_isRecurring && _recurrenceEndController.text.isNotEmpty) {
        _recurrenceEndDate = _parseDate(_recurrenceEndController.text);

        if (!_recurrenceEndDate!.isAfter(_receivedDate!)) {
          _showMessage('Recurrence end date must be after the received date.');
          return;
        }
      }
    } catch (_) {
      _showMessage('Invalid dates.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || _incomeId == null) return;

    final body = {
      'description': _descriptionController.text,
      'amount': _parseAmount(),
      'received_date': _receivedDate!.toIso8601String().split('T')[0],
      'is_recurring': _isRecurring,
      'recurrence_end_date': _recurrenceEndDate != null
          ? _recurrenceEndDate!.toIso8601String().split('T')[0]
          : null,
    };

    try {
      final response = await http.put(
        Uri.parse('$_updateIncomeUrl/$_incomeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        _showMessage('Income updated successfully');
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showMessage('Error: ${response.body}');
      }
    } catch (e) {
      _showMessage('Connection error: $e');
    }
  }

  /* -------------------------------------------------------------------------- */
  /*                                   HELPERS                                  */
  /* -------------------------------------------------------------------------- */

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
  /*                                     UI                                     */
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
            title: const Text('Recurring income'),
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
      appBar: AppBar(title: const Text('Edit Income')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _textField('Description *', _descriptionController),
              const SizedBox(height: 12),
              _dateField('Received date *', _receivedDateController),
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
                    onPressed: _updateIncome,
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
