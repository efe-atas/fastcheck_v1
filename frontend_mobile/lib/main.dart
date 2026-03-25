import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_shad_theme.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await initDependencies();

  runApp(const FastCheckApp());
}

class FastCheckApp extends StatelessWidget {
  const FastCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: Builder(
        builder: (context) {
          final authBloc = context.read<AuthBloc>();
          final appRouter = AppRouter(authBloc: authBloc);

          return ShadApp.router(
            title: 'FastCheck',
            debugShowCheckedModeBanner: false,
            theme: AppShadTheme.light,
            darkTheme: AppShadTheme.dark,
            themeMode: ThemeMode.light,
            materialThemeBuilder: (context, shadMaterial) {
              return AppTheme.lightTheme.copyWith(
                colorScheme: shadMaterial.colorScheme,
                scaffoldBackgroundColor: shadMaterial.scaffoldBackgroundColor,
                textTheme: shadMaterial.textTheme,
                textSelectionTheme: shadMaterial.textSelectionTheme,
                dividerTheme: shadMaterial.dividerTheme,
                iconTheme: shadMaterial.iconTheme,
                scrollbarTheme: shadMaterial.scrollbarTheme,
                primaryColor: shadMaterial.colorScheme.primary,
              );
            },
            routerConfig: appRouter.router,
          );
        },
      ),
    );
  }
}
