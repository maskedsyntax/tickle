import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:tickle_core/tickle_core.dart';
import 'package:uuid/uuid.dart';

class HomeWidgetService {
  static const String appGroupId = 'group.com.maskedsyntax.tickle.tickleMobile';
  static const String iosWidgetName = 'TickleWidget';
  static const String androidWidgetName = 'TickleWidgetProvider';

  static const String pendingIncrementsKey = 'pending_increments';

  static Future<void> init() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<void> updateWidgets(CountersRepository repository) async {
    final activeCounters = await repository.getCounters(includeArchived: false);
    activeCounters.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    
    final topCounters = activeCounters.take(3).map((c) => {
      'id': c.id,
      'title': c.title,
      'emoji': c.emoji ?? '',
      'colorHex': c.colorHex,
      'currentCount': c.currentCount,
      'goalValue': c.goalValue,
    }).toList();

    final jsonString = jsonEncode(topCounters);
    
    await HomeWidget.saveWidgetData('top_counters', jsonString);
    await HomeWidget.updateWidget(
      name: androidWidgetName,
      iOSName: iosWidgetName,
    );
  }

  /// Applies any counter increments made from the widget (which run in the
  /// widget-extension process and only write to shared storage) into the
  /// database. Call on app launch and resume.
  ///
  /// Returns `true` if any pending increments were applied.
  static Future<bool> reconcilePendingIncrements(
    CountersRepository repository,
  ) async {
    final pendingString =
        await HomeWidget.getWidgetData<String>(pendingIncrementsKey);
    if (pendingString == null || pendingString.isEmpty) return false;

    Map<String, dynamic> pending;
    try {
      pending = jsonDecode(pendingString) as Map<String, dynamic>;
    } catch (_) {
      await HomeWidget.saveWidgetData<String>(pendingIncrementsKey, null);
      return false;
    }
    if (pending.isEmpty) return false;

    var applied = false;
    for (final entry in pending.entries) {
      final counterId = entry.key;
      final delta = (entry.value as num?)?.toInt() ?? 0;
      if (delta == 0) continue;

      final counter = await repository.getCounter(counterId);
      if (counter == null) continue;

      final updated =
          counter.copyWith(currentCount: counter.currentCount + delta);
      await repository.saveCounter(updated);
      await repository.addLog(
        CounterLog(
          id: const Uuid().v4(),
          counterId: counterId,
          timestamp: DateTime.now(),
          actionType: CounterActionType.increment,
          resultingCount: updated.currentCount,
          delta: delta,
        ),
      );
      applied = true;
    }

    // Clear the pending queue and push the reconciled DB state back to widgets.
    await HomeWidget.saveWidgetData<String>(pendingIncrementsKey, null);
    if (applied) {
      await updateWidgets(repository);
    }
    return applied;
  }
}
