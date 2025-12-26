// import 'dart:io';
// import 'dart:convert';
// import 'package:intl/intl.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:device_info_plus/device_info_plus.dart';

// class ConfiguracoesPage extends StatefulWidget {
//   final Map<String, dynamic> dadosUsuario;

//   const ConfiguracoesPage({super.key, required this.dadosUsuario});

//   @override
//   State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
// }

// class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
//   final _nomeController = TextEditingController();
//   final _sobrenomeController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _dateController = TextEditingController();
//   final _cepController = TextEditingController();
//   final _ruaController = TextEditingController();
//   final _numeroController = TextEditingController();
//   final _bairroController = TextEditingController();
//   final _complementoController = TextEditingController();

//   final GlobalKey<FormState> _formKeyNome = GlobalKey<FormState>();
//   final GlobalKey<FormState> _formKeyEmail = GlobalKey<FormState>();
//   final _formKeyEndereco = GlobalKey<FormState>();

//   int? _idEstadoSelecionado;
//   Map<int, String> estadosMap = {};
//   DateTime? _selectedDate;
//   bool _editandoNome = false;
//   bool _editandoEmail = false;
//   bool _editandoNascimento = false;
//   bool _editandoEndereco = false;
//   String _estadosUrl = '';

//   String? _validateRequired(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Campo obrigatório';
//     }
//     return null;
//   }

//   String? _validateEmail(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'E-mail é obrigatório';
//     }
//     final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
//     if (!regex.hasMatch(value)) {
//       return 'E-mail inválido';
//     }
//     return null;
//   }

//   String _formatarData(String data) {
//     try {
//       final partes = data.split('-');
//       final ano = int.parse(partes[0]);
//       final mes = int.parse(partes[1]);
//       final dia = int.parse(partes[2]);
//       final dataFormatada = DateTime(ano, mes, dia);
//       return DateFormat('dd/MM/yyyy').format(dataFormatada);
//     } catch (_) {
//       return data;
//     }
//   }

//   void _inicializarControllers() {
//     final endereco = widget.dadosUsuario['endereco'] ?? {};
//     _cepController.text = endereco['cep'] ?? '';
//     _ruaController.text = endereco['rua'] ?? '';
//     _numeroController.text = endereco['numero'] ?? '';
//     _bairroController.text = endereco['bairro'] ?? '';
//     _complementoController.text = endereco['complemento'] ?? '';
//     _idEstadoSelecionado = endereco['id_estado'];
//   }

//   @override
//   void initState() {
//     super.initState();
//     _setupApiUrl();
//     _inicializarControllers();
//   }

//   Future<bool> isRunningOnEmulator() async {
//     final deviceInfo = DeviceInfoPlugin();
//     if (Platform.isAndroid) {
//       final androidInfo = await deviceInfo.androidInfo;
//       return !androidInfo.isPhysicalDevice;
//     } else if (Platform.isIOS) {
//       final iosInfo = await deviceInfo.iosInfo;
//       return !iosInfo.isPhysicalDevice;
//     }
//     return false;
//   }

//   Future<void> _setupApiUrl() async {
//     final isEmulator = await isRunningOnEmulator();
//     final baseUrl =
//         isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
//     _estadosUrl = '$baseUrl/estados';
//     await _carregarEstados();
//   }

//   Future<void> _carregarEstados() async {
//     try {
//       final response = await http.get(Uri.parse(_estadosUrl));
//       if (response.statusCode == 200) {
//         final String bodyUtf8 = utf8.decode(response.bodyBytes);
//         final List<dynamic> estados = jsonDecode(bodyUtf8);
//         setState(() {
//           estadosMap = {
//             for (var estado in estados) estado['id']: estado['nome']
//           };
//         });
//       } else {
//         print('Erro ao carregar estados: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Erro ao carregar estados: $e');
//     }
//   }

//   Future<void> _salvarNome() async {
//     if (!_formKeyNome.currentState!.validate()) {
//       return; // se tiver algum campo vazio, não continua
//     }

