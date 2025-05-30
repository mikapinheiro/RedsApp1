// telasolicitacao.dart
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:appreds1/apiservice.dart';
import 'package:appreds1/telafinal.dart';
import 'package:collection/collection.dart'; // Adicione esta importação

class TelaSolicitacao extends StatefulWidget {
  final String nomeCliente;
  final String telefone;
  // Removi 'numeroPedido' e 'isNewClient' do construtor
  // se esta tela for APENAS para criar novos pedidos.
  // Se for para edição, precisamos discutir como ela deve carregar dados.
  // Por enquanto, vou assumir que é para CRIAR NOVO PEDIDO.
  // Se 'numeroPedido' e 'isNewClient' forem realmente necessários, me avise.

  const TelaSolicitacao({
    super.key,
    required this.nomeCliente,
    required this.telefone,
    // Removendo: required this.numeroPedido, required bool isNewClient,
  });

  @override
  State<TelaSolicitacao> createState() => TelaSolicitacaoState();
}

class TelaSolicitacaoState extends State<TelaSolicitacao> {
  final TextEditingController _itemController = TextEditingController();
  final FocusNode _itemFocusNode = FocusNode();
  int _quantidade = 1;
  // Alterado para Map<String, Map<String, dynamic>> para facilitar a atualização por ID
  final Map<String, Map<String, dynamic>> _itensAdicionados = {};

  List<Produto> _produtosFiltrados = [];

  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  String _statusPedido = 'ABERTO'; // Valor inicial do status

