import 'package:flutter/material.dart';
import 'apiservice.dart'; // Importe sua ApiService global aqui!

class TelaPedido extends StatefulWidget {
  // Removi 'codigo' e 'telefone' como parâmetros para a busca principal,
  // pois a lista 'pedidos' já contém os dados necessários.
  // Mantive 'telefone' apenas para contexto, se você precisar exibi-lo.
  final String? telefone;
  final List<dynamic> pedidos; // Agora recebe a lista completa de pedidos

  const TelaPedido({
    super.key,
    this.telefone,
    required this.pedidos, String? codigo, // Agora é required e será usada
  });

  @override
  State<TelaPedido> createState() => _TelaPedidoState();
}

class _TelaPedidoState extends State<TelaPedido> {
  bool _isLoading = true;
  Map<String, dynamic>? _pedidoAtual; // Alterado para _pedidoAtual para evitar confusão
  List<Map<String, dynamic>> _itens = [];

  @override
  void initState() {
    super.initState();
    _carregarPedidoInicial();
  }

  Future<void> _carregarPedidoInicial() async {
    if (widget.pedidos.isNotEmpty) {
      // Exibe o último pedido da lista recebida
      _processarPedido(widget.pedidos.last);
    } else {
      // Se a lista estiver vazia (o que não deve acontecer se TelaValidacao funcionar como esperado)
      _mostrarErro("Nenhum pedido encontrado para este cliente.");
    }
  }

  void _processarPedido(Map<String, dynamic> pedido) {
    setState(() {
      _pedidoAtual = pedido;
      _itens = List<Map<String, dynamic>>.from(pedido['listaItems'] ?? []); // Corrigido para 'listaItems'
      _isLoading = false;
    });
  }

  Future<void> _deletarPedido() async {
    if (_pedidoAtual == null || _pedidoAtual!['id'] == null) {
      _mostrarMensagem("Nenhum pedido selecionado para cancelar.", isErro: true);
      return;
    }

    final id = _pedidoAtual!['id'].toString();
    try {
      // Usando o ApiService para deletar o pedido
      final sucesso = await ApiService.deletarPedido(id);
      if (sucesso) {
        _mostrarMensagem("Pedido cancelado com sucesso!");
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        _mostrarMensagem("Erro ao cancelar o pedido.", isErro: true);
      }
    } catch (e) {
      _mostrarMensagem("Erro ao cancelar o pedido: $e", isErro: true);
    }
  }

  void _mostrarErro(String mensagem) {
    setState(() => _isLoading = false);
    _mostrarMensagem(mensagem, isErro: true);
  }

  void _mostrarMensagem(String msg, {bool isErro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isErro ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const vermelho = Colors.red;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: vermelho))
          : Column(
              children: [
                const SizedBox(height: 50),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: vermelho),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    // Exibe o ID do pedido atualmente carregado
                    'VENDA #${_pedidoAtual?['id'] ?? '???'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: vermelho,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'ITENS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: vermelho,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded( // Use Expanded para que a lista de itens não transborde
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: ListView.builder(
                      itemCount: _itens.length,
                      itemBuilder: (context, index) {
                        final item = _itens[index];
                        final valor = (item['valorVenda'] ?? 0).toDouble();
                        final qtd = (item['qtdVenda'] ?? 1).toDouble();
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "x${qtd.toInt()} ${item['produto']}", // Convertido para int se for quantidade inteira
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: vermelho,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                "R\$ ${(valor * qtd).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: vermelho,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const Spacer(), // Mantém o espaçamento flexível
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(60),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 40, horizontal: 30),
                    color: const Color(0xFFB71C1C),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // Ação para "JÁ VENDI" - assume que apenas volta
                              Navigator.popUntil(context, (route) => route.isFirst);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: vermelho,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('JÁ VENDI'),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: _deletarPedido,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                  color: Colors.white, width: 2),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('NÃO QUERO MAIS'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}