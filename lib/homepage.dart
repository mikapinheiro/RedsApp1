import 'package:flutter/material.dart';
import 'package:appreds1/functions1.dart'; // Importação correta

class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Functions1(), // Agora funciona porque Functions1 é um Widget
            ),
          );
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red, Color.fromARGB(255, 161, 16, 6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Image.asset(
              'assets/EquipeVermelha.png',
              width: 250,
              height: 250,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.error, size: 100, color: Colors.white);
              },
            ),
          ),
        ),
      ),
    );
  }
}
