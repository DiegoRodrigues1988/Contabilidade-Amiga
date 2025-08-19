import 'package:contabilidade_amiga/caixa_entrada_saida.dart';
import 'package:contabilidade_amiga/configuracoes_screen.dart';
import 'package:contabilidade_amiga/fechamento_screen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Lista de telas que a barra de navegação irá controlar
  static const List<Widget> _widgetOptions = <Widget>[
    CaixaEntradaSaidaScreen(),
    FechamentoScreen(),
    ConfiguracoesScreen(), // ▼▼▼ NOVA TELA ADICIONADA ▼▼▼
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // ▼▼▼ NOVO ITEM ADICIONADO À BARRA DE NAVEGAÇÃO ▼▼▼
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows),
            label: 'Lançamentos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Fechamento',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configurações',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[800],
        onTap: _onItemTapped,
      ),
    );
  }
}
