import 'dart:convert';
import 'dart:developer'; // Para logs
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TelaFinal extends StatefulWidget {
  final String nomeCliente;
  final String numeroPedido;
  final String? telefone;
  final bool isNewClient;

  const TelaFinal({
    super.key,
    required this.nomeCliente,
    required this.numeroPedido,
    this.telefone,
    required this.isNewClient,
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
      final responseById = await http.get(
        Uri.parse('$_serverUrl/pedido/id/${widget.numeroPedido}'),
      );

      if (responseById.statusCode == 200) {
        final data = jsonDecode(responseById.body);
        _processarDadosPedido(data);
      } else {
        log("Falha ao carregar detalhes do pedido por ID ${widget.numeroPedido}: ${responseById.statusCode} - ${responseById.body}");
        if (widget.telefone != null && !widget.isNewClient) {
          log("Tentando buscar pedido por telefone como fallback...");
          await _buscarPorTelefone();
        } else {
          log("Não foi possível carregar o pedido. ID não encontrado e/ou telefone não disponível/cliente novo.");
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao carregar os detalhes do pedido: ${responseById.statusCode}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      log("Erro de rede/parsing ao carregar detalhes do pedido: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro de conexão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _buscarPorTelefone() async {
    if (widget.telefone == null) {
      log("Telefone não fornecido para busca por telefone.");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('$_serverUrl/pedido/${widget.telefone}'),
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
      log("Pedido com ID ${widget.numeroPedido} não encontrado pelo telefone ${widget.telefone}. Status: ${response.statusCode}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível encontrar o pedido pelo telefone.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      log("Erro ao buscar por telefone: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na busca por telefone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _processarDadosPedido(dynamic pedido) {
    if (mounted) {
      setState(() {
        _detalhePedido = Map<String, dynamic>.from(pedido);
        if (pedido['listaItens'] != null && pedido['listaItens'] is List) {
          _itens = List<Map<String, dynamic>>.from(pedido['listaItens']);
          _valorTotal = 0.0;
          for (var item in _itens) {
            _valorTotal +=
                (item['valorVenda'] ?? 0.0) * (item['qtdVenda']?.toDouble() ?? 0.0);
          }
        } else {
          _itens = [];
          _valorTotal = 0.0;
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color vermelho = const Color.fromARGB(255, 184, 26, 14);

    String numeroPedidoCurto = widget.numeroPedido.length > 6
        ? widget.numeroPedido.substring(0, 6)
        : widget.numeroPedido;

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
                  height: 380,
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
                                  '#$numeroPedidoCurto',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: vermelho,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Divider(color: vermelho),
                            const Spacer(flex: 5), // Aumentado de flex: 2 para flex: 3
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Mundo SENAI 2025',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: vermelho,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            // Damos o espaço restante para a lista de itens e o Spacer final
                            Expanded(
                              flex: 5,
                              child: ListView.builder(
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
                                          "R\$ ${((item['valorVenda'] ?? 0.0) * (item['qtdVenda']?.toDouble() ?? 0.0)).toStringAsFixed(2)}",
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
                            const Spacer(flex: 2),
                            TextButton.icon(
                              icon: Icon(Icons.home, color: vermelho),
                              label: Text(
                                'VOLTAR AO INÍCIO',
                                style: TextStyle(
                                  color: vermelho,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                            ),
                          ],
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