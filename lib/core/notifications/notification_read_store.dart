import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final notificationReadStoreProvider =
    NotifierProvider.family<NotificationReadStore, Set<String>, String>(
      NotificationReadStore.new,
    );

class NotificationReadStore extends Notifier<Set<String>> {
  NotificationReadStore(this.ownerKey);

  final String ownerKey;

  static const _prefix = 'sigcal.notifications.read';

  String get _storageKey => '$_prefix.$ownerKey';

  @override
  Set<String> build() {
    _load();

    return <String>{};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final storedValues = prefs.getStringList(_storageKey) ?? const <String>[];

    state = storedValues.toSet();
  }

  Future<void> markAsRead(String notificationId) async {
    if (state.contains(notificationId)) {
      return;
    }

    final nextState = {...state, notificationId};
    state = nextState;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, nextState.toList()..sort());
  }

  Future<void> markManyAsRead(Iterable<String> notificationIds) async {
    final nextState = {...state, ...notificationIds};

    if (nextState.length == state.length) {
      return;
    }

    state = nextState;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, nextState.toList()..sort());
  }

  Future<void> removeStale(Set<String> staleIds) async {
    if (staleIds.isEmpty) return;
    final nextState = {...state}..removeAll(staleIds);
    if (nextState.length == state.length) return;
    state = nextState;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, nextState.toList()..sort());
  }
}
