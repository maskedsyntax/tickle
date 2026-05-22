import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickle_core/tickle_core.dart';
import 'package:tickle_mobile/main.dart';
import 'package:tickle_mobile/src/cubits/settings_cubit.dart';
import 'package:tickle_mobile/src/cubits/counters_cubit.dart';

class FakeCountersRepository implements CountersRepository {
  @override
  Stream<List<Counter>> watchCounters({bool includeArchived = false}) => Stream.value([]);

  @override
  Future<List<Counter>> getCounters({bool includeArchived = false}) async => [];

  @override
  Future<Counter?> getCounter(String id) async => null;

  @override
  Future<void> saveCounter(Counter counter) async {}

  @override
  Future<void> deleteCounter(String id) async {}

  @override
  Future<void> updateCounterOrder(List<String> orderedIds) async {}

  @override
  Stream<List<CounterLog>> watchLogs(String counterId) => Stream.value([]);

  @override
  Future<List<CounterLog>> getLogs(String counterId) async => [];

  @override
  Future<void> addLog(CounterLog log) async {}

  @override
  Future<void> clearLogs(String counterId) async {}

  @override
  Future<List<CounterLog>> getAllLogs() async => [];
}

void main() {
  testWidgets('App starts and displays onboarding screen when no counters exist', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = FakeCountersRepository();

    await tester.pumpWidget(
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

    // Wait for settings cubit load
    await tester.pumpAndSettle();

    // Verify it finds the onboarding text
    expect(find.text('Count anything. Instantly.'), findsOneWidget);
    expect(find.text('Create a Counter'), findsOneWidget);
  });
}
