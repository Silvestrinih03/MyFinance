// import 'package:flutter/material.dart';
// import '../utils/environment.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// String _esqueciSenhaUrl = '';

// class ForgotPasswordPage extends StatefulWidget {
//   const ForgotPasswordPage({super.key});

//   @override
//   State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
// }

// class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
//   final TextEditingController _emailController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     _setupApiUrl();
//   }

//   Future<void> _setupApiUrl() async {
//     final isEmulator = await isRunningOnEmulator();
//     setState(() {
//       _esqueciSenhaUrl = isEmulator
//           ? 'http://10.0.2.2:8000/esqueci-senha'
//           : 'http://localhost:8000/esqueci-senha';
//     });
//   }

//   Future<void> sendEmail() async {
//     if (!_formKey.currentState!.validate()) {
//       return;
//     }

//     setState(() => _isLoading = true);

//     final requestBody = {'email': _emailController.text};

//     try {
//       final response = await http.post(
//         Uri.parse(_esqueciSenhaUrl),
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(requestBody),
//       );

//       if (response.statusCode == 200) {
//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text(
//                   'Se o e-mail estiver cadastrado, você receberá um link para redefinir a senha.'),
//             ),
//           );
//           await Future.delayed(const Duration(seconds: 1));
//           Navigator.pushReplacementNamed(context, '/login');
//         }
//       } else {
//         _showSnackbar('Falha ao enviar email: ${response.body}');
//       }
//     } catch (e) {
//       _showSnackbar('Erro ao enviar email: $e');
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   void _showSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Colors.blue,
//         title: const Text(
//           'Recuperar Senha',
//           style: TextStyle(color: Colors.white),
//         ),
//         iconTheme: const IconThemeData(color: Colors.white),
//         elevation: 0,
//       ),
//       body: Form(
//         key: _formKey,
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Digite seu e-mail para recuperar a senha:',
//                 style: TextStyle(fontSize: 16, color: Colors.black87),
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _emailController,
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Por favor, insira um e-mail';
//                   }
//                   if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
//                     return 'Insira um e-mail válido';
//                   }
//                   return null;
//                 },
//                 decoration: InputDecoration(
//                   hintText: 'E-mail',
//                   filled: true,
//                   fillColor: Colors.blue.shade50,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     borderSide: BorderSide.none,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Center(
//                 child: _isLoading
//                     ? const CircularProgressIndicator()
//                     : ElevatedButton(
//                         onPressed: sendEmail,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.blue,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 40, vertical: 14),
//                         ),
//                         child: const Text('Confirmar'),
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
