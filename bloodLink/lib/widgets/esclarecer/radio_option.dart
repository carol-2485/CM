import 'package:flutter/material.dart';

enum RadioOption {
  videocall("Video Chamada"),
  chatAI("Chat com IA"),
  message("Deixe uma mensagem");

  final String label;
  const RadioOption(this.label);
}

class RadioOptions extends StatefulWidget {
  const RadioOptions({super.key});

  @override
  State<RadioOptions> createState() => _RadioOptionsState();
}

class _RadioOptionsState extends State<RadioOptions> {
  RadioOption _selectedOption = RadioOption.videocall;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Agora usa este RadioGroup porque a forma antiga só com RadioListTile não está deprecada
        RadioGroup<RadioOption>(
          groupValue: _selectedOption,
          onChanged: (newOption) {
            setState(() {
              _selectedOption = newOption!;
            });
          },
          child: Column(
            children: RadioOption.values.map((option) {
              return RadioListTile<RadioOption>(
                value: option,
                title: Text(option.label),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
