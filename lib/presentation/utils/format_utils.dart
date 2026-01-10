import 'package:flutter/material.dart';
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

