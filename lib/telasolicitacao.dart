import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:appreds1/apiservice.dart';
import 'package:collection/collection.dart'; // Para firstWhereOrNull

class TelaSolicitacao extends StatefulWidget {
  final String nomeCliente; // Nome inicial do cliente (pode ser vazio ou preenchido)
  final String telefone; // Telefone do cliente (sempre presente e limpo)
  final bool isNewClient; // Indica se é um cliente novo (necessita preencher o nome)

  const TelaSolicitacao({
    super.key,
    required this.nomeCliente,
    required this.telefone,
    required this.isNewClient, required numeroPedido,
  });

  @override
  State<TelaSolicitacao> createState() => TelaSolicitacaoState();
}

class TelaSolicitacaoState extends State<TelaSolicitacao> {
  late final TextEditingController _nomeClienteController;
  final TextEditingController _itemController = TextEditingController();
  final FocusNode _itemFocusNode = FocusNode();
  int _quantidade = 1;
  final Map<String, Map<String, dynamic>> _itensAdicionados = {};

  List<Produto> _produtosFiltrados = [];

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink(); // Mantenha o LayerLink para o CompositedTransformTarget

  String _statusPedido = 'ABERTO';

  @override
  void initState() {
    super.initState();
    _nomeClienteController = TextEditingController(text: widget.nomeCliente);

    _produtosFiltrados = List.from(produtosGlobais);
    _itemController.addListener(_filtrarProdutos);
    _itemFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _itemController.removeListener(_filtrarProdutos);
    _itemFocusNode.removeListener(_onFocusChange);
    _nomeClienteController.dispose();
    _itemController.dispose();
    _itemFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_itemFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_itemFocusNode.hasFocus && _overlayEntry != null) {
          _removeOverlay();
          // Não precisa de setState aqui a menos que queira mudar algo na UI principal
        }
      });
    } else {
      if (_itemController.text.isNotEmpty && _produtosFiltrados.isNotEmpty) {
        _showOverlay();
      }
    }
  }

  void _filtrarProdutos() {
    final String query = _itemController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _produtosFiltrados = List.from(produtosGlobais);
      } else {
        _produtosFiltrados = produtosGlobais
            .where((produto) => produto.nome.toLowerCase().contains(query))
            .toList();
      }
      if (_itemFocusNode.hasFocus && query.isNotEmpty && _produtosFiltrados.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  void _showOverlay() {
    _removeOverlay(); // Remove qualquer overlay existente antes de criar um novo

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        top: position.dy + size.height + 5,
        left: position.dx,
        child: CompositedTransformFollower( // Use CompositedTransformFollower para seguir o target
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 5), // Offset relativo ao target
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _produtosFiltrados.length,
                itemBuilder: (context, index) {
                  final produto = _produtosFiltrados[index];
                  return ListTile(
                    title: Text(produto.nome),
                    subtitle: Text('R\$ ${produto.valor.toStringAsFixed(2)}'),
                    onTap: () {
                      _selecionarProduto(produto);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }


  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selecionarProduto(Produto produto) {
    _itemController.text = produto.nome;
    _itemController.selection = TextSelection.fromPosition(
      TextPosition(offset: _itemController.text.length),
    );
    _removeOverlay();
    _itemFocusNode.unfocus();
  }

  void _adicionarItem() {
    final produtoNome = _itemController.text.trim();
    if (produtoNome.isEmpty || _quantidade <= 0) {
      _mostrarSnackBar('Por favor, preencha o item e a quantidade.',
          isError: true);
      return;
    }

    final Produto? produtoSelecionado = produtosGlobais.firstWhereOrNull(
      (p) => p.nome.toLowerCase() == produtoNome.toLowerCase(),
    );

    if (produtoSelecionado == null) {
      _mostrarSnackBar(
          'Produto não encontrado na lista. Verifique o nome ou selecione da sugestão.',
          isError: true);
      return;
    }

    setState(() {
      if (_itensAdicionados.containsKey(produtoSelecionado.id)) {
        _itensAdicionados[produtoSelecionado.id]!['qtdVenda'] += _quantidade;
        _itensAdicionados[produtoSelecionado.id]!['valorTotalItem'] =
            _itensAdicionados[produtoSelecionado.id]!['qtdVenda'] *
            produtoSelecionado.valor;
      } else {
        _itensAdicionados[produtoSelecionado.id] = {
          'idProduto': produtoSelecionado.id,
          'produto': produtoSelecionado.nome,
          'qtdVenda': _quantidade,
          'valorVenda': produtoSelecionado.valor,
          'valorTotalItem': produtoSelecionado.valor * _quantidade,
        };
      }
      _itemController.clear();
      _quantidade = 1;
      _removeOverlay();
      _itemFocusNode.unfocus();
    });
    _calcularValorTotal();
  }

  void _aumentarQuantidade(String idProduto) {
    setState(() {
      if (_itensAdicionados.containsKey(idProduto)) {
        var item = _itensAdicionados[idProduto]!;
        item['qtdVenda'] += 1;
        item['valorTotalItem'] = item['qtdVenda'] * item['valorVenda'];
      }
    });
    _calcularValorTotal();
  }

  void _diminuirQuantidade(String idProduto) {
    setState(() {
      if (_itensAdicionados.containsKey(idProduto)) {
        var item = _itensAdicionados[idProduto]!;
        if (item['qtdVenda'] > 1) {
          item['qtdVenda'] -= 1;
          item['valorTotalItem'] = item['qtdVenda'] * item['valorVenda'];
        } else {
          _itensAdicionados.remove(idProduto);
        }
      }
    });
    _calcularValorTotal();
  }

  void _removerItem(String idProduto) {
    setState(() {
      _itensAdicionados.remove(idProduto);
    });
    _calcularValorTotal();
  }

  double _calcularValorTotal() {
    double total = 0.0;
    _itensAdicionados.forEach((key, item) {
      total += item['valorTotalItem'];
    });
    return total;
  }

  Future<void> _enviarPedidoParaAPI() async {
    if (_itensAdicionados.isEmpty) {
      _mostrarSnackBar('Adicione pelo menos um item ao pedido.', isError: true);
      return;
    }

    if (widget.isNewClient && _nomeClienteController.text.trim().isEmpty) {
      _mostrarSnackBar('Por favor, preencha o nome do novo cliente.', isError: true);
      return;
    }

    final List<Map<String, dynamic>> itensPayload =
        _itensAdicionados.values.map((item) {
      return {
        "idProduto": item['idProduto'],
        "produto": item['produto'],
        "qtdVenda": item['qtdVenda'],
        "valorVenda": item['valorVenda'],
      };
    }).toList();

    try {
      final sucesso = await ApiService.adicionarPedido(
        nomeCliente: _nomeClienteController.text.trim(),
        telefoneCliente: widget.telefone,
        listaItens: itensPayload,
        observacao: _statusPedido,
      );

      if (sucesso != null) {
        log('TelaSolicitacao - Pedido enviado com sucesso!');
        if (!mounted) return;
        _mostrarSnackBar('Pedido enviado com sucesso!', isError: false);

        Navigator.pushReplacementNamed(
          context,
          '/telaFinal',
          arguments: {
            'nomeCliente': _nomeClienteController.text.trim(),
            'numeroPedido': sucesso['id']?.toString() ?? 'PEDIDO_CONCLUIDO',
            'telefone': widget.telefone,
          },
        );
      } else {
        _mostrarSnackBar('Falha ao enviar pedido. Tente novamente.',
            isError: true);
      }
    } catch (e) {
      _mostrarSnackBar('Erro ao enviar pedido: $e', isError: true);
      log('TelaSolicitacao - Erro ao enviar pedido: $e');
    }
  }

  void _mostrarSnackBar(String mensagem, {bool isError = true}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _mostrarPopupConfirmacao() async {
    if (_itensAdicionados.isEmpty) {
      _mostrarSnackBar('Adicione pelo menos um item ao pedido para confirmar.', isError: true);
      return;
    }
    if (widget.isNewClient && _nomeClienteController.text.trim().isEmpty) {
      _mostrarSnackBar('Por favor, preencha o nome do novo cliente antes de confirmar o pedido.', isError: true);
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmar Pedido"),
          content: Text(
              "Deseja confirmar o pedido para ${_nomeClienteController.text} no valor total de R\$ ${_calcularValorTotal().toStringAsFixed(2)}?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Confirmar"),
              onPressed: () async {
                Navigator.of(context).pop();
                await _enviarPedidoParaAPI();
              },
            ),
          ],
        );
      },
    );
  }

  void _alterarStatusPedido(String novoStatus) async {
    if (_statusPedido == 'PAGO' && novoStatus == 'ABERTO') {
      bool? confirmar = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Confirmar Ação"),
            content: const Text(
                "Tem certeza que deseja mudar o status de 'PAGO' para 'ABERTO'?"),
            actions: <Widget>[
              TextButton(
                child: const Text("Cancelar"),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: const Text("Confirmar"),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );
      if (confirmar ?? false) {
        setState(() {
          _statusPedido = novoStatus;
        });
        _mostrarSnackBar('Status do pedido alterado para $novoStatus.', isError: false);
      }
    } else {
      setState(() {
        _statusPedido = novoStatus;
      });
      _mostrarSnackBar('Status do pedido alterado para $novoStatus.', isError: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color vermelho = Color(0xFFB71C1C);
    final total = _calcularValorTotal();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 138, 11, 2)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "NOVO PEDIDO",
              style: TextStyle(
                color: Color.fromARGB(255, 138, 11, 2),
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Cliente: ${_nomeClienteController.text.isEmpty ? 'Carregando...' : _nomeClienteController.text}",
              style: const TextStyle(
                color: Color.fromARGB(255, 138, 11, 2),
                fontSize: 14,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 138, 11, 2)),
      ),
      backgroundColor: Colors.white,
      body: _buildCorpoPagina(context, vermelho, total),
    );
  }

  Widget _buildCorpoPagina(BuildContext context, Color vermelho, double total) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 145, 12, 12), Colors.red.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: _buildConteudoPagina(context, vermelho, total),
              ),
            ),
            _buildBotaoFinalizarPedido(context, vermelho),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudoPagina(
      BuildContext context, Color vermelho, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Center(
          child: Text(
            "GUIA DE SOLICITAÇÃO",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white),
          ),
        ),
        const SizedBox(height: 20),
        _buildCampoNome(vermelho),
        const SizedBox(height: 10),
        _buildCampoTelefone(vermelho),
        const SizedBox(height: 10),
        _buildSecaoItens(context, vermelho),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total:",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "R\$ ${total.toStringAsFixed(2)}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCampoNome(Color vermelho) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("NOME DO CLIENTE",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 5),
        TextField(
          controller: _nomeClienteController,
          enabled: widget.isNewClient,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: const OutlineInputBorder(),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: widget.isNewClient ? Colors.blue : Colors.grey),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoTelefone(Color vermelho) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("TELEFONE DO CLIENTE",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 5),
        TextField(
          controller: TextEditingController(text: widget.telefone),
          enabled: false,
          style: const TextStyle(color: Colors.black),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecaoItens(BuildContext context, Color vermelho) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ITENS DO PEDIDO",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 5),
        CompositedTransformTarget(
          link: _layerLink,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _itemController,
                  focusNode: _itemFocusNode,
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Adicionar Produto',
                    labelStyle: const TextStyle(color: Colors.black54),
                    filled: true,
                    fillColor: Colors.white,
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildDropdownQuantidade(vermelho),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildBotaoAdicionar(vermelho),
        const SizedBox(height: 10),
        _itensAdicionados.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "Nenhum item adicionado ao pedido.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              )
            : SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _itensAdicionados.length,
                  itemBuilder: (context, index) {
                    final itemKey = _itensAdicionados.keys.elementAt(index);
                    final item = _itensAdicionados[itemKey]!;
                    return Card(
                      color: Colors.white.withOpacity(0.9),
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['produto'],
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Qtd: ${item['qtdVenda']} x R\$ ${item['valorVenda'].toStringAsFixed(2)} = R\$ ${item['valorTotalItem'].toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => _diminuirQuantidade(itemKey),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () => _aumentarQuantidade(itemKey),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.grey),
                              onPressed: () => _removerItem(itemKey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildDropdownQuantidade(Color vermelho) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: vermelho),
        borderRadius: BorderRadius.circular(5),
      ),
      child: DropdownButton<int>(
        value: _quantidade,
        underline: const SizedBox(),
        dropdownColor: Colors.white,
        items: List.generate(10, (index) => index + 1)
            .map((e) => DropdownMenuItem(
                    value: e,
                    child:
                        Text("x$e", style: const TextStyle(color: Color(0xFFB71C1C))),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _quantidade = value ?? 1;
          });
        },
      ),
    );
  }

  Widget _buildBotaoAdicionar(Color vermelho) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _adicionarItem,
        icon: const Icon(Icons.add, color: Color(0xFFB71C1C)),
        label: const Text("ADICIONAR",
            style:
                TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          side: const BorderSide(color: Color(0xFFB71C1C)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildBotaoFinalizarPedido(BuildContext context, Color vermelho) {
    return Center(
      child: ElevatedButton(
        onPressed: _mostrarPopupConfirmacao,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: vermelho,
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          "Finalizar Pedido",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  List<Widget> _buildListaItensAdicionados(Color vermelho) {
    return _itensAdicionados.entries.map((entry) {
      final String idProduto = entry.key;
      final Map<String, dynamic> item = entry.value;

      return Column(
        children: [
          ListTile(
            title: Text(
              item['produto'].toString(),
              style: const TextStyle(
                color: Color(0xFFB71C1C),
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "R\$ ${(item['valorTotalItem'] ?? 0.0).toStringAsFixed(2)}",
              style: const TextStyle(color: Color(0xFFB71C1C)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFB71C1C)),
                  onPressed: () => _diminuirQuantidade(idProduto),
                ),
                Text(
                  item['qtdVenda'].toInt().toString(),
                  style: const TextStyle(
                    color: Color(0xFFB71C1C),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFFB71C1C)),
                  onPressed: () => _aumentarQuantidade(idProduto),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Color(0xFFB71C1C)),
                  onPressed: () => _removerItem(idProduto),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFB71C1C)),
        ],
      );
    }).toList();
  }
}

// Removidas as extensões problemáticas de LayerLink e RenderBox.
// A lógica para obter o posicionamento do overlay foi movida para dentro de _showOverlay
// e usa as propriedades diretas do RenderBox do contexto do widget.