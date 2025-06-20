import 'package:flutter/material.dart';
import 'apiservice.dart'; // Certifique-se de que sua ApiService está corretamente importada
import 'dart:developer'; // Para logs

class TelaPedido extends StatefulWidget {
  final String telefone;
  final List<dynamic> pedidos; // Lista completa de pedidos do cliente

  const TelaPedido({
    super.key,
    required this.telefone,
    required this.pedidos,
  });

  @override
  State<TelaPedido> createState() => _TelaPedidoState();
}

class _TelaPedidoState extends State<TelaPedido> {
  bool _isLoading = false;
  late List<dynamic> _pedidosDoCliente; // Usaremos esta lista mutável
  final Map<String, bool> _pedidosExpandidos = {}; // Para controlar a expansão dos itens

  // Cores personalizadas
  static const Color primaryColor = Color.fromARGB(255, 184, 26, 14); // Vermelho da sua identidade
  static const Color backgroundColor = Colors.white; // Fundo principal branco
  static const Color textColor = Colors.black87; // Cor do texto padrão (para contraste em fundos claros)

  // Cores de status de pedido
  static const Color abertoColor = Colors.blue;
  static const Color pagoColor = Colors.green;
  static const Color entregueColor = Colors.grey;
  static const Color canceladoColor = Colors.red; // Cor para o botão Cancelar (que agora exclui)
  static const Color deleteColor = Colors.deepOrange; // Cor para exclusão (aviso extra)

