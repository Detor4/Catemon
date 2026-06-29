import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cat_photo_store.dart';
import 'detection_service.dart';
import 'home_page.dart';
import 'profile_store.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Shriftlar faqat bundled assetsdan yuklanadi (offline) — internet so'ralmaydi.
  GoogleFonts.config.allowRuntimeFetching = false;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  try {
    await CatPhotoStore.instance.load();
    await ProfileStore.instance.load();
    await ProfileStore.instance.registerLogin();
    await DetectionService.instance.ensureLoaded();
  } catch (_) {
    // path_provider / onnx may be unavailable in widget tests.
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Til (va profil) o'zgarganda butun ilova qayta quriladi.
    return AnimatedBuilder(
      animation: ProfileStore.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Catemon',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark(),
          home: const HomePage(),
        );
      },
    );
  }
}
