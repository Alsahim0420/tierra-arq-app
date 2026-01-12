import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class FormatUtils {
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Obtiene solo los números de un string (remueve formato de moneda)
  static double? parseCurrency(String value) {
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanValue.isEmpty) return null;
    return double.tryParse(cleanValue);
  }

  /// Formatea un número con separadores de miles (sin símbolo de moneda)
  static String formatNumberWithSeparators(int number) {
    final formatter = NumberFormat('#,###', 'es_CO');
    return formatter.format(number);
  }

  static Color getStateColor(String state) {
    // Primero normalizar el texto del estado para asegurar consistencia
    final normalizedText = formatStateText(state);
    final normalized = normalizedText.toLowerCase().trim();
    
    switch (normalized) {
      case 'finalizado':
      case 'finalizada':
      case 'completada':
      case 'completado':
      case 'completed':
        return Colors.green;
      case 'en progreso':
      case 'en_progreso':
      case 'en_proceso':
        return Colors.blue;
      case 'pendiente':
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static String formatStateText(String state) {
    final normalized = state.toLowerCase().trim();
    if (normalized == 'en_proceso' || normalized == 'en_progreso') {
      return 'en progreso';
    }
    if (normalized == 'pendiente' || normalized == 'pending') {
      return 'pendiente';
    }
    if (normalized == 'finalizado' ||
        normalized == 'finalizada' ||
        normalized == 'completada' ||
        normalized == 'completado' ||
        normalized == 'completed') {
      return 'finalizado';
    }
    // Si no coincide, devolver el original
    return state;
  }
}

/// Formateador de entrada para campos de moneda
/// Formatea números con separadores de miles mientras se escribe
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si el nuevo valor está vacío, retornar vacío
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remover todo excepto números
    final cleanText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Si no hay números, retornar vacío
    if (cleanText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Convertir a número
    final number = int.tryParse(cleanText);
    if (number == null) {
      return oldValue;
    }

    // Formatear con separadores de miles
    final formatter = NumberFormat('#,###', 'es_CO');
    final formattedText = formatter.format(number);

    // Calcular la posición del cursor
    // Contar los caracteres numéricos antes de la posición del cursor en el texto original
    final textBeforeCursor = newValue.text.substring(0, newValue.selection.baseOffset);
    final digitsBeforeCursor = textBeforeCursor.replaceAll(RegExp(r'[^\d]'), '').length;
    
    // Encontrar la posición correspondiente en el texto formateado
    int newOffset = 0;
    int digitCount = 0;
    for (int i = 0; i < formattedText.length && digitCount < digitsBeforeCursor; i++) {
      if (RegExp(r'\d').hasMatch(formattedText[i])) {
        digitCount++;
      }
      newOffset = i + 1;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

