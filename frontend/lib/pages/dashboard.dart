// import 'dart:io';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:http/http.dart' as http;
// import 'package:device_info_plus/device_info_plus.dart';

// class DashboardScreen extends StatefulWidget {
//   final int idLogin;
//   const DashboardScreen({Key? key, required this.idLogin}) : super(key: key);

//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   late String selectedMonth, selectedYear;
//   late List<String> years;
//   double saldo = 0.0;
//   int receitasRecorrentes = 0;
//   int receitasNaoRecorrentes = 0;
//   int despesasRecorrentes = 0;
//   int despesasNaoRecorrentes = 0;

//   List<BarChartGroupData> barGroups = [];
//   List<PieChartSectionData> pieSections = [];
//   List<PieChartSectionData> pieSectionsReceitas = [];
//   List<PieChartSectionData> pieSectionsDespesas = [];
//   List<FlSpot> receitaSpots = [];
//   List<String> receitaLabels = [];
//   List<FlSpot> despesaSpots = [];
//   List<String> despesaLabels = [];
//   List<FlSpot> saldoSpots = [];

//   String _diaVencimentoUrl = '';
//   String _despesasCategoriaUrl = '';
//   String _receitasPorMesUrl = '';
//   String _despesasPorMesUrl = '';
//   String _receitasRecorrenciaUrl = '';
//   String _despesasRecorrenciaUrl = '';

//   final List<Color> bluePalette = [
//     Color(0xFF56CCF2), // azul claro
//     Color(0xFF2F80ED), // azul médio
//     Color(0xFFBB6BD9), // lilás
//     Color(0xFF9B51E0), // roxo claro
//     Color(0xFF6FCF97), // verde menta
//     Color(0xFF219653), // verde escuro
//     Color(0xFFEB5757) // vermelho suave
//   ];

//   final Map<String, int> monthToNumber = {
//     'Janeiro': 1,
//     'Fevereiro': 2,
//     'Março': 3,
//     'Abril': 4,
//     'Maio': 5,
//     'Junho': 6,
//     'Julho': 7,
//     'Agosto': 8,
//     'Setembro': 9,
//     'Outubro': 10,
//     'Novembro': 11,
//     'Dezembro': 12,
//   };

//   void _setupApi() async {
//     final isEmulator = await isRunningOnEmulator();
//     final baseUrl =
//         isEmulator ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
//     setState(() {
//       _diaVencimentoUrl = '$baseUrl/contagem-despesas-por-dia-vencimento';
//       _despesasCategoriaUrl = '$baseUrl/contagem-despesas-por-categoria';
//       _receitasPorMesUrl = '$baseUrl/total-receitas-periodo';
//       _despesasPorMesUrl = '$baseUrl/total-despesas-periodo';
//       _receitasRecorrenciaUrl = '$baseUrl/total-receitas-recorrencia';
//       _despesasRecorrenciaUrl = '$baseUrl/total-despesas-recorrencia';
//     });
//     await _loadDespesasPorDiaVencimento();
//     await _loadDespesasPorCategoria();
//     await _loadReceitasPorPeriodo();
//     await _loadDespesasPorPeriodo();
//     await _loadSaldoPorPeriodo();
//     await _loadReceitasRecorrencia();
//     await _loadDespesasRecorrencia();
//   }

//   @override
//   void initState() {
//     super.initState();
//     final currentYear = DateTime.now().year;
//     final currentMonth = DateTime.now().month;
//     years = List.generate(11, (index) => (currentYear - 5 + index).toString());
//     selectedYear = currentYear.toString();
//     selectedMonth = monthToNumber.entries
//         .firstWhere((entry) => entry.value == currentMonth)
//         .key;
//     _setupApi();
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

//   Future<void> _loadDespesasPorDiaVencimento() async {
//     final mes = monthToNumber[selectedMonth];
//     final url = Uri.parse(
//         '$_diaVencimentoUrl?id_login=${widget.idLogin}&mes=$mes&ano=$selectedYear');

//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

//       setState(() {
//         barGroups = data.asMap().entries.map((entry) {
//           final index = entry.key;
//           final item = entry.value;

//           return BarChartGroupData(
//             x: item['dia'],
//             barRods: [
//               BarChartRodData(
//                 toY: item['quantidade'].toDouble(),
//                 color: bluePalette[index % bluePalette.length], // aqui
//                 width: 16,
//                 borderRadius: BorderRadius.circular(4),
//               ),
//             ],
//           );
//         }).toList();
//       });
//     }
//   }

