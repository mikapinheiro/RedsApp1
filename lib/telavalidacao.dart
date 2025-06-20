import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'telapedido.dart'; // Importe sua TelaPedido
import 'apiservice.dart' as api; // Importe sua ApiService global aqui!

class TelaValidacao extends StatefulWidget {
  const TelaValidacao({super.key});

  @override
  State<TelaValidacao> createState() => _TelaValidacaoState();
}

class _TelaValidacaoState extends State<TelaValidacao> {
  final TextEditingController _telefoneController = TextEditingController();
  bool _carregando = false;

  final maskFormatter = MaskTextInputFormatter(
    mask: '(##) # ####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  Future<void> _validarTelefone() async {
    final telefone = _telefoneController.text.replaceAll(RegExp(r'\D'), '').trim();
    if (telefone.isEmpty) {
      _mostrarDialogo('Por favor, digite um telefone.');
      return;
    }
    if (telefone.length != 11) {
      _mostrarDialogo('Por favor, digite um telefone válido com 11 dígitos (DDD + 9 dígitos).');
      return;
    }

    setState(() => _carregando = true);

    try {
      // Correção: o retorno de buscarPedidosPorTelefone pode ser List<dynamic>?
      // mas é melhor que a API já garanta que seja List<dynamic> vazia se não encontrar.
      final List<dynamic>? pedidosRetornados = await api.ApiService.buscarPedidosPorTelefone(telefone);

      // Garante que pedidos é uma lista não nula antes de passar para TelaPedido
      final List<dynamic> pedidos = pedidosRetornados ?? [];

      if (pedidos.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TelaPedido(
              telefone: telefone,
              pedidos: pedidos, // Passando a lista de pedidos agora, que é garantida não-nula
            ),
          ),
        );
      } else {
        _mostrarDialogo('Nenhum pedido encontrado para este telefone.');
      }
    } catch (e) {
      _mostrarDialogo('Erro ao buscar pedidos: ${e.toString()}');
    } finally {
      setState(() => _carregando = false);
    }
  }

  void _mostrarDialogo(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Aviso"),
        content: Text(msg),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color.fromARGB(255, 145, 12, 12);
    const Color secondaryColor = Colors.red;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.red),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "Validação",
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "DIGITE O CELULAR DO CLIENTE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _validarTelefone(),
              inputFormatters: [maskFormatter],
              decoration: InputDecoration(
                hintText: "(99) 99999-9999",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color.fromARGB(255, 145, 12, 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.phone, color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _carregando ? null : _validarTelefone,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _carregando
                  ? const CircularProgressIndicator(
                      color: primaryColor,
                      strokeWidth: 2,
                    )
                  : const Text(
                      "VALIDAR",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}