//     final idLogin = widget.dadosUsuario['id_login'];
//     final isEmulator = await isRunningOnEmulator();
//     final baseUrl =
//         isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
//     final url = Uri.parse('$baseUrl/atualizar-nome/$idLogin');

//     final body = jsonEncode({
//       "nome": _nomeController.text.trim(),
//       "sobrenome": _sobrenomeController.text.trim(),
//     });

//     try {
//       final response = await http.put(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: body,
//       );

//       if (response.statusCode == 200) {
//         setState(() {
//           widget.dadosUsuario['nome'] = _nomeController.text;
//           widget.dadosUsuario['sobrenome'] = _sobrenomeController.text;
//           _editandoNome = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Nome atualizado com sucesso")),
//         );
//       } else {
//         print('Erro: ${response.body}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Erro ao atualizar nome")),
//         );
//       }
//     } catch (e) {
//       print('Erro ao enviar atualização: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erro na comunicação com o servidor")),
//       );
//     }
//   }

//   Future<void> _salvarEmail() async {
//     if (!_formKeyEmail.currentState!.validate()) {
//       return; // se tiver algum campo vazio, não continua
//     }

//     final idLogin = widget.dadosUsuario['id_login'];
//     final isEmulator = await isRunningOnEmulator();
//     final baseUrl =
//         isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
//     final url = Uri.parse('$baseUrl/atualizar-email/$idLogin');

//     final body = jsonEncode({
//       "email": _emailController.text.trim(),
//     });

//     try {
//       final response = await http.put(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: body,
//       );

//       if (response.statusCode == 200) {
//         setState(() {
//           widget.dadosUsuario['email'] = _emailController.text.trim();
//           _editandoEmail = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("E-mail atualizado com sucesso")),
//         );
//       } else {
//         print('Erro: ${response.body}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Erro ao atualizar e-mail")),
//         );
//       }
//     } catch (e) {
//       print('Erro ao enviar atualização: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erro na comunicação com o servidor")),
//       );
//     }
//   }

//   // Future<void> _salvarNascimento() async {
//   //   final idLogin = widget.dadosUsuario['id_login'];
//   //   final isEmulator = await isRunningOnEmulator();
//   //   final baseUrl =
//   //       isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
//   //   final url = Uri.parse('$baseUrl/atualizar-nascimento/$idLogin');

//   //   final nascimentoFormatado = DateFormat('yyyy-MM-dd').format(_selectedDate!);
//   //   final body = jsonEncode({
//   //     "data_nascimento": nascimentoFormatado,
//   //   });

//   //   try {
//   //     final response = await http.put(
//   //       url,
//   //       headers: {"Content-Type": "application/json"},
//   //       body: body,
//   //     );

//   //     if (response.statusCode == 200) {
//   //       setState(() {
//   //         widget.dadosUsuario['data_nascimento'] = _dateController.text.trim();
//   //         _editandoNascimento = false;
//   //       });
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         const SnackBar(
//   //             content: Text("Data de nascimento atualizado com sucesso")),
//   //       );
//   //     } else {
//   //       print('Erro: ${response.body}');
//   //       ScaffoldMessenger.of(context).showSnackBar(
//   //         const SnackBar(content: Text("Erro ao atualizar data de nascimento")),
//   //       );
//   //     }
//   //   } catch (e) {
//   //     print('Erro ao enviar atualização: $e');
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text("Erro na comunicação com o servidor")),
//   //     );
//   //   }
//   // }

//   Future<void> _salvarNascimento() async {
//     final idLogin = widget.dadosUsuario['id_login'];
//     final isEmulator = await isRunningOnEmulator();
//     final baseUrl =
//         isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
//     final url = Uri.parse('$baseUrl/atualizar-nascimento/$idLogin');

