import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isDeleting = false;
  bool _isGeneratingPdf = false;

  // Função para limpar todos os dados do usuário
  Future<void> _limparTodosOsDados() async {
    if (_currentUser == null) return;

    // Diálogo de confirmação
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atenção!'),
        content: const Text(
            'Esta ação é irreversível e apagará TODAS as suas vendas, compras e gastos. Deseja continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim, Limpar Tudo', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() { _isDeleting = true; });
      try {
        final collectionRef = FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .collection('transactions');

        final snapshot = await collectionRef.get();

        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Todos os dados foram limpos com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao limpar os dados: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) { setState(() { _isDeleting = false; }); }
      }
    }
  }

  // Função para gerar o relatório em PDF
  Future<void> _gerarPdf() async {
    if (_currentUser == null) return;
    setState(() { _isGeneratingPdf = true; });

    try {
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('transactions')
          .orderBy('data', descending: false)
          .get();

      final pdf = pw.Document();

      double totalVendas = 0;
      double totalCompras = 0;
      double totalGastos = 0;
      List<pw.TableRow> rows = [];

      // Cabeçalho da tabela
      rows.add(pw.TableRow(children: [
        pw.Text('Data', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Descrição', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Tipo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Text('Valor (R\$)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ]));

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final tipo = data['tipo'];
        final valor = data['valor'];

        switch (tipo) {
          case 'venda': totalVendas += valor; break;
          case 'compra': totalCompras += valor; break;
          case 'gasto': totalGastos += valor; break;
        }

        rows.add(pw.TableRow(children: [
          pw.Text(DateFormat('dd/MM/yy').format((data['data'] as Timestamp).toDate())),
          pw.Text(data['nome']),
          pw.Text(tipo.toString().replaceFirst(tipo[0], tipo[0].toUpperCase())),
          pw.Text(valor.toStringAsFixed(2), textAlign: pw.TextAlign.right),
        ]));
      }

      final balanco = totalVendas - totalCompras - totalGastos;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (context) => [
            pw.Header(
              level: 0,
              child: pw.Text('Relatório Financeiro - Contabilidade Amiga', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text('Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total de Vendas: R\$ ${totalVendas.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.green)),
                pw.Text('Total de Compras: R\$ ${totalCompras.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.orange)),
                pw.Text('Total de Gastos: R\$ ${totalGastos.toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.red)),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text('Balanço Final: R\$ ${balanco.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: balanco >= 0 ? PdfColors.blue : PdfColors.red)),
            ),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Histórico de Transações')),
            pw.Table(
              border: pw.TableBorder.all(),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: rows,
            ),
          ],
        ),
      );

      // Salvar e abrir o arquivo
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/relatorio_financeiro.pdf");
      await file.writeAsBytes(await pdf.save());

      OpenFile.open(file.path);

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar PDF: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) { setState(() { _isGeneratingPdf = false; }); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações e Relatórios'),
        backgroundColor: Colors.blueGrey[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                title: const Text('Gerar Relatório PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Cria um resumo completo de todas as suas transações.'),
                onTap: _isGeneratingPdf ? null : _gerarPdf,
                trailing: _isGeneratingPdf ? const CircularProgressIndicator() : const Icon(Icons.arrow_forward_ios),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.red[50],
              child: ListTile(
                leading: Icon(Icons.warning_amber, color: Colors.red[700], size: 40),
                title: Text('Limpar Todos os Dados', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[900])),
                subtitle: const Text('Apaga permanentemente todos os registros. Use com cuidado.'),
                onTap: _isDeleting ? null : _limparTodosOsDados,
                trailing: _isDeleting ? const CircularProgressIndicator() : Icon(Icons.delete_forever, color: Colors.red[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
