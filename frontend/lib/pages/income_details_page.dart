import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/environment.dart';

class IncomeDetailsPage extends StatefulWidget {
  const IncomeDetailsPage({super.key});

  @override
  State<IncomeDetailsPage> createState() => _IncomeDetailsPageState();
}

class _IncomeDetailsPageState extends State<IncomeDetailsPage> {
  late String selectedMonth;
  late String selectedYear;
  late List<String> years;

  List<Map<String, dynamic>> incomes = [];
  final _storage = const FlutterSecureStorage();

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
    years = List.generate(11, (i) => (now.year - 5 + i).toString());
    selectedYear = now.year.toString();
    selectedMonth =
        monthToNumber.entries.firstWhere((e) => e.value == now.month).key;

    _loadIncomes();
  }

  Future<void> _loadIncomes() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    final month = monthToNumber[selectedMonth];

    try {
      final response = await http.get(
        Uri.parse(
          "${Environment.apiBaseUrl}/incomes?month=$month&year=$selectedYear",
        ),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          incomes = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        setState(() => incomes = []);
      }
    } catch (_) {
      setState(() => incomes = []);
    }
  }

  Future<void> _deleteIncome(int incomeId) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    final response = await http.delete(
      Uri.parse("${Environment.apiBaseUrl}/incomes/$incomeId"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      _loadIncomes();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income deleted successfully')),
      );
    }
  }

  Widget _buildIncomeCard(Map<String, dynamic> income) {
    final description = income['description'];
    final amount = income['amount'];
    final receivedDate = DateTime.parse(income['received_date']);
    final isRecurring = income['is_recurring'];

    final currency = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    final formattedAmount = currency.format(amount);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text("Amount: $formattedAmount"),
            Text(
              "Received on: ${DateFormat('dd/MM/yyyy').format(receivedDate)}",
            ),
            Text("Recurring: ${isRecurring ? 'Yes' : 'No'}"),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteIncome(income['id']),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Income Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedMonth,
                    items: monthToNumber.keys
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedMonth = v!);
                      _loadIncomes();
                    },
                    decoration: const InputDecoration(labelText: 'Month'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedYear,
                    items: years
                        .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text(y),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() => selectedYear = v!);
                      _loadIncomes();
                    },
                    decoration: const InputDecoration(labelText: 'Year'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: incomes.isEmpty
                  ? const Center(child: Text('No incomes found'))
                  : ListView.builder(
                      itemCount: incomes.length,
                      itemBuilder: (_, i) => _buildIncomeCard(incomes[i]),
                    ),
            )
          ],
        ),
      ),
    );
  }
}
