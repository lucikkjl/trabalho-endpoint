import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APIs REST - ViaCEP e DogAPI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 122, 93, 76)),
        useMaterial3: true,
      ),
      home: const ApiHomeScreen(),
    );
  }
}

// Modelo 1: ViaCEP
class Endereco {
  final String cep;
  final String logradouro;
  final String bairro;
  final String localidade;
  final String uf;

  Endereco({
    required this.cep,
    required this.logradouro,
    required this.bairro,
    required this.localidade,
    required this.uf,
  });

  factory Endereco.fromJson(Map<String, dynamic> json) {
    return Endereco(
      cep: json['cep'] ?? '',
      logradouro: json['logradouro'] ?? '',
      bairro: json['bairro'] ?? '',
      localidade: json['localidade'] ?? '',
      uf: json['uf'] ?? '',
    );
  }
}

class Cachorro {
  final String imagemUrl;

  Cachorro({required this.imagemUrl});

  factory Cachorro.fromJson(Map<String, dynamic> json) {
    return Cachorro(
      imagemUrl: json['message'] ?? '',
    );
  }
}

class ApiHomeScreen extends StatefulWidget {
  const ApiHomeScreen({super.key});

  @override
  State<ApiHomeScreen> createState() => _ApiHomeScreenState();
}

class _ApiHomeScreenState extends State<ApiHomeScreen> {
  // Controladores ViaCEP
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();

  final _racaController = TextEditingController();

  bool _isLoadingCep = false;
  bool _isLoadingDog = false;
  Cachorro? _cachorroBuscado;

  Future<void> _buscarCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) {
      _mostrarErro('CEP inválido. Digite exatamente 8 números.');
      return;
    }

    setState(() {
      _isLoadingCep = true;
      _logradouroController.clear();
      _bairroController.clear();
      _cidadeController.clear();
      _ufController.clear();
    });

    try {
      final response = await http
          .get(Uri.parse('https://viacep.com.br/ws/$cep/json/'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        if (dados.containsKey('erro')) {
          _mostrarErro('CEP não encontrado na base de dados.');
        } else {
          final endereco = Endereco.fromJson(dados);
          setState(() {
            _logradouroController.text = endereco.logradouro;
            _bairroController.text = endereco.bairro;
            _cidadeController.text = endereco.localidade;
            _ufController.text = endereco.uf;
          });
        }
      } else {
        _mostrarErro('Erro no servidor ViaCEP: Status ${response.statusCode}');
      }
    } on TimeoutException {
      _mostrarErro('A requisição demorou muito. Verifique sua internet.');
    } on SocketException {
      _mostrarErro('Sem conexão de rede. Ative o Wi-Fi ou dados móveis.');
    } catch (e) {
      _mostrarErro('Ocorreu um erro inesperado: $e');
    } finally {
      setState(() {
        _isLoadingCep = false;
      });
    }
  }

  Future<void> _buscarCachorro() async {
    final raca = _racaController.text.trim().toLowerCase();
    if (raca.isEmpty) {
      _mostrarErro('Por favor, digite o nome de uma raça.');
      return;
    }

    setState(() {
      _isLoadingDog = true;
      _cachorroBuscado = null;
    });

    try {
      final url = 'https://dog.ceo/api/breed/$raca/images/random';
      
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        setState(() {
          _cachorroBuscado = Cachorro.fromJson(dados);
        });
      } else if (response.statusCode == 404) {
        _mostrarErro('Raça não encontrada. Lembre-se de digitar em inglês (ex: pug, husky).');
      } else {
        _mostrarErro('Erro na Dog API: Status ${response.statusCode}');
      }
    } on TimeoutException {
      _mostrarErro('O download da imagem demorou muito.');
    } on SocketException {
      _mostrarErro('Sem conexão de rede. Ative o Wi-Fi ou dados móveis.');
    } catch (e) {
      _mostrarErro('Ocorreu um erro inesperado: $e');
    } finally {
      setState(() {
        _isLoadingDog = false;
      });
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red.shade800,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta de CEP e Doguinhos ૮ >ﻌ< ა'),
        backgroundColor: const Color.fromARGB(255, 155, 117, 95),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SESSÃO VIACEP
            const Text(
              '1. Consulta de Endereço ⚲',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cepController,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    decoration: const InputDecoration(
                      labelText: 'Digite o CEP',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 122, 93, 76),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isLoadingCep ? null : _buscarCep,
                    child: _isLoadingCep
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Buscar', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _logradouroController, readOnly: true, decoration: const InputDecoration(labelText: 'Rua')),
            TextField(controller: _bairroController, readOnly: true, decoration: const InputDecoration(labelText: 'Bairro')),
            Row(
              children: [
                Expanded(child: TextField(controller: _cidadeController, readOnly: true, decoration: const InputDecoration(labelText: 'Cidade'))),
                const SizedBox(width: 8),
                Expanded(flex: 0, child: SizedBox(width: 60, child: TextField(controller: _ufController, readOnly: true, decoration: const InputDecoration(labelText: 'UF')))),
              ],
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32.0),
              child: Divider(thickness: 2),
            ),

            // SESSÃO DOG API
            const Text(
              '2. Galeria de Raças 𓃦',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _racaController,
              decoration: const InputDecoration(
                labelText: 'Raça do cachorro (em inglês, ex: beagle)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pets),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color.fromARGB(255, 155, 117, 95),
                foregroundColor: Colors.white,
              ),
              onPressed: _isLoadingDog ? null : _buscarCachorro,
              child: _isLoadingDog
                  ? const SizedBox(
                      width: 20, height: 20, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text('Buscar Foto Aleatória', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 24),
            if (_cachorroBuscado != null)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color.fromARGB(255, 122, 93, 76), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    _cachorroBuscado!.imagemUrl,
                    fit: BoxFit.cover,
                    height: 300,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const SizedBox(
                        height: 300,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}