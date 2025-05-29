import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TelaPedido extends StatefulWidget {
  final String? codigo;
  final String? telefone;

  const TelaPedido({
    super.key,
    this.codigo,
    this.telefone,
  });

  @override
  State<TelaPedido> createState() => _TelaPedidoState();
}

class _TelaPedidoState extends State<TelaPedido> {
final String _serverUrl = 'http://192.168.2.106:8080';

  bool _isLoading = true;
  Map<String, dynamic>? _pedido;
  List<Map<String, dynamic>> _itens = [];

  @override
  void initState() {
    super.initState();
    _carregarPedido();
  }

  Future<void> _carregarPedido() async {
    if (widget.codigo != null) {
      await _buscarPedidoPorId(widget.codigo!);
    } else if (widget.telefone != null) {
      await _buscarUltimoPedidoPorTelefone(widget.telefone!);
    } else {
      _mostrarErro("Nenhum código ou telefone informado.");
    }
  }

  Future<void> _buscarPedidoPorId(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/reds/pedido/id/$id'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _processarPedido(data);
      } else {
        _mostrarErro("Pedido não encontrado (ID)");
      }
    } catch (e) {
      _mostrarErro("Erro ao buscar pedido por ID: $e");
    }
  }

  Future<void> _buscarUltimoPedidoPorTelefone(String telefone) async {
    try { 
      final response = await http.get(
        Uri.parse('$_serverUrl/reds/pedido/$telefone'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['pedidos'] != null && data['pedidos'] is List) {
          final pedidos = data['pedidos'] as List;
          if (pedidos.isNotEmpty) {
            final ultimoPedido = pedidos.last;
            _processarPedido(ultimoPedido);
            return;
          }
        }
        _mostrarErro("Nenhum pedido encontrado para este telefone.");
      } else {
        _mostrarErro("Erro ao buscar por telefone.");
      }
    } catch (e) {
      _mostrarErro("Erro ao buscar pedido: $e");
    }
  }

  void _processarPedido(Map<String, dynamic> pedido) {
    setState(() {
      _pedido = pedido;
      _itens = List<Map<String, dynamic>>.from(pedido['listaItens'] ?? []);
      // ignore: unused_local_variable
      for (var item in _itens) {
      }
      _isLoading = false;
    });
  }

  Future<void> _deletarPedido() async {
    if (_pedido == null || _pedido!['id'] == null) return;

    final id = _pedido!['id'].toString();
    try {
      final response = await http.delete(
        Uri.parse('$_serverUrl/reds/pedido/$id'),
      );
      if (response.statusCode == 200) {
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
                    'VENDA #${_pedido?['id'] ?? '???'}',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _itens.map((item) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "x${item['qtdVenda'] ?? 1} ${item['produto']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: vermelho,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "R\$ ${(item['valorVenda'] * item['qtdVenda']).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: vermelho,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Spacer(),
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
