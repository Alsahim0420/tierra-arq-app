import 'package:flutter/material.dart';

/// Widget personalizado para mostrar SnackBars con animación y personalización
class CustomSnackBar {
  /// Muestra un SnackBar personalizado
  static void show(
    BuildContext context, {
    required String message,
    Duration? duration,
    Color? backgroundColor,
    IconData? icon,
    Color? iconColor,
    String? actionLabel,
    VoidCallback? onAction,
    SnackBarType type = SnackBarType.info,
  }) {
    // Configuración por defecto según el tipo
    final defaultConfig = _getDefaultConfig(type);
    
    final finalIcon = icon ?? defaultConfig.icon;
    final snackBar = SnackBar(
      content: _AnimatedSnackBarContent(
        child: Row(
          children: [
            if (finalIcon != null)
              Icon(
                finalIcon,
                color: iconColor ?? defaultConfig.iconColor ?? Colors.white,
                size: 24,
              ),
            if (finalIcon != null) const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: backgroundColor ?? defaultConfig.backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: duration ?? defaultConfig.duration,
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Muestra un SnackBar de éxito
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Muestra un SnackBar de error
  static void showError(
    BuildContext context, {
    required String message,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Muestra un SnackBar de advertencia
  static void showWarning(
    BuildContext context, {
    required String message,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Muestra un SnackBar informativo
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: SnackBarType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Obtiene la configuración por defecto según el tipo
  static _SnackBarConfig _getDefaultConfig(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return _SnackBarConfig(
          backgroundColor: Colors.green.shade700,
          icon: Icons.check_circle_outline,
          iconColor: Colors.white,
          duration: const Duration(seconds: 3),
        );
      case SnackBarType.error:
        return _SnackBarConfig(
          backgroundColor: Colors.red.shade700,
          icon: Icons.error_outline,
          iconColor: Colors.white,
          duration: const Duration(seconds: 4),
        );
      case SnackBarType.warning:
        return _SnackBarConfig(
          backgroundColor: Colors.orange.shade700,
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.white,
          duration: const Duration(seconds: 3),
        );
      case SnackBarType.info:
        return _SnackBarConfig(
          backgroundColor: Colors.blue.shade700,
          icon: Icons.info_outline,
          iconColor: Colors.white,
          duration: const Duration(seconds: 3),
        );
    }
  }
}

/// Tipos de SnackBar disponibles
enum SnackBarType {
  success,
  error,
  warning,
  info,
}

/// Configuración interna para los SnackBars
class _SnackBarConfig {
  final Color backgroundColor;
  final IconData? icon;
  final Color? iconColor;
  final Duration duration;

  _SnackBarConfig({
    required this.backgroundColor,
    this.icon,
    this.iconColor,
    required this.duration,
  });
}

/// Widget con animación para el contenido del SnackBar
class _AnimatedSnackBarContent extends StatefulWidget {
  final Widget child;

  const _AnimatedSnackBarContent({required this.child});

  @override
  State<_AnimatedSnackBarContent> createState() =>
      _AnimatedSnackBarContentState();
}

class _AnimatedSnackBarContentState extends State<_AnimatedSnackBarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Animación de deslizamiento desde abajo
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0), // Empieza desde abajo
      end: Offset.zero, // Termina en su posición
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic, // Curva suave
    ));

    // Animación de fade in
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Iniciar animación
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}


