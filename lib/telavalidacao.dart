import 'package:flutter/material.dart';

class TelaValidacao extends StatefulWidget {
  const TelaValidacao({super.key});

  @override
  State<TelaValidacao> createState() => _TelaValidacaoState();
}

class _TelaValidacaoState extends State<TelaValidacao> {
  final TextEditingController _codigoController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();

  void _validarEntrada() {
    String codigo = _codigoController.text.trim();
    String telefone = _telefoneController.text.replaceAll(RegExp(r'\D'), '');

    if (codigo.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/telaPedido',
        arguments: {'codigo': codigo},
      );
    } else if (telefone.length == 11) {
      Navigator.pushNamed(
        context,
        '/telaPedido',
        arguments: {'telefone': telefone},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Digite um código de pedido ou um telefone válido."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color.fromARGB(255, 145, 12, 12);
    const Color secondaryColor = Colors.red;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.red),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            "VALIDAÇÃO",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
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
              "DIGITE O CÓDIGO DA VENDA",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _codigoController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _validarEntrada(),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "Ex: 123",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "OU",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),
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
              onSubmitted: (_) => _validarEntrada(),
              decoration: InputDecoration(
                hintText: "(00) 00000-0000",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
