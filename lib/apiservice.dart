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

  static Future<Map<String, dynamic>?> adicionarPedido({
    required String nomeCliente,
    required String telefoneCliente,
    required List<Map<String, dynamic>> listaItens,
    String? observacao,
    required String status,
  }) async {
    final url = Uri.parse('$_baseUrl/pedido/add/$telefoneCliente');
    log('ApiService - Adicionando pedido na URL: $url');

    final Map<String, dynamic> requestBody = {
      'nome': nomeCliente,
      'produtos': listaItens,
      'statusPedido': status,
    };

    if (observacao?.isNotEmpty == true) {
      requestBody['observacao'] = observacao;
    }

    log('Payload FINAL sendo enviado para a API: ${json.encode(requestBody)}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          apiKey: apiValue,
        },
        body: json.encode(requestBody),
      );

      log('ApiService - Status da resposta ao adicionar pedido: ${response.statusCode}');
      log('ApiService - Corpo da resposta ao adicionar pedido: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('Pedido adicionado com sucesso! Resposta: ${response.body}');
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

      if (response.statusCode == 200) {
        log('Pedido por ID encontrado: ${response.body}');
        return json.decode(response.body);
      } else {
        log('ApiService - Pedido por ID não encontrado ou erro: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      log('ApiService - Erro ao buscar pedido por ID: $e');
      return null;
    }
  }

  // Método para buscar APENAS pedidos por telefone (retorna a lista de pedidos)
  static Future<List<dynamic>> buscarPedidosPorTelefone(String telefone) async {
    final url = Uri.parse('$_baseUrl/pedido/$telefone');
    log('ApiService - Buscando pedidos na URL: $url');

    try {
      final response = await http.get(
        url,
        headers: {apiKey: apiValue},
      );

      log('ApiService - Status da resposta para buscarPedidosPorTelefone: ${response.statusCode}');
      log('ApiService - Corpo da resposta para buscarPedidosPorTelefone: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        if (decodedData is List<dynamic>) {
          log('ApiService - Pedidos encontrados (lista direta) para $telefone: ${decodedData.length}');
          return decodedData;
        } else if (decodedData is Map<String, dynamic> && decodedData.containsKey('pedidos')) {
          final List<dynamic> pedidos = decodedData['pedidos'] as List<dynamic>;
          log('ApiService - Pedidos encontrados (dentro de "pedidos") para $telefone: ${pedidos.length}');
          return pedidos;
        } else {
          log('ApiService - Formato de resposta inesperado para buscarPedidosPorTelefone: $decodedData');
          throw Exception('Formato de resposta inesperado da API ao buscar pedidos. O corpo da resposta não é uma lista direta nem um mapa com a chave "pedidos".');
        }
      } else if (response.statusCode == 404) {
        log('ApiService - Nenhum pedido encontrado para o telefone $telefone (Status 404). Retornando lista vazia.');
        return [];
      } else {
        log('ApiService - Erro ao buscar pedidos por telefone: ${response.statusCode} - ${response.body}');
        throw Exception('Falha ao buscar pedidos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('ApiService - Erro de conexão ao buscar pedidos: $e');
      throw Exception('Erro de conexão: ${e.toString()}');
    }
  }

  // MÉTODO PRINCIPAL PARA BUSCAR CLIENTE E PEDIDOS (USADO NA TELA VENDEDOR)
  // Retorna um Map contendo 'nome', 'telefone', 'pedidos' ou null
  static Future<Map<String, dynamic>?> buscarClienteEpedidosPorTelefone(String telefone) async {
    final url = Uri.parse('$_baseUrl/pedido/$telefone'); // Endpoint para buscar pedidos por telefone
    log('ApiService - Buscando cliente e pedidos na URL: $url');

    try {
      final response = await http.get(
        url,
        headers: {apiKey: apiValue},
      );

      log('ApiService - Status da resposta (cliente/pedidos): ${response.statusCode}');
      log('ApiService - Corpo da resposta (cliente/pedidos): ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedData = json.decode(response.body);

        String? nomeCliente;
        String? telefoneCliente;
        List<dynamic> pedidos = [];

        if (decodedData is List<dynamic> && decodedData.isNotEmpty) {
          // Cenário 1: API retorna uma lista de pedidos.
          // Assumimos que o nome/telefone do cliente está no primeiro pedido.
          final firstPedido = decodedData.first as Map<String, dynamic>;
          nomeCliente = firstPedido['nomeCliente'] ?? firstPedido['nome']; // Tenta 'nomeCliente' ou 'nome'
          telefoneCliente = firstPedido['telefoneCliente'] ?? firstPedido['telefone'];
          pedidos = decodedData; // A lista de pedidos é a própria resposta

        } else if (decodedData is Map<String, dynamic>) {
          // Cenário 2: API retorna um objeto que contém o nome do cliente e a lista de pedidos.
          // Ex: {"nome": "Cliente XYZ", "telefone": "...", "pedidos": [...]}
          nomeCliente = decodedData['nomeCliente'] ?? decodedData['nome'];
          telefoneCliente = decodedData['telefoneCliente'] ?? decodedData['telefone'];
          pedidos = decodedData['pedidos'] is List<dynamic> ? decodedData['pedidos'] : [];

        }

        if (nomeCliente != null && telefoneCliente != null) {
          log('ApiService - Cliente e pedidos encontrados. Nome: $nomeCliente, Telefone: $telefoneCliente, Pedidos: ${pedidos.length}');
          return {
            'nome': nomeCliente,
            'telefone': telefoneCliente,
            'pedidos': pedidos, // Retorna os pedidos também
          };
        } else {
          log('ApiService - Cliente/pedidos não encontrado ou formato inesperado para o telefone: $telefone');
          return null; // Cliente não encontrado ou dados insuficientes
        }
      } else if (response.statusCode == 404) {
        log('ApiService - Cliente não encontrado para o telefone $telefone (Status 404). Retornando null.');
        return null; // Cliente não encontrado
      } else {
        log('ApiService - Erro ao buscar cliente e pedidos: ${response.statusCode} - ${response.body}');
        throw Exception('Falha ao buscar cliente e pedidos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('ApiService - Erro de conexão ao buscar cliente e pedidos: $e');
      throw Exception('Erro de conexão: ${e.toString()}');
    }
  }

  static Future<bool> atualizarStatusPedido(String idPedido, String novoStatus) async {
    final url = Uri.parse('$_baseUrl/pedido/$idPedido');
    log('ApiService - Atualizando status do pedido $idPedido para $novoStatus na URL: $url');

    try {
      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          apiKey: apiValue,
        },
        body: json.encode({'status': novoStatus}),
      );

      log('ApiService - Status da resposta ao atualizar status: ${response.statusCode}');
      log('ApiService - Corpo da resposta ao atualizar status: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      log('ApiService - Erro ao atualizar status do pedido: $e');
      return false;
    }
  }

  static Future<bool> excluirPedido(String telefone, String idPedido) async {
    final url = Uri.parse('$_baseUrl/pedido/$telefone/$idPedido');
    log('ApiService - Deletando pedido $idPedido (telefone: $telefone) na URL: $url');

    try {
      final response = await http.delete(
        url,
        headers: {apiKey: apiValue},
      );

      log('ApiService - Status da resposta ao deletar pedido: ${response.statusCode}');
      log('ApiService - Corpo da resposta ao deletar pedido: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      log('ApiService - Erro ao deletar pedido: $e');
      return false;
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
}