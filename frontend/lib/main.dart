import 'package:flutter/material.dart';
import 'package:frontend/pages/edit_expense_page.dart';
import 'package:frontend/pages/edit_income_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/insert_expense_page.dart';
import 'pages/insert_income_page.dart';
import 'pages/income_details_page.dart';
import 'pages/expenses_details_page.dart';

void main() {
  runApp(const MyFinanceApp());
}

class MyFinanceApp extends StatelessWidget {
  const MyFinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFinance',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2F80ED),
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/insert_expense_page': (context) => const InsertExpensePage(),
        '/insert_income_page': (context) => const InsertIncomePage(),
        '/income_details_page': (context) => const IncomeDetailsPage(),
        '/expenses_details_page': (context) => const ExpensesDetailsPage(),
        '/edit_expense_page': (context) => const EditExpensePage(),
        '/edit_income_page': (context) => const EditIncomePage(),
      },
    );
  }
}
