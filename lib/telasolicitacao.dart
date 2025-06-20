import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:appreds1/apiservice.dart'; // Ajuste o caminho se necessário
import 'package:appreds1/telafinal.dart'; // Ajuste o caminho se necessário
import 'package:collection/collection.dart'; // Importação correta para firstWhereOrNull

class TelaSolicitacao extends StatefulWidget {
  final String nomeCliente;
  final String telefone;
  final bool isNewClient;
  final String? numeroPedido; // Pode ser nulo se for um novo pedido

  const TelaSolicitacao({
    super.key,
    required this.nomeCliente,
    required this.telefone,
    required this.isNewClient,
    this.numeroPedido, // numeroPedido agora pode ser nulo
  });

  @override
  State<TelaSolicitacao> createState() => TelaSolicitacaoState();
}

class TelaSolicitacaoState extends State<TelaSolicitacao> {
  final TextEditingController _itemController = TextEditingController();
  final FocusNode _itemFocusNode = FocusNode();
  int _quantidade = 1;
  // Mapa para armazenar os itens adicionados: {idProduto: {detalhes do item}}
  final Map<String, Map<String, dynamic>> _itensAdicionados = {};

  List<Produto> _produtosFiltrados = []; // Lista para as sugestões do autocomplete

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink(); // Necessário para posicionar o Overlay

  String _statusPedido = 'ABERTO'; // Valor inicial do status

  final TextEditingController _nomeClienteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Preenche o campo de nome do cliente com o valor recebido
    _nomeClienteController.text = widget.nomeCliente;

    // Carrega produtos se a lista global estiver vazia.
    // É crucial que `produtosGlobais` esteja populado para o autocomplete funcionar.
    if (produtosGlobais.isEmpty) {
      log('TelaSolicitacao - produtosGlobais está vazio. Tentando carregar...');
      ApiService.carregarProdutos().then((_) {
        setState(() {
          _produtosFiltrados = List.from(produtosGlobais); // Inicializa com todos os produtos
        });
      }).catchError((e) {
        log('TelaSolicitacao - Erro ao carregar produtos: $e');
        _mostrarSnackBar('Erro ao carregar produtos. Tente novamente mais tarde.', isError: true);
      });
    } else {
      _produtosFiltrados = List.from(produtosGlobais); // Se já carregado, usa a lista global
    }

