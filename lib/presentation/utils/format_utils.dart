// ignore_for_file: prefer_is_empty

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
      case 'estancado':
      case 'estancada':
      case 'stalled':
        return Colors.amber;
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
    if (normalized == 'estancado' ||
        normalized == 'estancada' ||
        normalized == 'stalled') {
      return 'estancado';
    }
    // Si no coincide, devolver el original
    return state;
  }
}

/// Formateador de entrada para campos de moneda
/// Formatea números con separadores de miles mientras se escribe
/// Incluye el prefijo "$ " directamente en el texto formateado
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Si el texto nuevo es igual al anterior, no hacer nada (evitar loops)
    if (newValue.text == oldValue.text) {
      return newValue;
    }

    // Remover todo excepto números del texto nuevo
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Si no hay números después de limpiar, permitir vacío
    if (newText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Convertir a número
    final number = int.tryParse(newText);
    if (number == null) {
      // Si no se puede parsear, mantener el valor anterior
      return oldValue;
    }

    // Formatear con separadores de miles
    final formatter = NumberFormat('#,###', 'es_CO');
    final formattedNumber = formatter.format(number);
    
    // Agregar el prefijo "$ " al texto formateado
    final formattedText = '\$ $formattedNumber';

    // Calcular la posición del cursor basándose en la cantidad de dígitos
    // antes del cursor en el texto nuevo (sin formato)
    final oldTextDigits = oldValue.text.replaceAll(RegExp(r'[^\d]'), '');
    final newTextDigits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Determinar si se agregó o eliminó texto
    final isDeleting = newTextDigits.length < oldTextDigits.length;
    final cursorOffset = newValue.selection.baseOffset;
    final textBeforeCursor = newValue.text.substring(0, cursorOffset.clamp(0, newValue.text.length));
    final digitsBeforeCursor = textBeforeCursor.replaceAll(RegExp(r'[^\d]'), '').length;
    
    // Encontrar la posición correspondiente en el texto formateado
    int newOffset = 2; // Empezar después de "$ "
    int digitCount = 0;
    for (int i = 0; i < formattedNumber.length; i++) {
      if (RegExp(r'\d').hasMatch(formattedNumber[i])) {
        digitCount++;
        if (digitCount >= digitsBeforeCursor) {
          newOffset = 2 + i + 1; // +2 por "$ ", +1 para posición después del dígito
          break;
        }
      }
    }
    
    // Si estamos al final o más allá, colocar al final
    if (newOffset > formattedText.length) {
      newOffset = formattedText.length;
    }
    
    // Si estamos borrando desde el final, ajustar la posición
    if (isDeleting && cursorOffset == oldValue.text.length && newTextDigits.length > 0) {
      newOffset = formattedText.length;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newOffset.clamp(0, formattedText.length)),
    );
  }
}

