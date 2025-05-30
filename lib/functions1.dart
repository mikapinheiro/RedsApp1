import 'package:flutter/material.dart';
import 'package:appreds1/telavalidacao.dart';
import 'package:appreds1/telavendedor.dart';

class Functions1 extends StatelessWidget {
  const Functions1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 145, 12, 12),
      body: Stack(
        children: [
          Container(
            height: 400,
            color: Colors.white,
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              double screenWidth = constraints.maxWidth;
              double circleSize = screenWidth * 0.7;

              return Stack(
                children: [
                  Positioned(
                    top: 200,
                    left: -circleSize * 0.25,
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
                    top: 230,
                    left: screenWidth - (circleSize * 0.75),
                    child: Container(
                      width: circleSize,
                      height: circleSize,
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 145, 12, 12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 275,
                    left: (screenWidth - 170) / 2,
                    child: Image.asset(
                      'assets/EquipeVermelha.png',
                      width: 170,
                      height: 170,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.error, size: 100, color: Colors.white);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildButton(context, "VENDER", const TelaVendedor()),
                  const SizedBox(height: 20),
                  _buildButton(context, "VALIDAÇÃO", const TelaValidacao()),
                  const SizedBox(height: 20)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Widget destination) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 180, 14, 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}