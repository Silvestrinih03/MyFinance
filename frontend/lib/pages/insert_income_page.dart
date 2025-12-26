import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/input_formatters.dart';
import '../utils/environment.dart';

class InsertIncomePage extends StatefulWidget {
  const InsertIncomePage({super.key});

  @override
  State<InsertIncomePage> createState() => _InsertIncomePageState();
}

class _InsertIncomePageState extends State<InsertIncomePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _receivedDateController = TextEditingController();
  final _recurrenceEndDateController = TextEditingController();

  final _storage = const FlutterSecureStorage();

  DateTime? _receivedDate;
  DateTime? _recurrenceEndDate;
  bool _isRecurring = false;

  DateTime _parseDate(String input) {
    return DateFormat('dd/MM/yyyy').parseStrict(input);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitIncome() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage("Please fill all required fields.");
      return;
    }

    try {
      _receivedDate = _parseDate(_receivedDateController.text);

      if (_isRecurring && _recurrenceEndDateController.text.isNotEmpty) {
        _recurrenceEndDate = _parseDate(_recurrenceEndDateController.text);

        if (!_recurrenceEndDate!.isAfter(_receivedDate!)) {
          _showMessage("Recurrence end date must be after the received date.");
          return;
        }
      }
    } catch (_) {
      _showMessage("Invalid dates.");
      return;
    }

    final token = await _storage.read(key: 'access_token');
    if (token == null) {
      _showMessage("User not authenticated.");
      return;
    }

    final body = {
      'description': _descriptionController.text,
      'amount': double.tryParse(
            _amountController.text
                .replaceAll(RegExp(r'[^\d,]'), '')
                .replaceAll(',', '.'),
          ) ??
          0.0,
      'received_date': _receivedDate!.toIso8601String().split('T')[0],
      'is_recurring': _isRecurring,
    };

    if (_recurrenceEndDate != null) {
      body['recurrence_end_date'] =
          _recurrenceEndDate!.toIso8601String().split('T')[0];
    }

    try {
      final response = await http.post(
        Uri.parse("${Environment.apiBaseUrl}/incomes"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showMessage("Income saved successfully.");
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        _showMessage("Error saving income.");
      }
    } catch (e) {
      _showMessage("Connection error.");
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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

  Widget _buildDateField(
    String label,
    TextEditingController controller, {
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [DateInputFormatter()],
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => _selectDate(controller),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'Required field';
        }
        if (value != null && value.isNotEmpty) {
          try {
            _parseDate(value);
          } catch (_) {
            return 'Invalid date (dd/MM/yyyy)';
          }
        }
        return null;
      },
    );
  }

  Widget _buildRecurringSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: const Text("Recurring income"),
            value: _isRecurring,
            onChanged: (v) => setState(() => _isRecurring = v),
          ),
          if (_isRecurring)
            _buildDateField(
              "Recurrence end date (optional)",
              _recurrenceEndDateController,
              required: false,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Income")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Description *", _descriptionController),
              const SizedBox(height: 12),
              _buildDateField("Received date *", _receivedDateController),
              const SizedBox(height: 12),
              _buildTextField(
                "Amount *",
                _amountController,
                keyboardType: TextInputType.number,
                formatters: [CurrencyInputFormatter()],
              ),
              const SizedBox(height: 12),
              _buildRecurringSwitch(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _submitIncome,
                    icon: const Icon(Icons.save),
                    label: const Text("Save"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.cancel),
                    label: const Text("Cancel"),
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
