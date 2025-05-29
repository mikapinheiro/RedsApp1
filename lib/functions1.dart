import 'package:appreds1/telavalidacao.dart';
import 'package:appreds1/telasolicitacao.dart';
import 'package:appreds1/telavendedor.dart';
import 'package:flutter/material.dart';
import 'package:appreds1/homepage.dart';
import 'package:appreds1/telafinal.dart';
import 'package:appreds1/telapedido.dart'; // Provavelmente não mais usada, mas mantida por enquanto
import 'package:appreds1/apiservice.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.carregarProdutos();

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
              // Certifique-se de que 'numeroPedido' é passado para TelaFinal.
              // Se ele vier como null, ou com outro nome, isso causará o erro.
              // O problema parece estar na CHAMA da rota /telaFinal,
              // que não está passando 'numeroPedido' como esperado pelo construtor de TelaFinal.
              // Por exemplo, na TelaSolicitacao, no _enviarPedidoParaAPI,
              // você passa 'numeroPedido': sucesso['id']?.toString() ?? 'PEDIDO_CONCLUIDO'
              // Se 'numeroPedido' for um campo realmente obrigatório no construtor de TelaFinal,
              // essa linha garante que um valor não nulo seja passado.
              return MaterialPageRoute(
                builder: (context) => TelaFinal(
                  nomeCliente: args['nomeCliente'],
                  numeroPedido: args['numeroPedido'], // Este é o parâmetro que está sendo reclamado
                  telefone: args['telefone'],
                ),
              );
            }
            return _erroDeArgumento('Erro: argumentos inválidos para a rota /telaFinal.');

          case '/telaSolicitacao': // Rota para TelaSolicitacao
            if (args is Map<String, dynamic>) {
              if (args.containsKey('nomeCliente') &&
                  args.containsKey('telefone') &&
                  args.containsKey('isNewClient')) {
                return MaterialPageRoute(
                  builder: (context) => TelaSolicitacao(
                    nomeCliente: args['nomeCliente'],
                    telefone: args['telefone'],
                    isNewClient: args['isNewClient'], numeroPedido: null,
                  ),
                );
              } else {
                return _erroDeArgumento(
                    'Erro: Argumentos incompletos para TelaSolicitacao. Esperado: nomeCliente, telefone, isNewClient.');
              }
            }
            return _erroDeArgumento('Erro: argumentos inválidos para a rota /telaSolicitacao.');

          case '/telaPedido':
            if (args is Map<String, dynamic>) {
              // O parâmetro 'codigo' ou 'telefone' pode ser nulo.
              // Se 'codigo' ou 'telefone' forem nullos, e não são opcionais, eles devem ser tratados.
              // Assumindo que são opcionais, ou que sempre virão.
              return MaterialPageRoute(
                builder: (context) => TelaPedido(
                  codigo: args['codigo'],
                  telefone: args['telefone'],
                ),
              );
            }
            return _erroDeArgumento('Erro: argumentos inválidos para a rota /telaPedido.');

          case '/telaVendedor':
            return MaterialPageRoute(builder: (_) => const TelaVendedor());

          case '/telaValidacao':
            return MaterialPageRoute(builder: (_) => const TelaValidacao());

          default:
            return _erroDeArgumento('Erro: Rota não encontrada ou inválida: ${settings.name}');
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