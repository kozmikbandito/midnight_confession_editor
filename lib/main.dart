import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase paketini dahil et
import 'screens/home_screen.dart'; 

// main fonksiyonunu 'async' yapıyoruz çünkü Supabase başlatma işlemi zaman alabilir.
Future<void> main() async {
  // Bu satır, Flutter'ın Supabase'i başlatmadan önce hazır olmasını sağlar.
  WidgetsFlutterBinding.ensureInitialized();

  // Değişkenleri ortamdan okuyoruz.
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const MidnightConfessionApp());
}

class MidnightConfessionApp extends StatelessWidget {
  const MidnightConfessionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Midnight Confession - Editör',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF212121),
        primaryColor: Colors.indigo,
      ),
      home: const HomeScreen(),
    );
  }
}