//     try {
//       final parts = _dateController.text.trim().split('/');
//       if (parts.length != 3) throw Exception();
//       final day = int.parse(parts[0]);
//       final month = int.parse(parts[1]);
//       final year = int.parse(parts[2]);
//       _selectedDate = DateTime(year, month, day);
//     } catch (_) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Data de nascimento inválida")),
//       );
//       return;
//     }

//     final nascimentoFormatado = DateFormat('yyyy-MM-dd').format(_selectedDate!);
//     final body = jsonEncode({
//       "data_nascimento": nascimentoFormatado,
//     });

//     try {
//       final response = await http.put(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: body,
//       );

//       if (response.statusCode == 200) {
//         setState(() {
//           widget.dadosUsuario['data_nascimento'] = _dateController.text.trim();
//           _editandoNascimento = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//               content: Text("Data de nascimento atualizada com sucesso")),
//         );
//       } else {
//         print('Erro: ${response.body}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Erro ao atualizar data de nascimento")),
//         );
//       }
//     } catch (e) {
//       print('Erro ao enviar atualização: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Erro na comunicação com o servidor")),
//       );
//     }
//   }

//   Future<void> _salvarEndereco() async {
//     final idEndereco = widget.dadosUsuario['endereco']['id'];
//     final isEmulator = await isRunningOnEmulator();
//     final baseUrl =
//         isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
//     final url = Uri.parse('$baseUrl/atualizar-endereco/$idEndereco');

//     final body = jsonEncode({
//       "cep": _cepController.text,
//       "rua": _ruaController.text,
//       "numero": _numeroController.text,
//       "bairro": _bairroController.text,
//       "complemento": _complementoController.text,
//       "id_estado": _idEstadoSelecionado,
//     });

//     try {
//       final response = await http.put(url,
//           headers: {"Content-Type": "application/json"}, body: body);

//       if (response.statusCode == 200) {
//         setState(() {
//           _editandoEndereco = false;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Endereço atualizado com sucesso")),
//         );
//       } else {
//         print('Erro: ${response.body}');
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Erro ao atualizar endereço")),
//         );
//       }
//     } catch (e) {
//       print('Erro ao enviar atualização: $e');
//     }
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 18,
//           fontWeight: FontWeight.bold,
//           color: Colors.blueAccent,
//         ),
//       ),
//     );
//   }

//   Widget _buildEditableField(String label, TextEditingController controller,
//       {bool obscureText = false, String? Function(String?)? validator}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: TextFormField(
//         controller: controller,
//         obscureText: obscureText,
//         validator: validator,
//         decoration: InputDecoration(
//           labelText: label,
//           errorMaxLines: 3,
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: Colors.blue, width: 2),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildEstadoDropdown() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: DropdownButtonFormField<int>(
//         value: _idEstadoSelecionado,
//         items: estadosMap.entries
//             .map((entry) =>
//                 DropdownMenuItem(value: entry.key, child: Text(entry.value)))
//             .toList(),
//         onChanged: (value) {
//           setState(() {
//             _idEstadoSelecionado = value;
//           });
//         },
//         decoration: InputDecoration(
//           labelText: 'Estado',
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       ),
//     );
//   }