  @override
  void initState() {
    super.initState();
    // Use produtosGlobais que já deve ser carregado no main.dart
    _produtosFiltrados = List.from(produtosGlobais);
    _itemController.addListener(_filtrarProdutos);
    _itemFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _removeOverlay();
    _itemController.removeListener(_filtrarProdutos);
    _itemFocusNode.removeListener(_onFocusChange);
    _itemController.dispose();
    _itemFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_itemFocusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_itemFocusNode.hasFocus && _overlayEntry != null) {
          _removeOverlay();
          setState(() {
            _showSuggestions = false;
          });
        }
      });
    } else {
      if (_itemController.text.isNotEmpty && _produtosFiltrados.isNotEmpty) {
        _showOverlay();
        setState(() {
          _showSuggestions = true;
        });
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
      if (_itemFocusNode.hasFocus &&
          query.isNotEmpty &&
          _produtosFiltrados.isNotEmpty) {
        _showOverlay();
        _showSuggestions = true;
      } else {
        _removeOverlay();
        _showSuggestions = false;
      }
    });
  }

  void _showOverlay() {
    _removeOverlay();

    final BuildContext? overlayContext = _layerLink.currentContext;

    if (overlayContext == null) {
      return;
    }

    final RenderBox? renderBox = overlayContext.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      return;
    }

    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width, // Ajusta a largura para ser a mesma do TextField
        top: position.dy + size.height + 5, // 5 pixels abaixo do TextField
        left: position.dx, // Mesma posição horizontal do TextField
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
      _quantidade = 1; // Reseta a quantidade para 1 após adicionar
      _removeOverlay();
      _showSuggestions = false;
      _itemFocusNode.unfocus();
    });
    _calcularValorTotal(); // Recalcula o total
  }

  // Função para aumentar a quantidade de um item existente
  void _aumentarQuantidade(String idProduto) {
    setState(() {
      if (_itensAdicionados.containsKey(idProduto)) {
        var item = _itensAdicionados[idProduto]!;
        item['qtdVenda'] += 1;
        item['valorTotalItem'] = item['qtdVenda'] * item['valorVenda'];
      }
    });
    _calcularValorTotal(); // Recalcula o total
  }

  // Função para diminuir a quantidade de um item existente
  void _diminuirQuantidade(String idProduto) {
    setState(() {
      if (_itensAdicionados.containsKey(idProduto)) {
        var item = _itensAdicionados[idProduto]!;
        if (item['qtdVenda'] > 1) {
          item['qtdVenda'] -= 1;
          item['valorTotalItem'] = item['qtdVenda'] * item['valorVenda'];
        } else {
          // Se a quantidade for 1, remove o item
          _itensAdicionados.remove(idProduto);
        }
      }
    });
    _calcularValorTotal(); // Recalcula o total
  }

  void _removerItem(String idProduto) {
    setState(() {
      _itensAdicionados.remove(idProduto);
    });
    _calcularValorTotal(); // Recalcula o total
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

    final List<Map<String, dynamic>> listaItensPayload =
        _itensAdicionados.values.map((item) {
      return {
        "idProduto": item['idProduto'],
        "produto": item['produto'],
        "quantidade": item['qtdVenda'],
        "valorUnitario": item['valorVenda'],
      };
    }).toList();

    // Removido o pedidoPayload completo para se adequar à nova assinatura
    // Agora passamos os campos nomeados diretamente para ApiService.adicionarPedido
    try {
      final Map<String, dynamic>? resultado = await ApiService.adicionarPedido(
        nomeCliente: widget.nomeCliente,
        telefoneCliente: widget.telefone,
        listaItens: listaItensPayload,
        // Opcionais: observacao e idPedido, se você tiver campos para isso
        // observacao: _observacaoController.text,
        // idPedido: widget.numeroPedido, // Se for para edição/atualização
      );

      if (resultado != null) {
        log('Pedido enviado com sucesso! ID: ${resultado['id']}');
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          '/telaFinal',
          arguments: {
            'nomeCliente': widget.nomeCliente,
            'numeroPedido': resultado['id'].toString(), // Use o ID real retornado pela API
            'telefone': widget.telefone,
          },
        );
      } else {
        _mostrarSnackBar('Falha ao enviar pedido. Tente novamente.',
            isError: true);
      }
    } catch (e) {
      _mostrarSnackBar('Erro ao enviar pedido: $e', isError: true);
      log('Erro ao enviar pedido: $e');
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
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmar Pedido"),
          content: Text(
              "Deseja confirmar o pedido para ${widget.nomeCliente} no valor total de R\$ ${_calcularValorTotal().toStringAsFixed(2)}?"),
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
      if (confirmar == true) {
        setState(() {
          _statusPedido = novoStatus;
        });
      }
    } else {
      setState(() {
        _statusPedido = novoStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color vermelho = Color(0xFFB71C1C);
    final total = _calcularValorTotal();

    return Scaffold(
      appBar: AppBar(
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
              "Cliente: ${widget.nomeCliente}",
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
          color: Colors.white,
          border: Border.all(color: vermelho, width: 2),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
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
            _buildBotaoCadastrar(context, vermelho),
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
                color: Color(0xFFB71C1C)),
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
                color: vermelho,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "R\$ ${total.toStringAsFixed(2)}",
              style: TextStyle(
                color: vermelho,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildStatusButtons(vermelho),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildStatusButtons(Color vermelho) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _alterarStatusPedido('ABERTO'),
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  _statusPedido == 'ABERTO' ? Colors.green : Colors.grey[300],
              side: BorderSide(
                  color: _statusPedido == 'ABERTO' ? Colors.green : Colors.grey),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "ABERTO",
              style: TextStyle(
                color: _statusPedido == 'ABERTO' ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _alterarStatusPedido('PAGO'),
            style: OutlinedButton.styleFrom(
              backgroundColor:
                  _statusPedido == 'PAGO' ? Colors.green : Colors.grey[300],
              side: BorderSide(
                  color: _statusPedido == 'PAGO' ? Colors.green : Colors.grey),
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "PAGO",
              style: TextStyle(
                color: _statusPedido == 'PAGO' ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoNome(Color vermelho) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("NOME",
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
        const SizedBox(height: 5),
        TextField(
          enabled: false,
          controller: TextEditingController(text: widget.nomeCliente),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB71C1C)),
            ),
          ),
          style: const TextStyle(color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildCampoTelefone(Color vermelho) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("TELEFONE",
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
        const SizedBox(height: 5),
        TextField(
          enabled: false,
          controller: TextEditingController(text: widget.telefone),
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB71C1C)),
            ),
          ),
          style: const TextStyle(color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildSecaoItens(BuildContext context, Color vermelho) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ITENS",
            style:
                TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
        const SizedBox(height: 5),
        CompositedTransformTarget(
          link: _layerLink,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _itemController,
                  focusNode: _itemFocusNode,
                  cursorColor: vermelho,
                  decoration: const InputDecoration(
                    hintText: "Digite o item",
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB71C1C)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB71C1C), width: 2),
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
                child: Text(
                  "Nenhum item adicionado ainda.",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : Column(
                children: _buildListaItensAdicionados(vermelho),
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

  List<Widget> _buildListaItensAdicionados(Color vermelho) {
    return _itensAdicionados.entries.map((entry) {
      final String idProduto = entry.key;
      final Map<String, dynamic> item = entry.value;

      return Column(
        children: [
          ListTile(
            title: Text(
              // Remover "x${item['qtdVenda'].toInt()}" daqui, pois a quantidade será controlada pelos botões
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
              mainAxisSize: MainAxisSize.min, // Ocupa o mínimo de espaço necessário
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFB71C1C)),
                  onPressed: () => _diminuirQuantidade(idProduto),
                ),
                Text(
                  item['qtdVenda'].toInt().toString(), // Exibe a quantidade atual
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
                const SizedBox(width: 8), // Espaçamento entre os botões de quantidade e a lixeira
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

  Widget _buildBotaoCadastrar(BuildContext context, Color vermelho) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _mostrarPopupConfirmacao,
        style: OutlinedButton.styleFrom(
          backgroundColor: vermelho,
          side: BorderSide(color: vermelho),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text(
          "ENVIAR PEDIDO",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// Extensões para compatibilidade com o código original (firstWhereOrNull e LayerLink)
extension on LayerLink {
  BuildContext? get currentContext {
    try {
      RenderObject? attached; // Isso não parece ser usado ou inicializado corretamente
      final RenderObject? renderObject = attached; // renderObject será sempre null aqui
      if (renderObject != null && renderObject.debugNeedsPaint) {
        // Esta condição nunca será verdadeira
        return (renderObject as RenderBox).context;
      }
    } catch (e) {
      log('Erro ao obter currentContext do LayerLink: $e');
    }
    return null;
  }
}

extension on RenderBox {
  BuildContext? get context => null; // Isso sempre retornará null
}