//   Future<void> _loadDespesasPorCategoria() async {
//     final url = Uri.parse(
//         '$_despesasCategoriaUrl?id_login=${widget.idLogin}&mes=${monthToNumber[selectedMonth]}&ano=$selectedYear');

//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

//       setState(() {
//         pieSections = data.asMap().entries.map((entry) {
//           final index = entry.key;
//           final item = entry.value;

//           final colors = bluePalette;
//           final total = data.fold<double>(0, (sum, e) => sum + e['quantidade']);
//           final percentual = (item['quantidade'] / total) * 100;

//           return PieChartSectionData(
//             value: item['quantidade'].toDouble(),
//             title: '',
//             color: colors[index % colors.length],
//             radius: 60,
//             badgeWidget: Container(
//               width: 100,
//               padding: const EdgeInsets.symmetric(horizontal: 4),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     item['categoria'],
//                     softWrap: true,
//                     overflow: TextOverflow.visible,
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   Text(
//                     '${percentual.toStringAsFixed(1)}%',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Colors.white,
//                       fontWeight: FontWeight.normal,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//             // badgePositionPercentageOffset: 1.0,
//             showTitle: false,
//           );
//         }).toList();
//       });
//     }
//   }

//   Future<void> _loadReceitasPorPeriodo() async {
//     final mes = monthToNumber[selectedMonth];
//     final url = Uri.parse(
//         '$_receitasPorMesUrl?id_login=${widget.idLogin}&mes=$mes&ano=$selectedYear');

//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

//       setState(() {
//         receitaSpots = [];
//         receitaLabels = [];

//         for (int i = 0; i < data.length; i++) {
//           final item = data[i];
//           receitaSpots
//               .add(FlSpot(i.toDouble(), (item['valor'] as num).toDouble()));
//           receitaLabels
//               .add('${item['mes'].toString().padLeft(2, '0')}/${item['ano']}');
//         }
//       });
//     }
//   }

//   Future<void> _loadDespesasPorPeriodo() async {
//     final mes = monthToNumber[selectedMonth];
//     final url = Uri.parse(
//         '$_despesasPorMesUrl?id_login=${widget.idLogin}&mes=$mes&ano=$selectedYear');

//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));

//       setState(() {
//         despesaSpots = [];
//         despesaLabels = [];

//         for (int i = 0; i < data.length; i++) {
//           final item = data[i];
//           despesaSpots
//               .add(FlSpot(i.toDouble(), (item['valor'] as num).toDouble()));
//           despesaLabels
//               .add('${item['mes'].toString().padLeft(2, '0')}/${item['ano']}');
//         }
//       });

//       _calcularSaldoSpots();
//     }
//   }

//   Future<void> _loadSaldoPorPeriodo() async {
//     final mes = monthToNumber[selectedMonth];
//     final receitaUrl = Uri.parse(
//         '$_receitasPorMesUrl?id_login=${widget.idLogin}&mes=$mes&ano=$selectedYear');
//     final despesaUrl = Uri.parse(
//         '$_despesasPorMesUrl?id_login=${widget.idLogin}&mes=$mes&ano=$selectedYear');

//     final receitaResponse = await http.get(receitaUrl);
//     final despesaResponse = await http.get(despesaUrl);

//     if (receitaResponse.statusCode == 200 &&
//         despesaResponse.statusCode == 200) {
//       final List<dynamic> receitas =
//           json.decode(utf8.decode(receitaResponse.bodyBytes));
//       final List<dynamic> despesas =
//           json.decode(utf8.decode(despesaResponse.bodyBytes));

//       final totalReceitas = receitas.fold<double>(
//           0.0, (sum, item) => sum + (item['valor'] as num).toDouble());
//       final totalDespesas = despesas.fold<double>(
//           0.0, (sum, item) => sum + (item['valor'] as num).toDouble());

//       setState(() {
//         saldo = totalReceitas - totalDespesas;
//       });
//     } else {
//       print('Erro ao carregar receitas ou despesas');
//     }
//   }

//   void _calcularSaldoSpots() {
//     if (receitaSpots.length != despesaSpots.length) return;

//     saldoSpots = [];
//     for (int i = 0; i < receitaSpots.length; i++) {
//       final double saldo = receitaSpots[i].y - despesaSpots[i].y;
//       saldoSpots.add(FlSpot(i.toDouble(), saldo));
//     }
//   }

//   Future<void> _loadReceitasRecorrencia() async {
//     final url = Uri.parse(
//         '$_receitasRecorrenciaUrl?id_login=${widget.idLogin}&mes=${monthToNumber[selectedMonth]}&ano=$selectedYear');

//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final Map<String, dynamic> data = json.decode(response.body);

//       setState(() {
//         receitasRecorrentes = data['recorrentes'] ?? 0;
//         receitasNaoRecorrentes = data['nao_recorrentes'] ?? 0;
//         final total = receitasRecorrentes + receitasNaoRecorrentes;
//         if (total == 0) {
//           pieSectionsReceitas = [];
//           return;
//         }

//         pieSectionsReceitas = [
//           PieChartSectionData(
//             value: receitasRecorrentes.toDouble(),
//             title: '${(receitasRecorrentes / total * 100).toStringAsFixed(1)}%',
//             color: bluePalette[1],
//             radius: 60,
//             titleStyle: const TextStyle(
//                 fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
//           ),
//           PieChartSectionData(
//             value: receitasNaoRecorrentes.toDouble(),
//             title:
//                 '${(receitasNaoRecorrentes / total * 100).toStringAsFixed(1)}%',
//             color: bluePalette[2],
//             radius: 60,
//             titleStyle: const TextStyle(
//                 fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
//           ),
//         ];
//       });
//     } else {
//       print('Erro ao carregar receitas recorrentes');
//     }
//   }

//   Future<void> _loadDespesasRecorrencia() async {
//     final url = Uri.parse(
//         '$_despesasRecorrenciaUrl?id_login=${widget.idLogin}&mes=${monthToNumber[selectedMonth]}&ano=$selectedYear');

//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final Map<String, dynamic> data = json.decode(response.body);

//       setState(() {
//         despesasRecorrentes = data['recorrentes'] ?? 0;
//         despesasNaoRecorrentes = data['nao_recorrentes'] ?? 0;
//         final total = despesasRecorrentes + despesasNaoRecorrentes;
//         if (total == 0) {
//           pieSectionsDespesas = [];
//           return;
//         }

//         pieSectionsDespesas = [
//           PieChartSectionData(
//             value: despesasRecorrentes.toDouble(),
//             title: '${(despesasRecorrentes / total * 100).toStringAsFixed(1)}%',
//             color: bluePalette[1],
//             radius: 60,
//             titleStyle: const TextStyle(
//                 fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
//           ),
//           PieChartSectionData(
//             value: despesasNaoRecorrentes.toDouble(),
//             title:
//                 '${(despesasNaoRecorrentes / total * 100).toStringAsFixed(1)}%',
//             color: bluePalette[2],
//             radius: 60,
//             titleStyle: const TextStyle(
//                 fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
//           ),
//         ];
//       });
//     } else {
//       print('Erro ao carregar receitas recorrentes');
//     }
//   }

//   Widget _buildBarChart() {
//     return SizedBox(
//       height: 240,
//       child: barGroups.isEmpty
//           ? const Center(child: Text('Nenhum dado disponível'))
//           : BarChart(
//               BarChartData(
//                 alignment: BarChartAlignment.spaceAround,
//                 barGroups: barGroups,
//                 titlesData: FlTitlesData(
//                   bottomTitles: AxisTitles(
//                     axisNameWidget: const Text(
//                       'Dia',
//                       style:
//                           TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//                     ),
//                     axisNameSize: 24,
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       getTitlesWidget: (value, _) => Text('${value.toInt()}'),
//                     ),
//                   ),
//                   leftTitles: AxisTitles(
//                     axisNameWidget: const Text(
//                       'Quantidade',
//                       style:
//                           TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//                     ),
//                     axisNameSize: 28,
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       getTitlesWidget: (value, _) => Text('${value.toInt()}'),
//                     ),
//                   ),
//                   topTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   rightTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 ),
//                 borderData: FlBorderData(show: false),
//                 gridData: FlGridData(show: true),
//               ),
//               swapAnimationDuration: const Duration(milliseconds: 500),
//               swapAnimationCurve: Curves.easeInOut,
//             ),
//     );
//   }

//   Widget _buildPieChart() {
//     return SizedBox(
//       height: 220,
//       child: pieSections.isEmpty
//           ? const Center(child: Text('Nenhum dado disponível'))
//           : PieChart(
//               PieChartData(
//                 sections: pieSections,
//                 sectionsSpace: 2,
//                 centerSpaceRadius: 40,
//               ),
//               swapAnimationDuration: const Duration(milliseconds: 500),
//               swapAnimationCurve: Curves.easeInOut,
//             ),
//     );
//   }

//   Widget _buildDropdown<T>({
//     required String label,
//     required T value,
//     required List<T> items,
//     required ValueChanged<T?> onChanged,
//     required String Function(T) itemBuilder,
//   }) {
//     return Expanded(
//       child: DropdownButtonFormField<T>(
//         value: value,
//         items: items
//             .map((item) => DropdownMenuItem(
//                   value: item,
//                   child: Text(itemBuilder(item)),
//                 ))
//             .toList(),
//         onChanged: onChanged,
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//         ),
//       ),
//     );
//   }

//   Widget _buildComparativoReceitaDespesaChart() {
//     final greenColor = bluePalette[4];
//     final redColor = bluePalette[6];
//     final blueColor = bluePalette[0];

//     if (receitaSpots.isEmpty || despesaSpots.isEmpty) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     final labels =
//         receitaLabels.length == despesaLabels.length ? receitaLabels : [];

//     final allValues =
//         [...receitaSpots, ...despesaSpots, ...saldoSpots].map((e) => e.y);

//     // Encontrar valores mínimos e máximos considerando saldo também
//     final double maxY = allValues.reduce((a, b) => a > b ? a : b);
//     final double minY = allValues.reduce((a, b) => a < b ? a : b);

//     // Define um intervalo visual confortável
//     final double intervalY = ((maxY - minY) / 5).ceilToDouble();

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 12),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               _buildLegendaItem(color: greenColor, label: 'Receitas'),
//               _buildLegendaItem(color: redColor, label: 'Despesas'),
//               _buildLegendaItem(color: blueColor, label: 'Saldo'),
//             ],
//           ),
//         ),
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 12.0),
//           child: SizedBox(
//             height: 250,
//             child: LineChart(
//               LineChartData(
//                 clipData: FlClipData.none(),
//                 minX: 0,
//                 maxX: labels.length > 1 ? labels.length - 0.75 : 0,
//                 minY: minY < 0 ? (minY - intervalY) : 0,
//                 maxY: maxY + intervalY,
//                 titlesData: FlTitlesData(
//                   bottomTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       interval: 1,
//                       getTitlesWidget: (value, _) {
//                         final index = value.toInt();
//                         if (index < 0 || index >= labels.length) {
//                           return const Text('');
//                         }
//                         return Text(labels[index],
//                             style: const TextStyle(fontSize: 10));
//                       },
//                       reservedSize: 32,
//                     ),
//                   ),
//                   leftTitles: AxisTitles(
//                     sideTitles: SideTitles(
//                       showTitles: true,
//                       reservedSize: 60,
//                       interval: intervalY,
//                       getTitlesWidget: (value, _) {
//                         return Text(
//                           value.toInt().toString(),
//                           style: const TextStyle(fontSize: 10),
//                         );
//                       },
//                     ),
//                   ),
//                   rightTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                   topTitles:
//                       AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 ),
//                 lineBarsData: [
//                   LineChartBarData(
//                     spots: receitaSpots,
//                     isCurved: true,
//                     color: greenColor,
//                     barWidth: 3,
//                     dotData: FlDotData(show: true),
//                     belowBarData: BarAreaData(
//                       show: true,
//                       color: greenColor.withOpacity(0.2),
//                     ),
//                   ),
//                   LineChartBarData(
//                     spots: despesaSpots,
//                     isCurved: true,
//                     color: redColor,
//                     barWidth: 3,
//                     dotData: FlDotData(show: true),
//                     belowBarData: BarAreaData(
//                       show: true,
//                       color: redColor.withOpacity(0.2),
//                     ),
//                   ),
//                   LineChartBarData(
//                     spots: saldoSpots,
//                     isCurved: true,
//                     color: blueColor,
//                     barWidth: 3,
//                     dotData: FlDotData(show: true),
//                     belowBarData: BarAreaData(
//                       show: true,
//                       color: blueColor.withOpacity(0.2),
//                     ),
//                   ),
//                 ],
//                 gridData: FlGridData(show: true),
//                 borderData: FlBorderData(show: false),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildLegendaItem({required Color color, required String label}) {
//     return Row(
//       children: [
//         Container(
//           width: 12,
//           height: 12,
//           decoration: BoxDecoration(
//             color: color,
//             shape: BoxShape.circle,
//           ),
//         ),
//         const SizedBox(width: 6),
//         Text(label, style: const TextStyle(fontSize: 12)),
//       ],
//     );
//   }

