import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickle_core/tickle_core.dart';
import 'package:tickle_data/tickle_data.dart';
import 'src/theme/theme.dart';
import 'src/cubits/settings_cubit.dart';
import 'src/cubits/counters_cubit.dart';
import 'src/screens/home_screen.dart';
import 'src/screens/settings_screen.dart';
import 'src/utils/haptic_feedback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  final database = AppDatabase();
  final repository = DriftCountersRepository(database);

  runApp(
    RepositoryProvider<CountersRepository>(
      create: (_) => repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => SettingsCubit()..loadSettings(),
          ),
          BlocProvider(
            create: (_) => CountersCubit(repository)..loadCounters(),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        if (!state.isLoaded) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator.adaptive(),
              ),
            ),
          );
        }

        return MaterialApp(
          title: 'Tickle',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode: state.themeMode,
          home: const MainAppScaffold(),
        );
      },
    );
  }
}

class MainAppScaffold extends StatefulWidget {
  const MainAppScaffold({super.key});

  @override
  State<MainAppScaffold> createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.watch<SettingsCubit>().state;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: theme.dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            HapticsHelper.selectionClick(settings.hapticLevel);
            setState(() {
              _currentIndex = index;
            });
          },
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          iconSize: 22,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.circle_outlined),
              activeIcon: Icon(Icons.lens),
              label: 'Counters',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
