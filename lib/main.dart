import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Supabase paketini dahil et
import 'screens/home_screen.dart'; 

// main fonksiyonunu 'async' yapıyoruz çünkü Supabase başlatma işlemi zaman alabilir.
Future<void> main() async {
  // Bu satır, Flutter'ın Supabase'i başlatmadan önce hazır olmasını sağlar.
  WidgetsFlutterBinding.ensureInitialized();

  // Supabase'i başlatıyoruz.
  await Supabase.initialize(
    url: 'https://bvtvyuqdemsdbdxyympq.supabase.co',      // Buraya Supabase projenin URL'sini yapıştır.
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ2dHZ5dXFkZW1zZGJkeHl5bXBxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA2ODA0OTUsImV4cCI6MjA2NjI1NjQ5NX0.8FjhUdhCNSDd_tsBRoWyCiU10Ylzjk0N84rpPwNYB6Y', // Buraya Supabase projenin 'anon' key'ini yapıştır.
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
