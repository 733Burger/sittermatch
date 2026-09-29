import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'screens/splash_screen.dart'; 
import 'screens/bookings_dashboard_screen.dart'; 
import 'screens/saved_sitters_screen.dart';

void main() {
  runApp(const SitterMatchApp());
}

class SitterMatchApp extends StatelessWidget {
  const SitterMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SitterMatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryRust,
          primary: AppColors.primaryRust,
        ),
        useMaterial3: true,
      ),
      // Set Page 8 as the starting screen for testing
      home: const SavedSittersScreen(), 
  
    );
  }
  
}

// Commented out the original start up logic
// import 'screens/home_screen.dart';
// import 'screens/role_select_screen.dart';
// import 'services/auth_services.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   final isLoggedIn = await AuthService().isLoggedIn();

//   runApp(SitterMatchApp(isLoggedIn: isLoggedIn));
// }

// class SitterMatchApp extends StatelessWidget {
//   final bool isLoggedIn;

//   const SitterMatchApp({
//     super.key,
//     required this.isLoggedIn
//   });

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'SitterMatch',
//       theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
//       home: isLoggedIn ? const HomeScreen() : const RoleSelectScreen(),
//     );
//   }
// }