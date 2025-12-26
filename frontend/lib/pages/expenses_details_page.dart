import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExpensesDetailsPage extends StatefulWidget {
  const ExpensesDetailsPage({super.key});

  @override
  State<ExpensesDetailsPage> createState() => _ExpensesDetailsPageState();
}

class _ExpensesDetailsPageState extends State<ExpensesDetailsPage> {
  late String selectedMonth;
  late String selectedYear;
  late List<String> years;

  List<Map<String, dynamic>> expenses = [];

  String _expensesUrl = '';

  final Map<String, int> monthToNumber = {
    'January': 1,
    'February': 2,
    'March': 3,
    'April': 4,
    'May': 5,
    'June': 6,
    'July': 7,
    'August': 8,
    'September': 9,
    'October': 10,
    'November': 11,
    'December': 12,
  };

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    selectedYear = now.year.toString();
    selectedMonth =
        monthToNumber.entries.firstWhere((e) => e.value == now.month).key;

    years = List.generate(11, (i) => (now.year - 5 + i).toString());

    _setupApiUrl();
  }

  Future<bool> _isRunningOnEmulator() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return !info.isPhysicalDevice;
    }
    if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      return !info.isPhysicalDevice;
    }
    return false;
  }

  Future<void> _setupApiUrl() async {
    final isEmulator = await _isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';

    setState(() {
      _expensesUrl = '$baseUrl/expenses';
    });

    await _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final month = monthToNumber[selectedMonth];

    if (token == null || month == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_expensesUrl?month=$month&year=$selectedYear'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          expenses = data.cast<Map<String, dynamic>>();
        });
      } else {
        setState(() => expenses = []);
      }
    } catch (_) {
      setState(() => expenses = []);
    }
  }

  Future<Map<String, dynamic>?> _getExpenseDetails(int expenseId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userId = prefs.getString('userId');

    if (token == null || userId == null) return null;

    final isEmulator = await _isRunningOnEmulator();
    final baseUrl =
        isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';

    final url = '$baseUrl/expense/$expenseId?user_id=$userId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _deleteExpense(int expenseId) async {
    final expense = await _getExpenseDetails(expenseId);
    if (expense == null) return;

    final bool isRecurring = expense['is_recurring'] ?? false;

    if (!isRecurring) {
      await _confirmDelete(expenseId);
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (_) => const RecurrenceDeleteDialog(),
    );

    if (choice == 'all') {
      await _confirmDelete(expenseId);
    } else if (choice == 'future') {
      await _endRecurringExpense(expenseId);
    }
  }

  Future<void> _confirmDelete(int expenseId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('$_expensesUrl/$expenseId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully')),
        );
        _loadExpenses();
      }
    } catch (_) {}
  }

  Future<void> _endRecurringExpense(int expenseId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) return;

    final month = monthToNumber[selectedMonth]!;
    final year = int.parse(selectedYear);

    final endDate = DateTime(year, month, 0);

    try {
      await http.put(
        Uri.parse('$_expensesUrl/$expenseId/end-recurrence'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'recurrence_end_date': endDate.toIso8601String(),
        }),
      );
      _loadExpenses();
    } catch (_) {}
  }

  Widget _buildExpenseTile(Map<String, dynamic> expense) {
    final description = expense['description'] ?? '';
    final amount = expense['amount'] ?? 0.0;
    final dueDate = expense['due_date'];
    final isRecurring = expense['is_recurring'] ?? false;
    final endDate = expense['recurrence_end_date'];
    final expenseId = expense['id'];

    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');
    final amountFormatted = currency.format(amount);

    final dueDateFormatted =
        DateFormat('dd/MM/yyyy').format(DateTime.parse(dueDate));

    final endDateFormatted = endDate != null
        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(endDate))
        : 'Indefinite';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.money_off, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  amountFormatted,
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Paid on: $dueDateFormatted'),
            Text('Recurring: ${isRecurring ? "Yes" : "No"}'),
            if (isRecurring) Text('Recurrence end: $endDateFormatted'),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/edit-expense',
                      arguments: {'id': expenseId},
                    ).then((_) => _loadExpenses());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteExpense(expenseId),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildDropdown(
                  'Month',
                  selectedMonth,
                  monthToNumber.keys.toList(),
                  (v) {
                    setState(() => selectedMonth = v!);
                    _loadExpenses();
                  },
                ),
                const SizedBox(width: 12),
                _buildDropdown(
                  'Year',
                  selectedYear,
                  years,
                  (v) {
                    setState(() => selectedYear = v!);
                    _loadExpenses();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: expenses.isEmpty
                  ? const Center(child: Text('No expenses found'))
                  : ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (_, i) => _buildExpenseTile(expenses[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecurrenceDeleteDialog extends StatelessWidget {
  const RecurrenceDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recurring expense'),
      content: const Text(
        'Do you want to delete:\n\n'
        '• Only from this month forward?\n'
        '• Or all records including previous months?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'future'),
          child: const Text('From now on'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'all'),
          child: const Text('Delete all'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
