import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mineral/features/orders/data/order_creation_draft_storage.dart';
import 'package:mineral/features/references/data/reference_storage_io.dart';
import 'package:mineral/features/references/data/reference_storage_stub.dart';

class _DelayedWriteStorage extends MemoryReferenceStorage {
  final started = Completer<void>();
  final resume = Completer<void>();
  var delay = true;
  @override
  Future<void> write(String key, List<Map<String, dynamic>> items) async {
    if (delay) {
      delay = false;
      started.complete();
      await resume.future;
    }
    await super.write(key, items);
  }
}

void main() {
  test('discard is refused after another form changes the draft', () async {
    final storage = MemoryReferenceStorage();
    final failed = OrderCreationDraftStorage(
      storage: storage,
      key: 'discard-newer',
    );
    await storage.write(failed.key, [
      {'description': 123},
    ]);
    await failed.load();
    final next = OrderCreationDraftStorage(storage: storage, key: failed.key);
    await next.load();
    await next.save({'description': 'New'});
    expect(await failed.discardFailedLoad(), isFalse);
    expect((await storage.read(failed.key))!.single['description'], 'New');
  });

  test('explicit discard can replace unreadable JSON on disk', () async {
    final directory = await Directory.systemTemp.createTemp(
      'order-discard-test-',
    );
    addTearDown(() async {
      if (!directory.absolute.path.startsWith(
        '${Directory.systemTemp.absolute.path}${Platform.pathSeparator}',
      )) {
        throw StateError('Unexpected test directory');
      }
      await directory.delete(recursive: true);
    });
    final storage = FileReferenceStorage(directory: () async => directory);
    const key = 'discard-corrupt-json';
    await storage.write(key, [
      {'description': 'Old'},
    ]);
    final file = await Directory(
      '${directory.path}/references',
    ).list().where((entry) => entry is File).cast<File>().single;
    await file.writeAsString('{broken');
    final failed = OrderCreationDraftStorage(storage: storage, key: key);
    await expectLater(failed.load(), throwsA(isA<FormatException>()));
    expect(await failed.discardFailedLoad(), isTrue);
    expect(await storage.read(key), isEmpty);
    await failed.save({'description': 'New'});
    expect((await storage.read(key))!.single['description'], 'New');
  });

  test(
    'a newer form owns an unchanged draft immediately after loading',
    () async {
      final storage = MemoryReferenceStorage();
      final old = OrderCreationDraftStorage(
        storage: storage,
        key: 'draft-load',
      );
      await old.load();
      await old.save({'description': 'Old'});
      final next = OrderCreationDraftStorage(storage: storage, key: old.key);
      await next.load();
      expect(await old.clearSubmitted(), isFalse);
      expect((await storage.read(old.key))!.single['description'], 'Old');
      await next.save({'description': 'New'});
      expect(await old.clearSubmitted(), isFalse);
      expect((await storage.read(old.key))!.single['description'], 'New');
      expect(await next.clearSubmitted(), isTrue);
      expect(await storage.read(old.key), isEmpty);
    },
  );

  test(
    'queued writes from the removed form cannot overwrite the new form',
    () async {
      final storage = _DelayedWriteStorage();
      final old = OrderCreationDraftStorage(
        storage: storage,
        key: 'draft-writes',
      );
      await old.load();
      final firstWrite = old.save({'description': 'Old'});
      await storage.started.future;
      final next = OrderCreationDraftStorage(storage: storage, key: old.key);
      final claim = next.load();
      final staleWrite = old.save({'description': 'Stale'});
      storage.resume.complete();
      await firstWrite;
      await claim;
      await staleWrite;
      expect((await storage.read(old.key))!.single['description'], 'Old');
      await next.save({'description': 'New'});
      expect(await old.clearSubmitted(), isFalse);
      expect((await storage.read(old.key))!.single['description'], 'New');
    },
  );

  test('cleanup does not delete an unexpected stored revision', () async {
    final storage = MemoryReferenceStorage();
    final draft = OrderCreationDraftStorage(
      storage: storage,
      key: 'draft-revision',
    );
    await draft.load();
    await draft.save({'description': 'Old'});
    await storage.write(draft.key, [
      {'_draftRevision': 'other', 'description': 'New'},
    ]);
    expect(await draft.clearSubmitted(), isFalse);
    expect((await storage.read(draft.key))!.single['description'], 'New');
  });

  for (final claimFirst in [false, true]) {
    test(
      'file-backed cleanup and new claim are serialized; claimFirst=$claimFirst',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'order-draft-test-',
        );
        addTearDown(() async {
          final path = directory.absolute.path;
          if (!path.startsWith(
            '${Directory.systemTemp.absolute.path}${Platform.pathSeparator}',
          )) {
            throw StateError('Unexpected test directory');
          }
          await directory.delete(recursive: true);
        });
        final old = OrderCreationDraftStorage(
          storage: FileReferenceStorage(directory: () async => directory),
          key: 'file-$claimFirst',
        );
        final next = OrderCreationDraftStorage(
          storage: FileReferenceStorage(directory: () async => directory),
          key: old.key,
        );
        await old.load();
        await old.save({'description': 'Old'});
        final Future<bool> clear;
        final Future<List<Map<String, dynamic>>?> claim;
        if (claimFirst) {
          claim = next.load();
          clear = old.clearSubmitted();
        } else {
          clear = old.clearSubmitted();
          claim = next.load();
        }
        await claim;
        expect(await clear, !claimFirst);
        await next.save({'description': 'New'});
        expect(
          (await next.storage.read(next.key))!.single['description'],
          'New',
        );
      },
    );
  }
}
