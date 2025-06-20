import 'package:appreds1/telavalidacao.dart';
import 'package:appreds1/telasolicitacao.dart';
import 'package:appreds1/telavendedor.dart';
import 'package:flutter/material.dart';
import 'package:appreds1/homepage.dart';
import 'package:appreds1/telafinal.dart';
import 'package:appreds1/telapedido.dart';
import 'package:appreds1/apiservice.dart' as api; // Este é o seu ApiService principal e global

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await api.ApiService.carregarProdutos(); // Agora o Dart saberá qual ApiService usar

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Reds',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const Homepage(),
      onGenerateRoute: (settings) {
        final args = settings.arguments;

        switch (settings.name) {
          case '/telaFinal':
            if (args is Map<String, dynamic>) {
              return MaterialPageRoute(
                builder: (context) => TelaFinal(
                  nomeCliente: args['nomeCliente'],
                  numeroPedido: args['numeroPedido'],
                  telefone: args['telefone'],
                  isNewClient: args['isNewClient'] ?? false,
                ),
              );
            }
            return _erroDeArgumento();

          case '/telaSolicitacao':
            if (args is Map<String, dynamic>) {
              if (args.containsKey('nomeCliente') &&
                  args.containsKey('telefone') &&
                  args.containsKey('isNewClient')) {
                return MaterialPageRoute(
                  builder: (context) => TelaSolicitacao(
                    nomeCliente: args['nomeCliente'],
                    telefone: args['telefone'],
                    isNewClient: args['isNewClient'],
                    numeroPedido: '',
                  ),
                );
              } else {
                return _erroDeArgumento(
                  'Erro: Argumentos incompletos para TelaSolicitacao. Esperado: nomeCliente, telefone, isNewClient.',
                );
              }
            }
            return _erroDeArgumento();

          case '/telaPedido':
            if (args is Map<String, dynamic>) {
              final String? telefone = args['telefone'] as String?;
              final List<dynamic>? pedidosList = (args['pedidos'] as List<dynamic>?);

              if (telefone == null || pedidosList == null) {
                return _erroDeArgumento('Erro: Argumentos "telefone" ou "pedidos" estão faltando ou são nulos para TelaPedido.');
              }

              return MaterialPageRoute(
                builder: (context) => TelaPedido(
                  telefone: telefone,
                  pedidos: pedidosList,
                ),
              );
            }
            return _erroDeArgumento();

          case '/telaVendedor':
            return MaterialPageRoute(builder: (_) => const TelaVendedor());

          case '/telaValidacao':
            return MaterialPageRoute(builder: (_) => const TelaValidacao());

          default:
            return null;
        }
      },
    );
  }

  MaterialPageRoute _erroDeArgumento([String mensagem = 'Erro: argumentos inválidos para a rota.']) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Erro', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              mensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}