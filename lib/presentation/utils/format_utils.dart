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
    switch (state.toLowerCase().trim()) {
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
    if (normalized == 'completada' || normalized == 'completado' || normalized == 'completed') {
      return 'completada';
    }
    // Si no coincide, devolver el original
    return state;
  }
}

