import 'package:flutter/material.dart';
import 'package:flutter_application_1/constants/app_colors.dart';
import 'package:flutter_application_1/widgets/app_bottom_nav.dart';
import 'package:flutter_application_1/widgets/blood_drop.dart';
import 'package:flutter_application_1/widgets/esclarecer/doctor_card.dart';
import 'package:flutter_application_1/widgets/esclarecer/radio_option.dart';

class EsclarecerScreen extends StatefulWidget {
  const EsclarecerScreen({super.key});

  @override
  State<EsclarecerScreen> createState() => _EsclarecerScreenState();
}

class _EsclarecerScreenState extends State<EsclarecerScreen> {
  RadioOption _selectedOption = RadioOption.videocall;

  void _handleOption(RadioOption newOption) {
    //setState();
    // tem que se alterar para depois colocar o chat e wpp
    switch (newOption) {
      case RadioOption.videocall:
        // Lógica para iniciar videochamada
        print("Iniciar Video Chamada");
        break;
      case RadioOption.chatAI:
        // Lógica para abrir chat com IA
        print("Abrir Chat com IA");
        break;
      case RadioOption.message:
        // Lógica para deixar uma mensagem
        print("Deixar uma mensagem");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: HeaderWidget()),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            DoctorCard(
              name: 'Dr. IPS',
              specialty: 'Computação Móvel',
              imageUrl:
                  'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?q=80&w=600&auto=format&fit=crop',
            ),
            const SizedBox(height: 100),
            RadioOptions(
              selectedOption: _selectedOption,
              onOptionChanged: (newOption) {
                setState(() {
                  _selectedOption = newOption;
                });
              },
            ),
            const Spacer(), 
            ElevatedButton(
              onPressed: () {
                _handleOption(_selectedOption);
                print("A fazer uma cena muita fixe");
              },
              child: const Text("Iniciar conversa"),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }
}


class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        //mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min, // Row ajusta se ao conteúdo
            children: [
              const BloodDrop(size: 25),
              const SizedBox(width: 8),
              const Text(
                'Esclarecer Dúvidas',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Fale com um profissional de saúde',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
