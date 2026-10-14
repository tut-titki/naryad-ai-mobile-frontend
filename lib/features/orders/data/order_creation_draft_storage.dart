import 'package:uuid/uuid.dart';
import '../../references/data/reference_storage.dart';

/// Coordinates forms sharing the same account's draft, including removed routes.
class OrderCreationDraftStorage {
  OrderCreationDraftStorage({required this.storage, required this.key});

  final ReferenceStorage storage;
  final String key;
  final String revision = const Uuid().v4();
  static final _pending = <String, Future<void>>{};
  static final _owners = <String, String>{};
  static final _versions = <String, int>{};
  int? _loadedVersion;

  void _changed() => _versions[key] = (_versions[key] ?? 0) + 1;

  Future<T> _serial<T>(Future<T> Function() operation) async {
    final result = (_pending[key] ?? Future<void>.value()).then(
      (_) => operation(),
    );
    final tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending[key] = tail;
    try {
      return await result;
    } finally {
      if (identical(_pending[key], tail)) _pending.remove(key);
    }
  }

  Future<List<Map<String, dynamic>>?> load() => _serial(() async {
    try {
      final values = await storage.read(key);
      _owners[key] = revision;
      _changed();
      return values;
    } finally {
      _loadedVersion = _versions[key] ?? 0;
    }
  });

  Future<void> save(
    Map<String, dynamic> data, {
    bool requireOwnership = false,
  }) => _serial(() async {
    if (_owners[key] != revision) {
      if (requireOwnership) {
        throw StateError("Черновик уже открыт в другой форме");
      }
      return;
    }
    await storage.write(key, [
      {...data, '_draftRevision': revision},
    ]);
    _changed();
  });

  Future<bool> clearSubmitted() => _serial(() async {
    if (_owners[key] != revision) return false;
    final values = await storage.read(key);
    if (values == null ||
        values.isEmpty ||
        values.first['_draftRevision'] != revision) {
      return false;
    }
    await storage.write(key, []);
    _owners.remove(key);
    _changed();
    return true;
  });

  /// Explicit discard also works when the stored JSON cannot be read.
  Future<bool> discardFailedLoad() => _serial(() async {
    if (_loadedVersion == null || _loadedVersion != (_versions[key] ?? 0)) {
      return false;
    }
    await storage.write(key, []);
    _owners[key] = revision;
    _changed();
    _loadedVersion = _versions[key];
    return true;
  });
}