    // Adiciona listeners para o campo de texto e foco para gerenciar o autocomplete
    _itemController.addListener(_filtrarProdutos);
    _itemFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _removeOverlay(); // Garante que o overlay é removido ao sair da tela
    _itemController.removeListener(_filtrarProdutos);
    _itemFocusNode.removeListener(_onFocusChange);
    _itemController.dispose();
    _itemFocusNode.dispose();
    _nomeClienteController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Adiciona um pequeno atraso para permitir que o clique no ListTile da sugestão seja processado
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!_itemFocusNode.hasFocus && _overlayEntry != null) {
        _removeOverlay(); // Remove o overlay se o campo perde o foco
      } else if (_itemFocusNode.hasFocus && _itemController.text.isNotEmpty && _produtosFiltrados.isNotEmpty) {
        _showOverlay(); // Mostra o overlay se o campo tem foco, texto e há sugestões
      }
    });
  }

  void _filtrarProdutos() {
    final String query = _itemController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _produtosFiltrados = List.from(produtosGlobais); // Mostra todos se a busca está vazia
      } else {
        _produtosFiltrados = produtosGlobais
            .where((produto) => produto.nome.toLowerCase().contains(query))
            .toList();
      }
      // Gerencia a visibilidade do overlay após filtrar
      if (_itemFocusNode.hasFocus && query.isNotEmpty && _produtosFiltrados.isNotEmpty) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  void _showOverlay() {
    _removeOverlay(); // Remove qualquer overlay existente antes de mostrar um novo

    // Obtém o RenderBox do CompositedTransformTarget para posicionar o overlay corretamente
    final RenderBox? renderBox = _layerLink.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      log('RenderBox is null for overlay. Cannot show overlay.');
      return;
    }

    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        top: position.dy + size.height + 5, // Posição vertical: abaixo do TextField + 5px
        left: position.dx, // Posição horizontal: alinhado com o TextField
        child: Material(
          elevation: 4.0,
          borderRadius: BorderRadius.circular(8.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200), // Altura máxima para a lista de sugestões
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true, // Importante para que a ListView ocupe apenas o espaço necessário
              itemCount: _produtosFiltrados.length,
              itemBuilder: (context, index) {
                final produto = _produtosFiltrados[index];
                return ListTile(
                  title: Text(produto.nome),
                  subtitle: Text('R\$ ${produto.valor.toStringAsFixed(2)}'),
                  onTap: () {
                    _selecionarProduto(produto); // Ao tocar, seleciona o produto
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
    // Verifica se o widget ainda está montado antes de inserir o overlay
    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove(); // Remove o overlay se ele existe
    _overlayEntry = null; // Zera a referência
  }

  void _selecionarProduto(Produto produto) {
    _itemController.text = produto.nome; // Preenche o campo de texto com o nome do produto
    // Move o cursor para o final do texto
    _itemController.selection = TextSelection.fromPosition(
      TextPosition(offset: _itemController.text.length),
    );
    _removeOverlay(); // Remove as sugestões
    _itemFocusNode.unfocus(); // Tira o foco do campo de texto
  }

  void _adicionarItem() {
    final produtoNome = _itemController.text.trim();
    if (produtoNome.isEmpty || _quantidade <= 0) {
      _mostrarSnackBar('Por favor, preencha o item e a quantidade.', isError: true);
      return;
    }

    // Procura o produto na lista global de produtos (case-insensitive)
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
      // Se o item já foi adicionado, atualiza a quantidade e o valor total
      if (_itensAdicionados.containsKey(produtoSelecionado.id)) {
        _itensAdicionados[produtoSelecionado.id]!['qtdVenda'] += _quantidade;
        _itensAdicionados[produtoSelecionado.id]!['valorTotalItem'] =
            _itensAdicionados[produtoSelecionado.id]!['qtdVenda'] *
            produtoSelecionado.valor;
      } else {
        // Se é um novo item, adiciona-o ao mapa
        _itensAdicionados[produtoSelecionado.id] = {
          'idProduto': produtoSelecionado.id,
          'produto': produtoSelecionado.nome,
          'qtdVenda': _quantidade,
          'valorVenda': produtoSelecionado.valor, // Valor unitário para controle interno
          'valorTotalItem': produtoSelecionado.valor * _quantidade, // Valor total do item
        };
      }
      _itemController.clear(); // Limpa o campo de texto
      _quantidade = 1; // Reseta a quantidade para 1
      _itemFocusNode.unfocus(); // Tira o foco do campo de texto
    });
    _calcularValorTotal(); // Recalcula o total após adicionar item
  }

  void _aumentarQuantidade(String idProduto) {
    setState(() {
      if (_itensAdicionados.containsKey(idProduto)) {
        var item = _itensAdicionados[idProduto]!;
        item['qtdVenda'] += 1;
        item['valorTotalItem'] = item['qtdVenda'] * item['valorVenda'];
      }
    });
    _calcularValorTotal(); // Recalcula o total após aumentar quantidade
  }

  void _diminuirQuantidade(String idProduto) {
    setState(() {
      if (_itensAdicionados.containsKey(idProduto)) {
        var item = _itensAdicionados[idProduto]!;
        if (item['qtdVenda'] > 1) {
          item['qtdVenda'] -= 1;
          item['valorTotalItem'] = item['qtdVenda'] * item['valorVenda'];
        } else {
          // Se a quantidade chega a 0, remove o item
          _itensAdicionados.remove(idProduto);
        }
      }
    });
    _calcularValorTotal(); // Recalcula o total após diminuir quantidade
  }

  void _removerItem(String idProduto) {
    setState(() {
      _itensAdicionados.remove(idProduto);
    });
    _calcularValorTotal(); // Recalcula o total após remover item
  }

  double _calcularValorTotal() {
    double total = 0.0;
    _itensAdicionados.forEach((key, item) {
      total += item['valorTotalItem']; // Soma o valor total de cada item
    });
    return total;
  }

  Future<void> _enviarPedidoParaAPI() async {
    if (_itensAdicionados.isEmpty) {
      _mostrarSnackBar('Adicione pelo menos um item ao pedido.', isError: true);
      return;
    }

    // Se for um novo cliente, o nome não pode estar vazio
    if (widget.isNewClient && _nomeClienteController.text.trim().isEmpty) {
      _mostrarSnackBar('Por favor, preencha o nome do novo cliente.', isError: true);
      return;
    }

    // CONSTRUÇÃO DO PAYLOAD PARA A API
    final List<Map<String, dynamic>> listaItensPayload =
        _itensAdicionados.values.map((item) {
      return {
        "idProduto": item['idProduto'],
        "produto": item['produto'],
        "qtdVenda": item['qtdVenda'],
        // CORREÇÃO AQUI: Passar o valor total do item para 'valorVenda' na API
        "valorVenda": item['valorTotalItem'],
      };
    }).toList();

    log('Payload do Pedido FINAL: ${json.encode({
      'nomeCliente': _nomeClienteController.text,
      'telefoneCliente': widget.telefone,
      'listaItens': listaItensPayload,
      'status': _statusPedido,
    })}');

    try {
      final Map<String, dynamic>? resultado = await ApiService.adicionarPedido(
        nomeCliente: _nomeClienteController.text,
        telefoneCliente: widget.telefone,
        listaItens: listaItensPayload,
        status: _statusPedido,
      );

      if (resultado != null && resultado.containsKey('id')) {
        log('Pedido enviado com sucesso! ID: ${resultado['id']}');
        if (!mounted) return; // Verifica se o widget ainda está montado

        // Navega para a TelaFinal após o sucesso
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TelaFinal(
              nomeCliente: _nomeClienteController.text,
              numeroPedido: resultado['id'].toString(),
              telefone: widget.telefone,
              isNewClient: widget.isNewClient,
            ),
          ),
        );
      } else {
        log('Falha ao enviar pedido. Resultado da API: $resultado');
        _mostrarSnackBar('Falha ao enviar pedido. Tente novamente.', isError: true);
      }
    } catch (e) {
      _mostrarSnackBar('Erro ao enviar pedido: $e', isError: true);
      log('Erro ao enviar pedido: $e');
    }
  }

  void _mostrarSnackBar(String mensagem, {bool isError = true}) {
    if (!mounted) return; // Impede erro se o widget não estiver mais na árvore

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  void _mostrarPopupConfirmacao() async {
    if (!mounted) return;

    if (_itensAdicionados.isEmpty) {
      _mostrarSnackBar('Adicione pelo menos um item ao pedido antes de confirmar.', isError: true);
      return;
    }

    if (widget.isNewClient && _nomeClienteController.text.trim().isEmpty) {
      _mostrarSnackBar('Por favor, preencha o nome do novo cliente antes de confirmar.', isError: true);
      return;
    }

    // Mostra um diálogo de confirmação
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirmar Pedido"),
          content: Text(
              "Deseja confirmar o pedido para ${_nomeClienteController.text} no valor total de R\$ ${_calcularValorTotal().toStringAsFixed(2)}?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o diálogo
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Fecha o diálogo
                await _enviarPedidoParaAPI(); // Envia o pedido
              },
              child: const Text("Confirmar"),
            ),
          ],
        );
      },
    );
  }

  void _alterarStatusPedido(String novoStatus) async {
    // Lógica para confirmar a mudança de status de 'PAGO' para 'ABERTO'
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
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text("Confirmar"),
              ),
            ],
          );
        },
      );
      if (confirmar == true) {
        setState(() {
          _statusPedido = novoStatus;
        });
        _mostrarSnackBar('Status do pedido alterado para $novoStatus.', isError: false);
      } else {
        _mostrarSnackBar('Ação cancelada.', isError: true);
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
            // Exibe o nome do cliente no AppBar
            Text(
              "Cliente: ${_nomeClienteController.text}",
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
        _buildCampoNome(vermelho), // Campo para o nome do cliente
        const SizedBox(height: 10),
        _buildCampoTelefone(vermelho), // Campo para o telefone do cliente
        const SizedBox(height: 10),
        _buildSecaoItens(context, vermelho), // Seção para adicionar itens com autocomplete
        const SizedBox(height: 20),
        // Exibição do valor total do pedido
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
        _buildStatusButtons(vermelho), // Botões de status do pedido
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
          enabled: widget.isNewClient, // Habilita/desabilita baseado se é novo cliente
          controller: _nomeClienteController,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB71C1C)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB71C1C)),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB71C1C), width: 2),
            ),
            disabledBorder: OutlineInputBorder( // Estilo quando desabilitado
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
          enabled: false, // Campo de telefone sempre desabilitado aqui
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
        // CompositedTransformTarget é crucial para o posicionamento do Overlay
        CompositedTransformTarget(
          link: _layerLink, // Link para o OverlayEntry
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
              _buildDropdownQuantidade(vermelho), // Dropdown de quantidade
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildBotaoAdicionar(vermelho), // Botão para adicionar item
        const SizedBox(height: 10),
        // Exibe "Nenhum item adicionado ainda." se a lista estiver vazia
        _itensAdicionados.isEmpty
            ? const Center(
                child: Text(
                  "Nenhum item adicionado ainda.",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : Column(
                children: _buildListaItensAdicionados(vermelho), // Lista de itens adicionados
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
        underline: const SizedBox(), // Remove a linha inferior do dropdown
        dropdownColor: Colors.white,
        items: List.generate(10, (index) => index + 1) // Opções de 1 a 10
            .map((e) => DropdownMenuItem(
                  value: e,
                  child:
                      Text("x$e", style: const TextStyle(color: Color(0xFFB71C1C))),
                ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _quantidade = value ?? 1; // Atualiza a quantidade selecionada
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

  // Constrói a lista de itens adicionados dinamicamente
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
              "R\$ ${(item['valorTotalItem'] ?? 0.0).toStringAsFixed(2)}", // Exibe o valor total do item
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
          const Divider(color: Color(0xFFB71C1C)), // Divisor entre os itens
        ],
      );
    }).toList();
  }

  Widget _buildBotaoCadastrar(BuildContext context, Color vermelho) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _mostrarPopupConfirmacao, // Chama o popup de confirmação
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

extension on LayerLink {
  get currentContext => null;
}