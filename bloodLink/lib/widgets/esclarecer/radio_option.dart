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
      // Aparece como deprecated, mas não consigo fazer de outra forma
      children: RadioOption.values.map(
            (option) => RadioListTile<RadioOption>(
              value: option,
              groupValue: _selectedOption,
              title: Text(option.label),
              onChanged: (newOption) {
                setState(() => _selectedOption = newOption!);
              },
            ),
          ).toList(),
    );
  }
}
