import 'package:flutter/material.dart';
import 'package:flutter_application_1/widgets/esclarecer/doctor_card.dart';
import 'package:flutter_application_1/widgets/esclarecer/radio_option.dart';

class EsclarecerScreen extends StatelessWidget {
  const EsclarecerScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Esclarecer Dúvidas'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [DoctorCard(name: 'Dr. IPS', specialty: 'Computação Móvel', imageUrl: 'https://example.com/doctor.jpg'),
            RadioOptions()
            ],
        ),
      ),
    );
  }

}