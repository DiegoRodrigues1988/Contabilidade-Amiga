import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart'; // ▼▼▼ CORREÇÃO APLICADA AQUI ▼▼▼

class CaixaEntradaSaidaScreen extends StatefulWidget {
  const CaixaEntradaSaidaScreen({super.key});

  @override
  State<CaixaEntradaSaidaScreen> createState() => _CaixaEntradaSaidaScreenState();
}

class _CaixaEntradaSaidaScreenState extends State<CaixaEntradaSaidaScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // Função para adicionar uma nova transação
  Future<void> _adicionarTransacao(String nome, double valor, String tipo) async {
    if (_currentUser == null) return;
    bool isEntrada = (tipo == 'venda');
    await _firestore.collection('users').doc(_currentUser.uid).collection('transactions').add({
      'nome': nome,
      'valor': valor,
      'tipo': tipo,
      'isEntrada': isEntrada,
      'data': Timestamp.now(),
    });
  }

  // Função para excluir uma transação
  Future<void> _excluirTransacao(String docId) async {
    if (_currentUser == null) return;
    await _firestore
        .collection('users')
        .doc(_currentUser.uid)
        .collection('transactions')
        .doc(docId)
        .delete();
  }

  // Função para mostrar o diálogo de registro
  void _mostrarDialogoRegistro(String tipo) {
    final nomeController = TextEditingController();
    final valorController = TextEditingController();
    String title = '';
    String nomeLabel = 'Nome do Item';

    switch (tipo) {
      case 'venda':
        title = 'Registrar Venda';
        nomeLabel = 'Nome do Produto Vendido';
        break;
      case 'compra':
        title = 'Registrar Compra';
        nomeLabel = 'Nome do Material Comprado';
        break;
      case 'gasto':
        title = 'Registrar Gasto';
        nomeLabel = 'Descrição do Gasto';
        break;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: nomeLabel),
              textCapitalization: TextCapitalization.sentences,
            ),
            TextField(
              controller: valorController,
              decoration: const InputDecoration(labelText: 'Valor (R\$)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: const Text('Salvar'),
            onPressed: () {
              final nome = nomeController.text;
              final valor = double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0.0;

              if (nome.isNotEmpty && valor > 0) {
                _adicionarTransacao(nome, valor, tipo);
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  // Widget para construir a lista de transações
  Widget _buildTransactionsList(Stream<QuerySnapshot> stream) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Nenhuma transação encontrada.'));
        }

        var docs = snapshot.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (ctx, index) {
            var doc = docs[index];
            var transacao = doc.data() as Map<String, dynamic>;
            DateTime data = (transacao['data'] as Timestamp).toDate();
            bool isEntrada = transacao['isEntrada'];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: ListTile(
                leading: Icon(
                  isEntrada ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isEntrada ? Colors.green : Colors.red,
                ),
                title: Text(transacao['nome']),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(data)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'R\$ ${transacao['valor'].toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isEntrada ? Colors.green : Colors.red,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Confirmar Exclusão'),
                            content: const Text('Você tem certeza que deseja excluir esta transação?'),
                            actions: [
                              TextButton(
                                child: const Text('Cancelar'),
                                onPressed: () => Navigator.of(ctx).pop(),
                              ),
                              TextButton(
                                child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                                onPressed: () {
                                  _excluirTransacao(doc.id);
                                  Navigator.of(ctx).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: Text("Erro: Usuário não encontrado.")));
    }

    final transactionsStream = _firestore.collection('users').doc(_currentUser.uid).collection('transactions').orderBy('data', descending: true).snapshots();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Controle Financeiro'),
          backgroundColor: Colors.green[700],
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await GoogleSignIn().signOut();
                await FirebaseAuth.instance.signOut();
              },
            )
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: transactionsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            double totalVendas = 0;
            double totalCompras = 0;
            double totalGastos = 0;

            if (snapshot.hasData) {
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
            }

            final vendasStream = _firestore.collection('users').doc(_currentUser.uid).collection('transactions').where('tipo', isEqualTo: 'venda').orderBy('data', descending: true).snapshots();
            final comprasStream = _firestore.collection('users').doc(_currentUser.uid).collection('transactions').where('tipo', isEqualTo: 'compra').orderBy('data', descending: true).snapshots();
            final gastosStream = _firestore.collection('users').doc(_currentUser.uid).collection('transactions').where('tipo', isEqualTo: 'gasto').orderBy('data', descending: true).snapshots();

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            alignment: WrapAlignment.center,
                            children: [
                              ElevatedButton(onPressed: () => _mostrarDialogoRegistro('venda'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Registrar Venda')),
                              ElevatedButton(onPressed: () => _mostrarDialogoRegistro('compra'), style: ElevatedButton.styleFrom(backgroundColor: Colors.orange), child: const Text('Registrar Compra')),
                              ElevatedButton(onPressed: () => _mostrarDialogoRegistro('gasto'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Registrar Gasto')),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _buildTotalCard('Vendas', totalVendas, Colors.green)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTotalCard('Compras', totalCompras, Colors.orange)),
                              const SizedBox(width: 8),
                              Expanded(child: _buildTotalCard('Gastos', totalGastos, Colors.red)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text('Balanço Visual', style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: (totalVendas == 0 && totalCompras == 0 && totalGastos == 0)
                                ? const Center(child: Text('Nenhum dado para exibir.'))
                                : PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                                sections: [
                                  if (totalVendas > 0) PieChartSectionData(color: Colors.green, value: totalVendas, title: 'Vendas', radius: 60, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                  if (totalCompras > 0) PieChartSectionData(color: Colors.orange, value: totalCompras, title: 'Compras', radius: 60, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                  if (totalGastos > 0) PieChartSectionData(color: Colors.red, value: totalGastos, title: 'Gastos', radius: 60, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('Histórico de Transações', style: Theme.of(context).textTheme.titleLarge),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    delegate: _SliverAppBarDelegate(
                      const TabBar(
                        tabs: [
                          Tab(text: "Vendas"),
                          Tab(text: "Compras"),
                          Tab(text: "Gastos"),
                        ],
                      ),
                    ),
                    pinned: true,
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _buildTransactionsList(vendasStream),
                  _buildTransactionsList(comprasStream),
                  _buildTransactionsList(gastosStream),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTotalCard(String title, double value, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('R\$ ${value.toStringAsFixed(2)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
