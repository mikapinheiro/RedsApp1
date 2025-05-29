import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TelaFinal extends StatefulWidget {
  final String nomeCliente;
  final String numeroPedido;
  final String? telefone;

  const TelaFinal({
    super.key,
    required this.nomeCliente,
    required this.numeroPedido,
    this.telefone,
  });

  @override
  State<TelaFinal> createState() => _TelaFinalState();
}

class _TelaFinalState extends State<TelaFinal> {
  final String _serverUrl = 'https://redsapp-1748346206099.azurewebsites.net/reds';
  bool _isLoading = true;
  Map<String, dynamic>? _detalhePedido;
  List<Map<String, dynamic>> _itens = [];
  double _valorTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _carregarDetalhesPedido();
  }

  Future<void> _carregarDetalhesPedido() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/reds/pedido/id/${widget.numeroPedido}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _processarDadosPedido(data);
      } else if (widget.telefone != null) {
        await _buscarPorTelefone();
      } else {
        log("Erro ao carregar detalhes do pedido: ${response.statusCode}");
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      log("Erro ao carregar detalhes do pedido: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _buscarPorTelefone() async {
    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/reds/pedido/${widget.telefone}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['pedidos'] != null && data['pedidos'] is List) {
          final List<dynamic> pedidos = data['pedidos'];
          final pedidoEncontrado = pedidos.firstWhere(
            (pedido) => pedido['id'] == widget.numeroPedido,
            orElse: () => null,
          );

          if (pedidoEncontrado != null) {
            _processarDadosPedido(pedidoEncontrado);
            return;
          }
        }
      }
      log("Pedido não encontrado pelo telefone");
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      log("Erro ao buscar por telefone: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processarDadosPedido(dynamic pedido) {
    if (pedido['listaItens'] != null && pedido['listaItens'] is List) {
      setState(() {
        _detalhePedido = Map<String, dynamic>.from(pedido);
        _itens = List<Map<String, dynamic>>.from(pedido['listaItens']);

        _valorTotal = 0.0;
        for (var item in _itens) {
          _valorTotal +=
              (item['valorVenda'] ?? 0.0) * (item['qtdVenda'] ?? 1.0);
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color vermelho = const Color.fromARGB(255, 184, 26, 14);

    return Scaffold(
      backgroundColor: vermelho,
      body: LayoutBuilder(
        builder: (context, constraints) {
          double screenWidth = constraints.maxWidth;
          double circleSize = screenWidth * 0.55;

          return Stack(
            children: [
              Container(height: 120, color: Colors.white),
              Positioned(
                top: 80,
                left: -circleSize * 0.25,
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    color: vermelho,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 60,
                left: screenWidth - (circleSize * 0.75),
                child: Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: 90,
                left: (screenWidth - 180) / 2,
                child: Image.asset(
                  'assets/EquipeVermelha.png',
                  width: 180,
                  height: 180,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 180,
                      height: 180,
                      color: Colors.white,
                      child: Center(
                        child: Text(
                          "EQUIPE\nVERMELHA",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: vermelho,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 290),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  width: 300,
                  height: 420,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: vermelho))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              widget.nomeCliente.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: vermelho,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'PEDIDO:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: vermelho,
                                  ),
                                ),
                                Text(
                                  '#${widget.numeroPedido}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: vermelho,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'STATUS:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: vermelho,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: vermelho.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _detalhePedido?['statusPedido'] ?? 'ABERTO',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: vermelho,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Divider(color: vermelho),
                            const SizedBox(height: 5),
                            Expanded(
                              child: _itens.isEmpty
                                  ? Center(
                                      child: Text(
                                        'Nenhum item no pedido',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: vermelho,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _itens.length,
                                      itemBuilder: (context, index) {
                                        final item = _itens[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "x${item['qtdVenda']?.toInt() ?? 1} ${item['produto'] ?? 'Item'}",
                                                  style: TextStyle(
                                                    color: vermelho,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                "R\$ ${((item['valorVenda'] ?? 0.0) * (item['qtdVenda'] ?? 1.0)).toStringAsFixed(2)}",
                                                style: TextStyle(
                                                  color: vermelho,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            Divider(color: vermelho),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TOTAL:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: vermelho,
                                  ),
                                ),
                                Text(
                                  'R\$ ${_valorTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: vermelho,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            // Texto no lugar do QR Code
                            Center(
                              child: Text(
                                '@osreds2025',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: vermelho,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.home, color: Colors.white),
                    label: const Text(
                      'VOLTAR AO INÍCIO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