//   Widget _buildEnderecoRow(IconData icon, String label, String? value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.blue, size: 20),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               '$label: ${value ?? 'Não informado'}',
//               style: const TextStyle(fontSize: 16),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDatePicker(String label) {
//     return TextFormField(
//       controller: _dateController,
//       keyboardType: TextInputType.number,
//       inputFormatters: [DateInputFormatter()],
//       decoration: InputDecoration(
//         labelText: label,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         suffixIcon: IconButton(
//           icon: const Icon(Icons.calendar_today),
//           onPressed: () async {
//             final pickedDate = await showDatePicker(
//               context: context,
//               initialDate: _selectedDate ?? DateTime.now(),
//               firstDate: DateTime(1900),
//               lastDate: DateTime.now(),
//             );
//             if (pickedDate != null) {
//               setState(() {
//                 _selectedDate = pickedDate;
//                 _dateController.text =
//                     DateFormat('dd/MM/yyyy').format(pickedDate);
//               });
//             }
//           },
//         ),
//       ),
//       validator: (value) {
//         if (value == null || value.isEmpty) {
//           return 'Data de nascimento é obrigatória';
//         }
//         try {
//           final parts = value.split('/');
//           if (parts.length != 3) throw Exception();
//           final day = int.parse(parts[0]);
//           final month = int.parse(parts[1]);
//           final year = int.parse(parts[2]);
//           _selectedDate =
//               DateTime(year, month, day); // define a data para envio
//         } catch (_) {
//           return 'Data inválida';
//         }
//         return null;
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Configurações'),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           _buildSectionTitle('Dados Pessoais'),
//           // Nome
//           Card(
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             margin: const EdgeInsets.symmetric(vertical: 6),
//             elevation: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: _editandoNome
//                   ? Form(
//                       key: _formKeyNome,
//                       child: Column(
//                         children: [
//                           _buildEditableField('Nome', _nomeController,
//                               validator: _validateRequired),
//                           _buildEditableField('Sobrenome', _sobrenomeController,
//                               validator: _validateRequired),
//                           const SizedBox(height: 8),
//                           ElevatedButton.icon(
//                             icon: const Icon(Icons.save),
//                             label: const Text("Salvar"),
//                             onPressed: _salvarNome,
//                           ),
//                         ],
//                       ),
//                     )
//                   : Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: [
//                             const Icon(Icons.person, color: Colors.blue),
//                             const SizedBox(width: 8),
//                             Text(
//                               '${widget.dadosUsuario['nome']} ${widget.dadosUsuario['sobrenome']}',
//                               style: const TextStyle(fontSize: 16),
//                             ),
//                           ],
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.edit, color: Colors.blue),
//                           onPressed: () {
//                             setState(() {
//                               _editandoNome = true;
//                               _nomeController.text =
//                                   widget.dadosUsuario['nome'] ?? '';
//                               _sobrenomeController.text =
//                                   widget.dadosUsuario['sobrenome'] ?? '';
//                             });
//                           },
//                         ),
//                       ],
//                     ),
//             ),
//           ),
//           // E-mail
//           Card(
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             margin: const EdgeInsets.symmetric(vertical: 6),
//             elevation: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: _editandoEmail
//                   ? Form(
//                       key: _formKeyEmail,
//                       child: Column(
//                         children: [
//                           _buildEditableField('Email', _emailController,
//                               validator: _validateEmail),
//                           ElevatedButton.icon(
//                             icon: const Icon(Icons.save),
//                             label: const Text("Salvar"),
//                             onPressed: _salvarEmail,
//                           ),
//                         ],
//                       ),
//                     )
//                   : Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: [
//                             const Icon(Icons.email, color: Colors.blue),
//                             const SizedBox(width: 8),
//                             Text(
//                               widget.dadosUsuario['email'] ?? 'Não informado',
//                               style: const TextStyle(fontSize: 16),
//                             ),
//                           ],
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.edit, color: Colors.blue),
//                           onPressed: () {
//                             setState(() {
//                               _editandoEmail = true;
//                               _emailController.text =
//                                   widget.dadosUsuario['email'] ?? '';
//                             });
//                           },
//                         ),
//                       ],
//                     ),
//             ),
//           ),
//           // Data de Nascimento
//           Card(
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             margin: const EdgeInsets.symmetric(vertical: 6),
//             elevation: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: _editandoNascimento
//                   ? Column(
//                       children: [
//                         _buildDatePicker('Data de Nascimento:'),
//                         const SizedBox(height: 8),
//                         ElevatedButton.icon(
//                           icon: const Icon(Icons.save),
//                           label: const Text("Salvar"),
//                           onPressed: _salvarNascimento,
//                         ),
//                       ],
//                     )
//                   : Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Row(
//                           children: [
//                             const Icon(Icons.cake, color: Colors.blue),
//                             const SizedBox(width: 8),
//                             Text(
//                               _formatarData(
//                                   widget.dadosUsuario['data_nascimento']),
//                               style: const TextStyle(fontSize: 16),
//                             ),
//                           ],
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.edit, color: Colors.blue),
//                           onPressed: () {
//                             setState(() {
//                               _editandoNascimento = true;
//                               try {
//                                 final partes = widget
//                                     .dadosUsuario['data_nascimento']
//                                     .split('-');
//                                 final ano = int.parse(partes[0]);
//                                 final mes = int.parse(partes[1]);
//                                 final dia = int.parse(partes[2]);
//                                 _selectedDate = DateTime(ano, mes, dia);
//                                 _dateController.text = DateFormat('dd/MM/yyyy')
//                                     .format(_selectedDate!);
//                               } catch (_) {
//                                 _dateController.text = '';
//                                 _selectedDate = null;
//                               }
//                             });
//                           },
//                         ),
//                       ],
//                     ),
//             ),
//           ),
//           const SizedBox(height: 24),
//           _buildSectionTitle('Endereço'),
//           Card(
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//             margin: const EdgeInsets.symmetric(vertical: 6),
//             elevation: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: _editandoEndereco
//                   ? Form(
//                       key: _formKeyEndereco,
//                       child: Column(
//                         children: [
//                           _buildEditableField('CEP', _cepController,
//                               validator: _validateRequired),
//                           _buildEstadoDropdown(),
//                           _buildEditableField('Rua', _ruaController,
//                               validator: _validateRequired),
//                           _buildEditableField('Número', _numeroController,
//                               validator: _validateRequired),
//                           _buildEditableField('Bairro', _bairroController,
//                               validator: _validateRequired),
//                           _buildEditableField(
//                               'Complemento', _complementoController),
//                           const SizedBox(height: 12),
//                           ElevatedButton.icon(
//                             icon: const Icon(Icons.save),
//                             label: const Text("Salvar"),
//                             onPressed: () {
//                               if (_formKeyEndereco.currentState!.validate() &&
//                                   _idEstadoSelecionado != null) {
//                                 _salvarEndereco();
//                               } else if (_idEstadoSelecionado == null) {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                       content: Text("Estado é obrigatório")),
//                                 );
//                               }
//                             },
//                           ),
//                         ],
//                       ),
//                     )
//                   : Column(
//                       children: [
//                         _buildEnderecoRow(
//                             Icons.map, 'CEP', _cepController.text),
//                         _buildEnderecoRow(
//                             Icons.flag,
//                             'Estado',
//                             estadosMap[_idEstadoSelecionado] ??
//                                 'Carregando...'),
//                         _buildEnderecoRow(
//                             Icons.home, 'Rua', _ruaController.text),
//                         _buildEnderecoRow(
//                             Icons.numbers, 'Número', _numeroController.text),
//                         _buildEnderecoRow(Icons.location_city, 'Bairro',
//                             _bairroController.text),
//                         _buildEnderecoRow(Icons.place, 'Complemento',
//                             _complementoController.text),
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: IconButton(
//                             icon: const Icon(Icons.edit, color: Colors.blue),
//                             onPressed: () {
//                               setState(() {
//                                 _editandoEndereco = true;
//                               });
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class DateInputFormatter extends TextInputFormatter {
//   @override
//   TextEditingValue formatEditUpdate(
//       TextEditingValue oldValue, TextEditingValue newValue) {
//     var text = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

//     final buffer = StringBuffer();
//     for (int i = 0; i < text.length && i < 8; i++) {
//       if (i == 2 || i == 4) buffer.write('/');
//       buffer.write(text[i]);
//     }

//     final formatted = buffer.toString();
//     return TextEditingValue(
//       text: formatted,
//       selection: TextSelection.collapsed(offset: formatted.length),
//     );
//   }
// }
