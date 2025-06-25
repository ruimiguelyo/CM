import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    bool isEditing = widget.product != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Produto' : 'Adicionar Produto'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildImagePicker(context),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome do Produto'),
                validator: (v) => v!.isEmpty ? 'O nome é obrigatório.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (v) => v!.isEmpty ? 'A descrição é obrigatória.' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildPriceField()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildUnitDropdown()),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock Disponível'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v!.isEmpty) return 'Obrigatório';
                  if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Inválido';
                  return null;
                },
              ),
            ],
          ).animate().fade(duration: 400.ms),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              image: _buildImageProvider(),
            ),
            child: _buildImageProvider() == null
                ? const Icon(Icons.image_outlined, size: 50, color: Colors.grey)
                : null,
          ),
          FloatingActionButton.small(
            onPressed: _pickImage,
            child: const Icon(Icons.edit),
          ),
        ],
      ),
    );
  }

  DecorationImage? _buildImageProvider() {
    if (_pickedImage != null) {
      return DecorationImage(
        image: kIsWeb ? NetworkImage(_pickedImage!.path) : FileImage(File(_pickedImage!.path)) as ImageProvider,
        fit: BoxFit.cover,
      );
    }
    if (_imagemUrlExistente != null && _imagemUrlExistente!.isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(_imagemUrlExistente!),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  Widget _buildPriceField() {
    return TextFormField(
      controller: _precoController,
      decoration: const InputDecoration(labelText: 'Preço (€)'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v!.isEmpty) return 'Obrigatório';
        if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Inválido';
        return null;
      },
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      value: _unidadeSelecionada,
      decoration: const InputDecoration(labelText: 'Unidade'),
      items: _unidades.map((String unidade) {
        return DropdownMenuItem<String>(value: unidade, child: Text(unidade));
      }).toList(),
      onChanged: (newValue) {
        if (newValue != null) {
          setState(() => _unidadeSelecionada = newValue);
        }
      },
      validator: (v) => v == null ? 'Obrigatório' : null,
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16).copyWith(bottom: 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProduct,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text('Guardar Produto'),
      ),
    );
  }
} 