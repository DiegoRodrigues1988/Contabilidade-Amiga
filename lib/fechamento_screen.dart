import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class FechamentoScreen extends StatefulWidget {
  const FechamentoScreen({super.key});

  @override
  State<FechamentoScreen> createState() => _FechamentoScreenState();
}

class _FechamentoScreenState extends State<FechamentoScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Função para obter o início e o fim da semana atual (Segunda a Domingo)
  Map<String, DateTime> _getWeekRange() {
    DateTime now = DateTime.now();
    // Vai para a segunda-feira da semana atual
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day); // Zera as horas

    // Vai para o domingo da semana atual
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    return {'start': startOfWeek, 'end': endOfWeek};
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text("Erro: Usuário não encontrado.")));
    }

    final weekRange = _getWeekRange();
    final startOfWeek = weekRange['start']!;
    final endOfWeek = weekRange['end']!;

    // Stream que busca as transações apenas da semana atual
    final weeklyTransactionsStream = _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('transactions')
        .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .where('data', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fechamento Semanal'),
        backgroundColor: Colors.blueGrey[700],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: weeklyTransactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma transação registrada esta semana.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            );
          }

          double totalVendas = 0;
          double totalCompras = 0;
          double totalGastos = 0;

          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            switch (data['tipo']) {
              case 'venda':
                totalVendas += data['valor'];
                break;
              case 'compra':
                totalCompras += data['valor'];
                break;
              case 'gasto':
                totalGastos += data['valor'];
                break;
            }
          }

          double balancoFinal = totalVendas - totalCompras - totalGastos;
          Color balancoColor = balancoFinal >= 0 ? Colors.green : Colors.red;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Resumo da Semana',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '${DateFormat('dd/MM').format(startOfWeek)} - ${DateFormat('dd/MM/yyyy').format(endOfWeek)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildSummaryCard('Total de Vendas', totalVendas, Colors.green, Icons.arrow_upward),
                const SizedBox(height: 12),
                _buildSummaryCard('Total de Compras', totalCompras, Colors.orange, Icons.shopping_cart),
                const SizedBox(height: 12),
                _buildSummaryCard('Total de Gastos', totalGastos, Colors.red, Icons.receipt),
                const Divider(height: 32, thickness: 1),
                Card(
                  elevation: 6,
                  color: balancoColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: balancoColor, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          'Balanço Final da Semana',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: balancoColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'R\$ ${balancoFinal.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: balancoColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        trailing: Text(
          'R\$ ${value.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
