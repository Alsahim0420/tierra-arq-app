import 'package:flutter/material.dart';
import 'core/injection/injection_container.dart' as di;
import 'presentation/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.configureDependencies();
  runApp(const TierraApp());
}
