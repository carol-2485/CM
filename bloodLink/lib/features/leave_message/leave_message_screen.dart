import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class LeaveMessageScreen extends StatefulWidget {
  const LeaveMessageScreen({super.key});

  @override
  State<LeaveMessageScreen> createState() => _LeaveMessageScreenState();
}

class _LeaveMessageScreenState extends State<LeaveMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String? _selectedCenterId;
  List<QueryDocumentSnapshot> _centers = [];
  bool _loadingCenters = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _loadCenters();
  }

  Future<void> _loadCenters() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('centros')
        .get();
    if (mounted) {
      setState(() {
        _centers = snapshot.docs;
        _loadingCenters = false;
      });
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCenterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um centro de saúde')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance.collection('messages').add({
        'userId': uid,
        'centerId': _selectedCenterId,
        'subject': _subjectCtrl.text.trim(),
        'text': _messageCtrl.text.trim(),
        'reply': null,
        'repliedBy': null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'repliedAt': null,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mensagem enviada!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Deixar Mensagem'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: _loadingCenters
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'A sua mensagem será enviada ao centro de saúde escolhido.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedCenterId,
                        decoration: InputDecoration(
                          labelText: 'Centro de Saúde',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _centers.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(data['nome'] ?? 'Sem nome'),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedCenterId = value),
                        validator: (v) =>
                            v == null ? 'Selecione um centro' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _subjectCtrl,
                        decoration: InputDecoration(
                          labelText: 'Assunto',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Obrigatório' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _messageCtrl,
                        decoration: InputDecoration(
                          labelText: 'Mensagem',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 6,
                        validator: (v) => v == null || v.length < 10
                            ? 'Mínimo 10 caracteres'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sending ? null : _sendMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _sending
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Enviar',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}