import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:appreds1/apiservice.dart';
import 'package:appreds1/telasolicitacao.dart';

class TelaVendedor extends StatefulWidget {
  const TelaVendedor({super.key});

  @override
  State<TelaVendedor> createState() => _TelaVendedorState();
}

class _TelaVendedorState extends State<TelaVendedor> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  final maskFormatter = MaskTextInputFormatter(
    mask: '(##) # ####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _validarTelefone(String telefone) {
    telefone = telefone.replaceAll(RegExp(r'\D'), '');
    return telefone.length == 11; // Exige DDD + 9 dígitos
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

  Future<void> _buscarClienteNaAPI() async {
    if (!_validarTelefone(_phoneController.text)) {
      _mostrarSnackBar('Por favor, digite um telefone válido com DDD e 9 dígitos.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String telefoneLimpo = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    log('TelaVendedor - Telefone limpo para busca: $telefoneLimpo');

    // Usamos `final navigator = Navigator.of(context);` antes do `await`
    // para garantir que o contexto não seja nulo após uma operação assíncrona.
    final navigator = Navigator.of(context);

    try {
      // Chama o método atualizado da ApiService para buscar cliente e pedidos
      final clienteData = await ApiService.buscarClienteEpedidosPorTelefone(telefoneLimpo);

      if (clienteData != null && clienteData['nome'] != null && (clienteData['nome'] as String).isNotEmpty) {
        log('TelaVendedor - Cliente encontrado: ${clienteData['nome']}');
        final nomeCliente = clienteData['nome'] as String;
        final telefoneCliente = clienteData['telefone'] as String; // Usar o telefone que veio da API, se disponível

        // Cliente existente: nome é preenchido, isNewClient é false, numeroPedido é null para um NOVO pedido.
        navigator.push(
          MaterialPageRoute(
            builder: (context) => TelaSolicitacao(
              telefone: telefoneCliente,
              nomeCliente: nomeCliente,
              isNewClient: false,
              numeroPedido: null, // Novo pedido para um cliente existente
            ),
          ),
        );
      } else {
        // Cliente não encontrado, ou o nome veio nulo/vazio.
        // Trata como novo cliente para permitir o cadastro.
        log('TelaVendedor - Cliente não encontrado ou nome vazio. Prosseguindo para cadastro de novo cliente.');
        navigator.push(
          MaterialPageRoute(
            builder: (context) => TelaSolicitacao(
              telefone: telefoneLimpo,
              nomeCliente: '', // Nome vazio para ser preenchido
              isNewClient: true, // É um novo cliente
              numeroPedido: null, // Sempre null para novo cliente
            ),
          ),
        );
      }
    } catch (e) {
      log('TelaVendedor - Erro ao buscar cliente: $e');
      _mostrarSnackBar(
        'Erro ao verificar cliente. ${e.toString().contains("Falha ao buscar cliente") ? "Telefone não cadastrado ou erro na API." : ""}',
        isError: true,
      );

      // Em caso de erro (ex: falha de conexão), ainda damos a opção de cadastrar como novo cliente
      if (!mounted) return;
      navigator.push(
        MaterialPageRoute(
          builder: (context) => TelaSolicitacao(
            telefone: telefoneLimpo,
            nomeCliente: '',
            isNewClient: true,
            numeroPedido: null,
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Vendedor",
          style: TextStyle(color:Color.fromARGB(255, 145, 12, 12), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 145, 12, 12), Colors.red.shade900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Digite o celular do cliente",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [maskFormatter],
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color.fromARGB(255, 145, 12, 12),
                border: OutlineInputBorder(),
                hintText: '(99) 9 9999-9999',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.phone, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : ElevatedButton(
                    onPressed: _buscarClienteNaAPI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color.fromARGB(255, 145, 21, 12),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Buscar Cliente",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}