//   Widget _buildPieReceitasRecorrencia() {
//     if (pieSectionsReceitas.isEmpty) {
//       return const Center(child: Text('Nenhum dado disponível'));
//     }

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Legenda acima
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _buildLegendaItem(color: bluePalette[1], label: 'Recorrentes'),
//               const SizedBox(width: 16),
//               _buildLegendaItem(
//                   color: bluePalette[2], label: 'Não Recorrentes'),
//             ],
//           ),
//         ),
//         // Gráfico de Pizza
//         SizedBox(
//           height: 220,
//           child: PieChart(
//             PieChartData(
//               sections: pieSectionsReceitas,
//               sectionsSpace: 2,
//               centerSpaceRadius: 40,
//             ),
//             swapAnimationDuration: const Duration(milliseconds: 500),
//             swapAnimationCurve: Curves.easeInOut,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildPieDespesasRecorrencia() {
//     if (pieSectionsDespesas.isEmpty) {
//       return const Center(child: Text('Nenhum dado disponível'));
//     }

//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Legenda acima
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8.0),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               _buildLegendaItem(color: bluePalette[1], label: 'Recorrentes'),
//               const SizedBox(width: 16),
//               _buildLegendaItem(
//                   color: bluePalette[2], label: 'Não Recorrentes'),
//             ],
//           ),
//         ),
//         // Gráfico de Pizza
//         SizedBox(
//           height: 220,
//           child: PieChart(
//             PieChartData(
//               sections: pieSectionsDespesas,
//               sectionsSpace: 2,
//               centerSpaceRadius: 40,
//             ),
//             swapAnimationDuration: const Duration(milliseconds: 500),
//             swapAnimationCurve: Curves.easeInOut,
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Dashboard'),
//         centerTitle: true,
//       ),
//       body: Padding(
//           padding: const EdgeInsets.all(16),
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 Card(
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   elevation: 2,
//                   margin: const EdgeInsets.only(bottom: 16),
//                   child: Padding(
//                     padding: const EdgeInsets.all(12),
//                     child: Row(
//                       children: [
//                         _buildDropdown<String>(
//                           label: 'Mês',
//                           value: selectedMonth,
//                           items: monthToNumber.keys.toList(),
//                           onChanged: (value) {
//                             setState(() => selectedMonth = value!);
//                             _setupApi();
//                           },
//                           itemBuilder: (item) => item,
//                         ),
//                         const SizedBox(width: 16),
//                         _buildDropdown<String>(
//                           label: 'Ano',
//                           value: selectedYear,
//                           items: years,
//                           onChanged: (value) {
//                             setState(() => selectedYear = value!);
//                             _setupApi();
//                           },
//                           itemBuilder: (item) => item,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 // Gráfico Despesas por Dia de Vencimento
//                 const Text(
//                   'Despesas por Dia de Vencimento',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 8),
//                 _buildBarChart(),
//                 // Gráfico Despesas por Categoria
//                 const SizedBox(height: 24),
//                 const Text(
//                   'Despesas por Categoria',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 const SizedBox(height: 12),
//                 _buildPieChart(),
//                 // Gráfico Receitas x Despesas
//                 const SizedBox(height: 24),
//                 const Text(
//                   'Receitas x Despesas',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 12),
//                 _buildComparativoReceitaDespesaChart(),
//                 // Gráfico Receitas Recorrentes x Não Recorrentes
//                 const SizedBox(height: 24),
//                 const Text(
//                   'Receitas Recorrentes x Não Recorrentes',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 12),
//                 _buildPieReceitasRecorrencia(),
//                 // Gráfico Despesas Recorrentes x Não Recorrentes
//                 const SizedBox(height: 24),
//                 const Text(
//                   'Despesas Recorrentes x Não Recorrentes',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 12),
//                 _buildPieDespesasRecorrencia()
//               ],
//             ),
//           )),
//     );
//   }
// }
