import 'package:flutter/material.dart';

enum RadioOption {
  videocall("Video Chamada"),
  chatAI("Chat com IA"),
  message("Deixe uma mensagem");

  final String label;
  const RadioOption(this.label);
}

class RadioOptions extends StatelessWidget {
  final RadioOption selectedOption;
  final ValueChanged<RadioOption> onOptionChanged;

  const RadioOptions({
    super.key,
    required this.selectedOption,
    required this.onOptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioGroup<RadioOption>(
          groupValue: selectedOption,
          onChanged: (newValue) => onOptionChanged(newValue!), // Call back para o pai
          child: Column(
            children: RadioOption.values.map(
              (option) => RadioListTile<RadioOption>(
                value: option,
                title: Text(option.label),
              ),
            ).toList(),
          ),
        ), 
      ], 
    );
  }
}
