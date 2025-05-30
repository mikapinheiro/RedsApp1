import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer';

class Produto {
  final String id;
  final String nome;
  final double saldo;
  final double valor;

  Produto({
    required this.id,
    required this.nome,
    required this.saldo,
    required this.valor,
  });

  factory Produto.fromJson(Map<String, dynamic> json) {
    return Produto(
      id: json['id'].toString(),
      nome: json['produto'],
      saldo: (json['saldo'] as num).toDouble(),
      valor: (json['valor'] as num).toDouble(),
    );
  }
}

List<Produto> produtosGlobais = [];

class ApiService {
  static const String _baseUrl = 'https://redsapp-1748346206099.azurewebsites.net/reds';

  static const String apiKey = 'X-API-KEY';
  static const String apiValue = '535ebe88729240b1be05dd363e0e95bc';

  static Future<void> carregarProdutos() async {
    final url = Uri.parse('$_baseUrl/produto');
    log('ApiService - Carregando produtos da URL: $url');

    try {
      final response = await http.get(
        url,
        headers: {apiKey: apiValue},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        produtosGlobais = data.map((json) => Produto.fromJson(json)).toList();
        log('ApiService - Produtos carregados: ${produtosGlobais.length}');
      } else {
        throw Exception('Falha ao carregar produtos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('ApiService - Erro: $e');
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<Map<String, dynamic>?> adicionarPedido({ // Parâmetro pedidoPayload removido
    required String nomeCliente,
    required String telefoneCliente,
    required List<Map<String, dynamic>> listaItens,
    String? observacao,
    String? idPedido,
  }) async {
    final url = Uri.parse('$_baseUrl/pedido');
    log('ApiService - Adicionando pedido na URL: $url');

    final Map<String, dynamic> requestBody = {
      'nome': nomeCliente,
      'telefone': telefoneCliente,
      'listaItems': listaItens,
    };

    if (observacao?.isNotEmpty == true) {
      requestBody['observacao'] = observacao;
    }

    if (idPedido?.isNotEmpty == true) {
      requestBody['idPedido'] = idPedido;
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          apiKey: apiValue,
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        log('ApiService - Falha ao adicionar pedido: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      log('ApiService - Erro ao adicionar pedido: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> buscarPedidoPorId(String idPedido) async {
    final url = Uri.parse('$_baseUrl/pedido/id/$idPedido');
    log('ApiService - Buscando pedido por ID na URL: $url');
    try {
      final response = await http.get(
        url,
        headers: {apiKey: apiValue},
      );

      return response.statusCode == 200
          ? json.decode(response.body)
          : null;
    } catch (e) {
      log('ApiService - Erro ao buscar pedido por ID: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> buscarClienteEpedidosPorTelefone(String telefone) async {
    final url = Uri.parse('$_baseUrl/pedido/telefone/$telefone');
    log('ApiService - Buscando cliente e pedidos por telefone na URL: $url');
    try {
      final response = await http.get(
        url,
        headers: {apiKey: apiValue},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data is Map<String, dynamic> &&
                data.containsKey('nome') &&
                data.containsKey('telefone')
            ? data
            : null;
      } else if (response.statusCode == 404) {
        log('ApiService - Cliente não encontrado para o telefone $telefone (Status 404).');
        return null;
      }
      return null;
    } catch (e) {
      log('ApiService - Erro ao buscar cliente/pedidos: $e');
      return null;
    }
  }

  static Future<List<dynamic>> buscarPedidosPorTelefone(String telefone) async {
    final url = Uri.parse('$_baseUrl/pedido/$telefone');
    log('ApiService - Buscando pedidos na URL: $url');

    try {
      final response = await http.get(
        url,
        headers: {apiKey: apiValue},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        log('ApiService - Pedidos encontrados para $telefone: ${data.length}');
        return data;
      } else if (response.statusCode == 404) {
        log('ApiService - Nenhum pedido encontrado para o telefone $telefone (Status 404).');
        return [];
      } else {
        log('ApiService - Erro ao buscar pedidos por telefone: ${response.statusCode} - ${response.body}');
        throw Exception('Falha ao buscar pedidos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('ApiService - Erro de conexão ao buscar pedidos: $e');
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<bool> atualizarPedidoCompleto(
      String idPedido, Map<String, dynamic> pedidoData) async {
    final url = Uri.parse('$_baseUrl/pedido/$idPedido');
    log('ApiService - Atualizando pedido na URL: $url com dados: $pedidoData');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          apiKey: apiValue,
        },
        body: json.encode(pedidoData),
      );
      log('ApiService - Status de atualização do pedido: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      log('ApiService - Erro ao atualizar pedido: $e');
      return false;
    }
  }

  static Future<bool> deletarPedido(String idPedido) async {
    final url = Uri.parse('$_baseUrl/pedido/$idPedido');
    log('ApiService - Deletando pedido na URL: $url');
    try {
      final response = await http.delete(
        url,
        headers: {apiKey: apiValue},
      );
      log('ApiService - Status de exclusão do pedido: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      log('ApiService - Erro ao deletar pedido: $e');
      return false;
    }
  }
}