import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hellofarmer_app/models/product_model.dart';
import 'package:hellofarmer_app/services/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddEditProductScreen extends StatefulWidget {
  final String userId;
  final ProductModel? product; // Se for nulo, é para adicionar. Se não, é para editar.

  const AddEditProductScreen({super.key, required this.userId, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _precoController;
  late TextEditingController _stockController;

  String _unidadeSelecionada = 'Kg';
  final List<String> _unidades = ['Kg', 'Unidade', 'L', 'Molho', 'Dúzia'];

  XFile? _pickedImage;
  String? _imagemUrlExistente;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Preenche os campos se estiver a editar um produto
    _nomeController = TextEditingController(text: widget.product?.nome ?? '');
    _descricaoController = TextEditingController(text: widget.product?.descricao ?? '');
    _precoController = TextEditingController(text: widget.product?.preco.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _unidadeSelecionada = widget.product?.unidade ?? 'Kg';
    _imagemUrlExistente = widget.product?.imagemUrl;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = pickedFile;
      });
    }
  }

  Future<String> _uploadImage(XFile image) async {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('product_images')
        .child('${widget.userId}_${DateTime.now().toIso8601String()}.jpg');

    final uploadTask = storageRef.putData(await image.readAsBytes(), SettableMetadata(contentType: 'image/jpeg'));
    final snapshot = await uploadTask.whenComplete(() => {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_pickedImage == null && (_imagemUrlExistente == null || _imagemUrlExistente!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma imagem para o produto.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _imagemUrlExistente ?? '';

      if (_pickedImage != null) {
        imageUrl = await _uploadImage(_pickedImage!);
      }

      final product = ProductModel(
        id: widget.product?.id,
        nome: _nomeController.text,
        descricao: _descricaoController.text,
        preco: double.parse(_precoController.text.replaceAll(',', '.')),
        unidade: _unidadeSelecionada,
        produtorId: widget.userId,
        imagemUrl: imageUrl,
        dataCriacao: widget.product?.dataCriacao ?? Timestamp.now(),
        stock: double.parse(_stockController.text.replaceAll(',', '.')),
      );

      if (widget.product == null) {
        // Adicionar novo produto
        await _firestoreService.adicionarProduto(widget.userId, product);
      } else {
        // Atualizar produto existente
        await _firestoreService.atualizarProduto(widget.userId, product);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produto guardado com sucesso!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao guardar o produto: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Adicionar Produto' : 'Editar Produto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Widget para escolher e pré-visualizar a imagem
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _pickedImage != null
                    ? (kIsWeb
                        ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                        : Image.file(File(_pickedImage!.path), fit: BoxFit.cover))
                    : (_imagemUrlExistente != null && _imagemUrlExistente!.isNotEmpty)
                        ? Image.network(_imagemUrlExistente!, fit: BoxFit.cover)
                        : const Center(child: Text('Nenhuma imagem selecionada.')),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.image),
                label: const Text('Selecionar Imagem'),
                onPressed: _pickImage,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Produto'),
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precoController,
                      decoration: const InputDecoration(labelText: 'Preço (€)', prefixIcon: Icon(Icons.euro_symbol)),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value!.isEmpty) return 'Obrigatório';
                        if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Número inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unidadeSelecionada,
                      decoration: const InputDecoration(labelText: 'Unidade'),
                      items: _unidades.map((String unidade) {
                        return DropdownMenuItem<String>(
                          value: unidade,
                          child: Text(unidade),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() => _unidadeSelecionada = newValue!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock Disponível', prefixIcon: Icon(Icons.inventory_2_outlined)),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return 'Obrigatório';
                  if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Número inválido';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveProduct,
                icon: const Icon(Icons.save),
                label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 