  @override
  void initState() {
    super.initState();
    _pedidosDoCliente = List.from(widget.pedidos);
    // Inicializa todos os pedidos como não expandidos, tratando o ID nulo
    for (var pedido in _pedidosDoCliente) {
      final String pedidoId = pedido['id']?.toString() ?? '';
      if (pedidoId.isNotEmpty) {
        _pedidosExpandidos[pedidoId] = false;
      }
    }

    if (_pedidosDoCliente.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarMensagem("Nenhum pedido encontrado para este cliente.", isErro: true);
      });
    }
  }

  // Função para alternar a visibilidade dos itens do pedido
  void _toggleItensVisibility(String pedidoId) {
    setState(() {
      _pedidosExpandidos[pedidoId] = !(_pedidosExpandidos[pedidoId] ?? false);
    });
  }

  Future<void> _atualizarStatusPedido(Map<String, dynamic> pedido, String novoStatus) async {
    final idPedido = (pedido['id']?.toString()) ?? ''; // Garante que é uma string ou vazia

    if (idPedido.isEmpty || idPedido == '?????') { // Verifica se o ID é vazio ou o placeholder
      _mostrarMensagem("Erro: ID do pedido não encontrado ou inválido.", isErro: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Chama o método atualizado na ApiService
      final sucesso = await ApiService.atualizarStatusPedido(idPedido, novoStatus);

      if (sucesso) {
        _mostrarMensagem("Pedido ${idPedido.substring(0, 6)} atualizado para $novoStatus com sucesso!");
        setState(() {
          final index = _pedidosDoCliente.indexWhere((p) => (p['id']?.toString() ?? '') == idPedido);
          if (index != -1) {
            _pedidosDoCliente[index]['statusPedido'] = novoStatus; // CORREÇÃO: Usar 'statusPedido'
          }
        });
      } else {
        _mostrarMensagem("Erro ao atualizar o pedido ${idPedido.substring(0, 6)} para $novoStatus.", isErro: true);
      }
    } catch (e) {
      _mostrarMensagem("Erro ao atualizar o pedido ${idPedido.substring(0, 6)}: $e", isErro: true);
      log('Erro ao atualizar pedido: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Função para excluir pedido (AGORA CHAMANDO A API COM TELEFONE E ID DO PEDIDO)
  Future<void> _excluirPedido(Map<String, dynamic> pedido) async {
    final idPedido = (pedido['id']?.toString()) ?? ''; // Garante que é uma string ou vazia

    if (idPedido.isEmpty || idPedido == '?????') { // Verifica se o ID é vazio ou o placeholder
      _mostrarMensagem("Erro: ID do pedido não encontrado ou inválido para exclusão.", isErro: true);
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão', style: TextStyle(color: textColor)),
          content: Text('Tem certeza que deseja EXCLUIR permanentemente o pedido #${idPedido.substring(0, 6)}?', style: TextStyle(color: textColor)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não', style: TextStyle(color: primaryColor)), // Botão Não em vermelho
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim', style: TextStyle(color: deleteColor)), // Botão Sim em laranja/vermelho
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      // Passa o telefone do cliente junto com o ID do pedido
      final sucesso = await ApiService.excluirPedido(widget.telefone, idPedido);

      if (sucesso) {
        _mostrarMensagem("Pedido ${idPedido.substring(0, 6)} excluído com sucesso!");
        setState(() {
          _pedidosDoCliente.removeWhere((p) => (p['id']?.toString() ?? '') == idPedido);
          _pedidosExpandidos.remove(idPedido); // Remove do mapa de expansão
        });
      } else {
        _mostrarMensagem("Erro ao excluir o pedido ${idPedido.substring(0, 6)}.", isErro: true);
      }
    } catch (e) {
      _mostrarMensagem("Erro ao excluir o pedido ${idPedido.substring(0, 6)}: $e", isErro: true);
      log('Erro ao excluir pedido: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarMensagem(String msg, {bool isErro = false}) {
    // Adicionado check de mounted para evitar erro se o contexto não estiver mais disponível
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)), // Conteúdo branco
        backgroundColor: isErro ? primaryColor : pagoColor, // Cores do SnackBar ajustadas
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildStatusButton(String currentStatus, String targetAction, Map<String, dynamic> pedido) {
    Color buttonColor;
    Color textColor = Colors.white; // Texto dos botões de ação sempre branco
    Function()? onPressed;

    switch (targetAction) {
      case 'Pago':
        buttonColor = pagoColor;
        onPressed = currentStatus == 'Aberto' ? () => _atualizarStatusPedido(pedido, 'Pago') : null;
        break;
      case 'Entregue': // Changed from 'Entregar' to 'Entregue' to match final status value
        buttonColor = Colors.blue; // Usando azul para entregar
        onPressed = (currentStatus == 'Pago' || currentStatus == 'Aberto') ? () => _atualizarStatusPedido(pedido, 'Entregue') : null;
        break;
      case 'Apagar': // Changed from 'Cancelar' to 'Apagar' for delete action
        buttonColor = deleteColor; // Cor para o botão de apagar
        onPressed = () => _excluirPedido(pedido); // Always allow deletion, but with confirmation
        break;
      default:
        buttonColor = Colors.grey;
        onPressed = null;
    }

    // Só construímos o botão se onPressed não for nulo (ou seja, se a ação for permitida)
    if (onPressed == null && targetAction != 'Apagar') { // Still show Apagar even if onPressed is null to allow it
      return const SizedBox.shrink(); // Retorna um widget vazio se o botão não deve aparecer
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor, // Cor do botão
            foregroundColor: textColor,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          child: Text(targetAction), // Usamos targetAction para o texto do botão
        ),
      ),
    );
  }

  // A função de filtro agora retorna a lista completa, pois o filtro é fixo em "Todos"
  List<dynamic> get _pedidosFiltrados {
    return _pedidosDoCliente;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor, // Fundo principal branco
      appBar: AppBar(
        backgroundColor: Colors.white, // AppBar branca
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor), // Ícone em vermelho
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text( // Removido o número do cliente
          'Pedidos do Cliente',
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold), // Título em vermelho
        ),
        centerTitle: true,
        actions: const [
          // Botão "Venda" removido completamente
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : _pedidosFiltrados.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sentiment_dissatisfied, size: 60, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text(
                          // Mensagem agora é sempre sobre a ausência de pedidos totais
                          'Nenhum pedido encontrado para este cliente.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _pedidosFiltrados.length,
                  itemBuilder: (context, index) {
                    final pedido = _pedidosFiltrados[index];
                    // Garantindo que 'id' e 'status' sejam tratados com segurança de nulos
                    final String pedidoId = pedido['id']?.toString() ?? '?????';
                    final String pedidoIdCurto = pedidoId.length >= 6 ? pedidoId.substring(0, 6) : pedidoId;
                    final String status = (pedido['statusPedido'] as String?) ?? 'Aberto'; // Alterado de 'status' para 'statusPedido'
                    
                    // CORREÇÃO AQUI: Acessa 'listaItens' conforme o JSON da API
                    final List<dynamic> itens = (pedido['listaItens'] is List) ? pedido['listaItens'] : [];


                    // Definindo a cor do CARD com foco no tom avermelhado
                    Color cardColor;
                    cardColor = primaryColor.withOpacity(0.1); // Todos os cards terão um tom vermelho claro para o fundo

                    final bool isExpanded = _pedidosExpandidos[pedidoId] ?? false;

                    return Card(
                      color: cardColor, // Cor do card definida acima
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _toggleItensVisibility(pedidoId),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pedido #$pedidoIdCurto',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor), // Texto preto para contraste
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Status: $status', style: const TextStyle(fontSize: 16, color: textColor)), // Texto preto para contraste
                                  const Divider(height: 10, thickness: 1, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Itens do Pedido:',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor), // Texto preto
                                  ),
                                  const SizedBox(height: 8),
                                  if (itens.isEmpty)
                                    const Text('Nenhum item neste pedido.', style: TextStyle(fontStyle: FontStyle.italic, color: textColor)), // Texto preto
                                  ...itens.map<Widget>((item) {
                                    // Acessando os campos do item com segurança, conforme o JSON
                                    final String nomeItem = (item['produto'] as String?) ?? 'Item desconhecido';
                                    final dynamic quantidadeItem = item['qtdVenda'] ?? 'N/A';
                                    final double precoItem = (item['valorVenda'] as num?)?.toDouble() ?? 0.0;

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Text.rich(
                                        TextSpan(
                                          text: '- $nomeItem (Quant: $quantidadeItem) - ',
                                          style: const TextStyle(fontSize: 14, color: textColor), // Texto preto
                                          children: <TextSpan>[
                                            TextSpan(
                                              text: 'R\$ ${precoItem.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: primaryColor, // Preço em vermelho
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                _buildStatusButton(status, 'Pago', pedido),
                                _buildStatusButton(status, 'Entregue', pedido), // Updated to 'Entregue'
                                _buildStatusButton(status, 'Apagar', pedido), // Updated to 'Apagar'
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}