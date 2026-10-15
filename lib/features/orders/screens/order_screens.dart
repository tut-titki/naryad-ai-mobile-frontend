import '../../master/widgets/master_ui.dart';
import 'dart:convert';
import 'dart:async';
import 'package:uuid/uuid.dart';

import '../../../shared/widgets/backend_section.dart';
import '../../auth/widgets/auth_scope.dart';
import '../../references/data/reference_storage.dart';
import '../../../shared/widgets/backend_refresh_view.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mineral/core/api/api_client.dart';
import 'package:mineral/core/api/api_services.dart';
import 'package:mineral/core/services/photo_picker_service.dart';

import 'package:mineral/features/orders/data/recommendations_api.dart';
import 'package:mineral/features/orders/data/order_creation_draft_storage.dart';
import 'package:mineral/features/orders/data/references_api.dart';
import 'package:mineral/features/orders/data/uploads_api.dart';
import 'package:mineral/features/orders/data/work_orders_api.dart';
import 'package:mineral/features/orders/models/work_order_api_models.dart';
import 'package:mineral/features/orders/widgets/photo_attachments.dart';
import '../widgets/voice_description_button.dart';

import 'package:mineral/l10n/ui_localization.dart';
import 'package:mineral/shared/models/models.dart';
import 'package:mineral/shared/widgets/ui.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({
    super.key,
    required this.api,
    this.photoPicker,
    this.initialEquipmentId,
    this.initialEquipment,
    this.initialArea,
    this.lockEquipment = false,
    this.draftStorage,
  }) : assert(!lockEquipment || initialEquipment != null);

  final ApiServices api;
  final int? initialEquipmentId;
  final EquipmentReference? initialEquipment;
  final AreaReference? initialArea;
  final bool lockEquipment;
  final ReferenceStorage? draftStorage;
  final PhotoPickerService? photoPicker;

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen>
    with WidgetsBindingObserver {
  final formKey = GlobalKey<FormState>();

  final descriptionController = TextEditingController();
  final descriptionFocus = FocusNode();

  final commentController = TextEditingController();
  String? creationKey;
  Map<String, dynamic>? creationPayload;

  late final PhotoPickerService photoPicker;

  // MARK: References

  List<AreaReference> areas = [];
  List<EquipmentReference> equipment = [];
  List<ExecutorReference> executors = [];
  List<NormativeReference> normatives = [];
  List<FaultCodeReference> faultCodes = [];
  List<BrigadeReference> brigades = [];
  bool assignBrigade = false;
  int? brigadeId;

  int? areaId;
  int? equipmentId;
  int? executorId;
  int? normativeId;
  int? faultCodeId;

  // MARK: Order

  WorkOrderType get type => priority == WorkOrderPriority.emergency
      ? WorkOrderType.emergency
      : WorkOrderType.planned;

  WorkOrderPriority priority = WorkOrderPriority.normal;

  bool useNormative = false;
  bool manualWork = false;
  bool manualExecutor = false;
  bool customDeadline = false;
  int deadlineHours = 2;
  Timer? recommendationTimer;
  Timer? draftTimer;
  ReferenceStorage? draftStorage;
  OrderCreationDraftStorage? creationDraftStorage;
  String? draftKey;
  bool issued = false;
  bool draftRestored = false;
  bool draftLoadFailed = false;
  bool discardingDraft = false;
  Future<void> draftWrites = Future.value();
  int recommendationVersion = 0;
  int equipmentVersion = 0;
  String equipmentSearch = '';
  final Map<String, WorkRecommendation> recommendationCache = {};

  DateTime deadline = DateTime.now().add(const Duration(hours: 2));

  // MARK: Photos

  final List<OrderPhoto> photos = [];
  int photoRecoveryVersion = 0;

  bool pickingPhotos = true;

  // MARK: Loading

  bool loadingReferences = true;
  bool loadingEquipment = false;
  bool loadingNormatives = false;
  bool loadingRecommendations = false;
  bool creating = false;
  bool voiceBusy = false;

  // MARK: Recommendations

  List<RecommendedExecutor> recommendedExecutors = [];

  WorkRecommendation? workRecommendation;

  String? pageError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    photoPicker = widget.photoPicker ?? PhotoPickerService.instance;

    descriptionController.addListener(scheduleRecommendation);
    restorePhotos();
    loadInitialData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    draftTimer?.cancel();
    if (!issued) saveDraft();
    recommendationTimer?.cancel();
    descriptionController.removeListener(scheduleRecommendation);
    descriptionFocus.dispose();
    descriptionController.dispose();
    commentController.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !issued) saveDraft();
  }

  String _executorStatusDetails(ExecutorReference item) {
    final status = !item.isOnShift
        ? EmployeeStatus.offShift.label
        : item.employeeStatus.label;
    return [
      uiText(context, status),
      if (item.currentOrder != null) '№${item.currentOrder!.number}',
      if (item.queue > 0)
        backendText(
          context,
          'В очереди: ${item.queue}',
          'Кезекте: ${item.queue}',
        ),
    ].join(' ');
  }

  Future<void> restoreDraft() async {
    draftLoadFailed = false;
    final owner = AuthScope.maybeOf(context)?.user?.id;
    if (owner == null && widget.draftStorage == null) return;
    draftStorage = widget.draftStorage ?? createReferenceStorage();
    draftKey =
        'order-draft:${widget.api.baseUrl}:${owner ?? 'test'}'
        '${widget.lockEquipment ? ':qr:${widget.initialEquipment!.id}' : ''}';
    creationDraftStorage ??= OrderCreationDraftStorage(
      storage: draftStorage!,
      key: draftKey!,
    );
    try {
      final values = await creationDraftStorage!.load();
      if (!mounted || values == null || values.isEmpty) return;
      final draft = values.first;
      creationKey = draft['creationKey'] as String?;
      final savedPayload = draft['creationPayload'];
      creationPayload = savedPayload == null
          ? null
          : Map<String, dynamic>.from(savedPayload as Map);
      if ((creationKey == null) != (creationPayload == null)) {
        throw const FormatException('Повреждены данные отправки наряда');
      }
      equipmentId = draft['equipmentId'] as int?;
      if (!equipment.any((e) => e.id == equipmentId)) equipmentId = null;
      descriptionController.text = draft['description'] as String? ?? '';
      commentController.text = draft['comment'] as String? ?? '';
      priority =
          WorkOrderPriority.values
              .where((p) => p.apiValue == draft['priority'])
              .firstOrNull ??
          WorkOrderPriority.normal;
      executorId = draft['executorId'] as int?;
      normativeId = draft['normativeId'] as int?;
      faultCodeId = draft['faultCodeId'] as int?;
      manualWork = draft['manualWork'] == true;
      manualExecutor = draft['manualExecutor'] == true;
      customDeadline = draft['customDeadline'] == true;
      deadline =
          DateTime.tryParse(draft['deadline'] as String? ?? '') ??
          DateTime.now().add(const Duration(hours: 2));
      deadlineHours = draft['deadlineHours'] as int? ?? 2;
      assignBrigade = draft['assignBrigade'] == true;
      brigadeId = draft['brigadeId'] as int?;
      if (!brigades.any((b) => b.id == brigadeId)) brigadeId = null;
      final savedPhotos = (draft['photos'] as List? ?? [])
          .take(5)
          .map(
            (p) => OrderPhoto(
              name: p['name'] as String,
              bytes: base64Decode(p['bytes'] as String),
              takenAt: DateTime.tryParse(p['takenAt'] as String? ?? ''),
            ),
          )
          .toList();
      photos.addAll(savedPhotos.take(5 - photos.length));
      setState(() {});
    } catch (_) {
      draftLoadFailed = true;
      rethrow;
    }
  }

  Future<void> saveDraft({bool beforeCreation = false}) {
    if (issued ||
        !draftRestored ||
        draftLoadFailed ||
        draftStorage == null ||
        draftKey == null) {
      if (beforeCreation) {
        return Future<void>.error(
          StateError("Не удалось сохранить данные перед отправкой"),
        );
      }
      return Future<void>.value();
    }
    final data = {
      'creationKey': creationKey,
      'creationPayload': creationPayload,
      'equipmentId': equipmentId,
      'description': descriptionController.text,
      'comment': commentController.text,
      'priority': priority.apiValue,
      'executorId': executorId,
      'normativeId': normativeId,
      'faultCodeId': faultCodeId,
      'manualWork': manualWork,
      'manualExecutor': manualExecutor,
      'customDeadline': customDeadline,
      'deadline': deadline.toIso8601String(),
      'deadlineHours': deadlineHours,
      'assignBrigade': assignBrigade,
      'brigadeId': brigadeId,
      'photos': [
        for (final p in photos)
          {
            'name': p.name,
            'bytes': base64Encode(p.bytes),
            'takenAt': p.takenAt?.toIso8601String(),
          },
      ],
    };
    final write = draftWrites.then(
      (_) => creationDraftStorage!.save(data, requireOwnership: beforeCreation),
    );
    draftWrites = write.catchError((Object _) {});
    return beforeCreation ? write : draftWrites;
  }

  Future<void> discardDraft() async {
    if (!draftLoadFailed || discardingDraft || creating) return;
    setState(() => discardingDraft = true);
    try {
      final s = strings(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(s.discardOrderDraftTitle),
          content: Text(s.discardOrderDraftMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              key: const ValueKey('confirm-discard-order-draft'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(s.discardOrderDraftAction),
            ),
          ],
        ),
      );
      if (!mounted || confirmed != true) return;
      await draftWrites;
      final discarded = await creationDraftStorage!.discardFailedLoad();
      if (!mounted) return;
      if (!discarded) {
        showMessage(context, strings(context).orderDraftChangedBeforeDiscard);
        return;
      }

      draftTimer?.cancel();
      recommendationTimer?.cancel();
      equipmentVersion++;
      recommendationVersion++;
      photoRecoveryVersion++;
      equipmentId = null;
      areaId = null;
      executorId = null;
      normativeId = null;
      faultCodeId = null;
      brigadeId = null;
      assignBrigade = false;
      manualWork = false;
      manualExecutor = false;
      useNormative = false;
      customDeadline = false;
      deadlineHours = 2;
      deadline = DateTime.now().add(const Duration(hours: 2));
      priority = WorkOrderPriority.normal;
      normatives = [];
      recommendedExecutors = [];
      workRecommendation = null;
      recommendationCache.clear();
      photos.clear();
      pickingPhotos = false;
      descriptionController.clear();
      commentController.clear();
      draftRestored = false;
      draftLoadFailed = false;
      await loadInitialData();
    } catch (_) {
      if (mounted) {
        showMessage(context, strings(context).orderDraftDiscardFailed);
      }
    } finally {
      if (mounted) setState(() => discardingDraft = false);
    }
  }

  // MARK: Initial data

  Future<void> refreshReferences() async {
    if (creating || voiceBusy || loadingEquipment || loadingNormatives) return;
    final selectedArea = areaId;
    final selectedEquipment = equipmentId;
    try {
      final refs = widget.api.references;
      final results = await Future.wait<Object>([
        refs.getAreas(refresh: true),
        refs.getExecutors(),
        refs.getFaultCodes(refresh: true),
        refs.getBrigades(refresh: true),
        refs.getEquipment(refresh: true),
        refs.getNormatives(equipmentId: selectedEquipment, refresh: true),
      ]);
      if (!mounted ||
          areaId != selectedArea ||
          equipmentId != selectedEquipment) {
        return;
      }
      setState(() {
        areas = results[0] as List<AreaReference>;
        executors = results[1] as List<ExecutorReference>;
        faultCodes = results[2] as List<FaultCodeReference>;
        brigades = results[3] as List<BrigadeReference>;
        equipment = results[4] as List<EquipmentReference>;
        mergeScannedEquipment();
        normatives = results[5] as List<NormativeReference>;
        if (!areas.any((item) => item.id == areaId)) {
          areaId = null;
          equipment = [];
        }
        if (!equipment.any((item) => item.id == equipmentId)) {
          equipmentId = null;
          normatives = [];
        }
        if (!normatives.any((item) => item.id == normativeId)) {
          normativeId = null;
        }
        if (!executors.any((item) => item.id == executorId)) executorId = null;
        if (!brigades.any((item) => item.id == brigadeId)) brigadeId = null;
        if (!faultCodes.any((item) => item.id == faultCodeId)) {
          faultCodeId = null;
        }
      });
    } catch (error) {
      if (mounted) showMessage(context, backendError(context, error));
    }
  }

  Future<void> loadInitialData() async {
    setState(() {
      loadingReferences = true;
      pageError = null;
    });

    try {
      final results = await Future.wait([
        widget.api.references.getAreas(),
        widget.api.references.getExecutors(),
        widget.api.references.getFaultCodes(),
        widget.api.references.getBrigades(),
        widget.api.references.getEquipment(),
      ]);

      if (!mounted) return;

      areas = results[0] as List<AreaReference>;

      executors = results[1] as List<ExecutorReference>;

      faultCodes = results[2] as List<FaultCodeReference>;
      brigades = results[3] as List<BrigadeReference>;

      equipment = results[4] as List<EquipmentReference>;
      mergeScannedEquipment();
      if (!draftRestored) {
        await restoreDraft();
        if (!mounted) return;
        draftRestored = true;
        saveDraft();
      }
      setState(() => loadingReferences = false);
      final restoredEquipment = equipmentId;
      final initial =
          widget.initialEquipment?.id ??
          widget.initialEquipmentId ??
          restoredEquipment;
      if (initial != null && equipment.any((e) => e.id == initial)) {
        await changeEquipment(
          initial,
          force: true,
          preserveManualSelection: restoredEquipment == initial,
        );
      }
    } on ApiException catch (error) {
      if (!mounted) return;

      setState(() {
        loadingReferences = false;
        pageError = draftLoadFailed
            ? strings(context).draftLoadFailed
            : error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loadingReferences = false;
        pageError = draftLoadFailed
            ? strings(context).draftLoadFailed
            : backendError(context, error);
      });
    }
  }

  // MARK: Area / equipment

  void mergeScannedEquipment() {
    final scanned = widget.initialEquipment;
    if (scanned == null) return;
    equipment = [scanned, ...equipment.where((item) => item.id != scanned.id)];
    final scannedArea = widget.initialArea;
    if (scannedArea != null) {
      areas = [
        scannedArea,
        ...areas.where((item) => item.id != scannedArea.id),
      ];
    }
  }

  Future<void> changeEquipment(
    int newEquipmentId, {
    bool force = false,
    bool preserveManualSelection = false,
  }) async {
    if (widget.lockEquipment && newEquipmentId != widget.initialEquipment!.id) {
      return;
    }
    if (!force && equipmentId == newEquipmentId) {
      return;
    }

    final keepSelection =
        preserveManualSelection && equipmentId == newEquipmentId;
    final selectionVersion = ++equipmentVersion;
    final initialDescription = descriptionController.text.trim();
    final initialBrigade = assignBrigade ? brigadeId : null;

    setState(() {
      equipmentId = newEquipmentId;
      areaId = equipment.firstWhere((e) => e.id == newEquipmentId).areaId;
      if (!keepSelection) {
        manualWork = false;
        manualExecutor = false;
        useNormative = false;
        executorId = null;
        normativeId = null;
        faultCodeId = null;
      }

      recommendationVersion++;
      normatives = [];
      recommendedExecutors = [];
      workRecommendation = null;

      loadingNormatives = true;
      loadingRecommendations = true;
    });

    bool selectionCurrent() =>
        equipmentId == newEquipmentId && equipmentVersion == selectionVersion;

    try {
      final results = await Future.wait([
        widget.api.references.getNormatives(equipmentId: newEquipmentId),
        widget.api.recommendations
            .getRecommendedExecutors(
              equipmentId: newEquipmentId,
              description: descriptionController.text,
              faultCodeId: faultCodeId,
              brigadeId: initialBrigade,
            )
            .catchError((_) => <RecommendedExecutor>[]),
      ]);

      if (!mounted || !selectionCurrent()) return;

      final loadedNormatives = results[0] as List<NormativeReference>;

      final recommendations = results[1] as List<RecommendedExecutor>;

      setState(() {
        normatives = loadedNormatives;

        // Validate the current selection only after a successful load.
        if (keepSelection && manualWork) {
          if (!normatives.any((n) => n.id == normativeId)) {
            normativeId = null;
          }
          if (!faultCodes.any((f) => f.id == faultCodeId)) {
            faultCodeId = null;
          }
          useNormative = normativeId != null && !customDeadline;
        }
        if (keepSelection &&
            manualExecutor &&
            !executors.any((e) => e.id == executorId)) {
          executorId = null;
        }

        if (descriptionController.text.trim() == initialDescription &&
            initialBrigade == (assignBrigade ? brigadeId : null)) {
          recommendedExecutors = recommendations;
          if (!manualExecutor) executorId = recommendations.firstOrNull?.id;
        }
        loadingNormatives = false;
        loadingRecommendations = false;
      });
      scheduleRecommendation();
    } on ApiException catch (error) {
      if (!mounted || !selectionCurrent()) return;
      setState(() {
        loadingNormatives = false;
        loadingRecommendations = false;
      });
      showMessage(context, error.message);
    } catch (error) {
      if (!mounted || !selectionCurrent()) return;
      setState(() {
        loadingNormatives = false;
        loadingRecommendations = false;
      });
      showMessage(context, backendError(context, error));
    }
  }

  // MARK: AI recommendation

  void scheduleRecommendation() {
    recommendationTimer?.cancel();
    recommendationVersion++;
    if (!mounted || creating) return;
    setState(() {
      if (!manualWork) {
        workRecommendation = null;
        faultCodeId = null;
        normativeId = null;
        useNormative = false;
      }
    });
    if (equipmentId == null) return;
    if (descriptionController.text.trim().length < 3) {
      setState(() => loadingRecommendations = false);
      return;
    }
    recommendationTimer = Timer(
      const Duration(milliseconds: 800),
      requestWorkRecommendation,
    );
    setState(() {});
  }

  Future<void> requestWorkRecommendation() async {
    final selectedEquipment = equipmentId;
    final description = descriptionController.text.trim();
    if (selectedEquipment == null || description.length < 3 || creating) return;
    final version = ++recommendationVersion;
    bool current() =>
        mounted &&
        !creating &&
        version == recommendationVersion &&
        equipmentId == selectedEquipment;
    setState(() => loadingRecommendations = true);
    bool fullApplied = false;
    Future<void> request(bool fast) async {
      try {
        final key = '$selectedEquipment:$description:$fast';
        final result =
            recommendationCache[key] ??
            await widget.api.recommendations
                .getWorkRecommendation(
                  description: description,
                  equipmentId: selectedEquipment,
                  fast: fast,
                )
                .timeout(const Duration(seconds: 30));
        recommendationCache[key] = result;
        if (!current() || (fast && fullApplied)) return;
        if (!fast) fullApplied = true;
        setState(() {
          workRecommendation = result;
          if (result.normative != null &&
              !normatives.any((n) => n.id == result.normative!.id)) {
            normatives = [...normatives, result.normative!];
          }
          if (result.faultCode != null &&
              !faultCodes.any((f) => f.id == result.faultCode!.id)) {
            faultCodes = [...faultCodes, result.faultCode!];
          }
          if (!manualWork) {
            faultCodeId = result.faultCodeId;
            normativeId = result.normativeId;
            useNormative = normativeId != null && !customDeadline;
          }
        });
        await updateRecommendedExecutors(version);
      } catch (_) {
        // Suggestions are optional: issuance remains available with a two-hour deadline.
      }
    }

    await Future.wait([request(true), request(false)]);
    if (current()) setState(() => loadingRecommendations = false);
  }

  Future<void> updateRecommendedExecutors([int? expectedVersion]) async {
    final selectedEquipment = equipmentId;
    if (selectedEquipment == null) return;
    final version = expectedVersion ?? recommendationVersion;
    final selectedBrigade = assignBrigade ? brigadeId : null;
    final selectedFault = faultCodeId;
    try {
      final result = await widget.api.recommendations.getRecommendedExecutors(
        equipmentId: selectedEquipment,
        description: descriptionController.text.trim(),
        faultCodeId: selectedFault,
        brigadeId: selectedBrigade,
      );
      if (!mounted ||
          creating ||
          version != recommendationVersion ||
          equipmentId != selectedEquipment ||
          selectedFault != faultCodeId ||
          selectedBrigade != (assignBrigade ? brigadeId : null)) {
        return;
      }
      setState(() {
        recommendedExecutors = result;
        if (!manualExecutor) {
          executorId = result.firstOrNull?.id;
        }
      });
    } catch (_) {}
  }

  // MARK: Photos

  Future<void> restorePhotos() async {
    final version = photoRecoveryVersion;
    try {
      final restored = await photoPicker.takeRecoveredPhotos();

      if (!mounted || version != photoRecoveryVersion) return;

      setState(() {
        photos.addAll(restored.take(5 - photos.length));
      });
    } finally {
      if (mounted && version == photoRecoveryVersion) {
        setState(() {
          pickingPhotos = false;
        });
      }
    }
  }

  Future<void> addPhotos({required bool camera}) async {
    if (pickingPhotos || photos.length >= 5) {
      return;
    }

    setState(() {
      pickingPhotos = true;
    });

    try {
      final selected = camera
          ? await photoPicker.pickCamera()
          : await photoPicker.pickGallery(5 - photos.length);

      if (!mounted) return;

      setState(() {
        photos.addAll(selected.take(5 - photos.length));
      });
    } on PlatformException catch (error) {
      if (!mounted) return;

      final code = error.code.toLowerCase();

      final denied = code.contains('access') || code.contains('permission');

      showMessage(
        context,
        denied
            ? 'Разрешите доступ к камере или фото в настройках приложения.'
            : 'Не удалось открыть камеру или галерею.',
      );
    } catch (_) {
      if (!mounted) return;

      showMessage(context, 'Не удалось выбрать фотографию.');
    } finally {
      if (mounted) {
        setState(() {
          pickingPhotos = false;
        });
      }
    }
  }

  // MARK: Deadline

  Future<void> selectDeadline() async {
    final now = DateTime.now();
    final firstDate = DateUtils.dateOnly(now);
    final lastDate = DateTime(now.year, now.month, now.day + 365);
    final savedDate = DateUtils.dateOnly(deadline.toLocal());
    final initialDate = savedDate.isBefore(firstDate)
        ? firstDate
        : savedDate.isAfter(lastDate)
        ? lastDate
        : savedDate;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: uiText(context, 'Срок исполнения'),
      cancelText: uiText(context, 'Отмена'),
      confirmText: uiText(context, 'Выбрать'),
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(deadline),
      helpText: uiText(context, 'Время исполнения'),
      cancelText: uiText(context, 'Отмена'),
      confirmText: uiText(context, 'Выбрать'),
    );

    if (time == null || !mounted) {
      return;
    }

    setState(() {
      customDeadline = true;
      useNormative = false;
      deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // MARK: Create order

  Future<void> submit() async {
    if (issued ||
        discardingDraft ||
        creating ||
        pickingPhotos ||
        loadingReferences ||
        !draftRestored ||
        draftLoadFailed ||
        voiceBusy) {
      return;
    }

    final selectedAreaId = areaId;
    final selectedEquipmentId = equipmentId;
    final selectedExecutorId = executorId;

    if (creationPayload == null) {
      if (!formKey.currentState!.validate()) {
        return;
      }

      if (selectedAreaId == null) {
        showMessage(context, 'Выберите участок.');
        return;
      }

      if (selectedEquipmentId == null) {
        showMessage(context, 'Выберите оборудование.');
        return;
      }

      if (!assignBrigade && selectedExecutorId == null) {
        showMessage(context, 'Выберите исполнителя.');
        return;
      }

      if (assignBrigade && brigadeId == null) {
        showMessage(
          context,
          backendText(context, 'Выберите бригаду', 'Бригаданы таңдаңыз'),
        );
        return;
      }

      if (useNormative && normativeId == null) {
        showMessage(context, 'Выберите норматив.');
        return;
      }

      if (customDeadline && !deadline.isAfter(DateTime.now())) {
        showMessage(context, 'Выберите срок в будущем.');
        return;
      }
    }

    setState(() {
      creating = true;
      recommendationVersion++;
      recommendationTimer?.cancel();
    });

    try {
      if (creationPayload == null) {
        // Capture the form before uploading; a disposed form cannot be read later.
        final beforePhotoUrls = <String>[];
        final input = CreateWorkOrderInput(
          type: type,
          description: descriptionController.text.trim(),
          areaId: selectedAreaId!,
          equipmentId: selectedEquipmentId!,
          assigneeId: assignBrigade ? null : selectedExecutorId,
          brigadeId: assignBrigade ? brigadeId : null,
          priority: priority,
          normativeId: normativeId,
          faultCodeId: faultCodeId,
          deadline: customDeadline
              ? deadline.toUtc()
              : normativeId != null
              ? null
              : DateTime.now().add(Duration(hours: deadlineHours)).toUtc(),
          comment: commentController.text.trim().isEmpty
              ? null
              : commentController.text.trim(),
          beforePhotoUrls: beforePhotoUrls,
        );
        // Сначала загружаем фотографии.
        //
        // POST /api/uploads не является
        // идемпотентным, поэтому здесь
        // нет автоматического retry.
        final uploadFiles = photos
            .map(
              (photo) => UploadFileInput(
                bytes: photo.bytes,
                fileName: photo.name,
                takenAt: photo.takenAt,
              ),
            )
            .toList(growable: false);

        if (uploadFiles.isNotEmpty) {
          beforePhotoUrls.addAll(
            await widget.api.uploads.uploadPhotoUrls(uploadFiles),
          );
        }
        // Затем создаём сам наряд.
        //
        // POST /api/work-orders также
        // нельзя автоматически повторять.
        input.validate();
        creationKey ??= const Uuid().v4();
        creationPayload = Map<String, dynamic>.from(
          jsonDecode(jsonEncode(input.toJson())) as Map,
        );
      }

      await saveDraft(beforeCreation: true);
      final created = await widget.api.workOrders.createWorkOrderFromSnapshot(
        creationPayload!,
        creationKey: creationKey!,
      );

      // Server acknowledgement must clear the draft even after route removal.
      issued = true;
      draftTimer?.cancel();
      await draftWrites;
      if (draftStorage != null && draftKey != null) {
        try {
          await creationDraftStorage!.clearSubmitted();
        } catch (_) {}
      }
      if (mounted) Navigator.pop(context, created.id);
    } on ApiException catch (error) {
      if (!mounted) return;

      showMessage(context, error.message);
    } catch (error) {
      if (!mounted) return;

      showMessage(
        context,
        backendText(
          context,
          'Соединение оборвалось. Проверьте список нарядов, прежде чем создавать снова.',
          'Байланыс үзілді. Қайта жасамас бұрын нарядтар тізімін тексеріңіз.',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          creating = false;
        });
      }
    }
  }

  // MARK: Helpers

  ExecutorReference? findExecutor(int id) {
    for (final executor in executors) {
      if (executor.id == id) {
        return executor;
      }
    }

    return null;
  }

  RecommendedExecutor? findRecommendation(int id) {
    for (final executor in recommendedExecutors) {
      if (executor.id == id) {
        return executor;
      }
    }

    return null;
  }

  Color employeeStatusColor(EmployeeStatus status) {
    return switch (status) {
      EmployeeStatus.available => const Color(0xFF059669),
      EmployeeStatus.busy => const Color(0xFFF59E0B),
      EmployeeStatus.queued => const Color(0xFF2563EB),
      EmployeeStatus.offShift => const Color(0xFF94A3B8),
      EmployeeStatus.unknown => const Color(0xFF94A3B8),
    };
  }

  DropdownMenuItem<int> _brigadeOption(BrigadeReference brigade) {
    final status = brigade.assignmentStatus(executors);
    final label = switch (status) {
      EmployeeStatus.available => uiText(context, 'Свободна'),
      EmployeeStatus.busy || EmployeeStatus.queued => uiText(context, 'Занята'),
      EmployeeStatus.offShift ||
      EmployeeStatus.unknown => uiText(context, status.label),
    };
    return DropdownMenuItem<int>(
      value: brigade.id,
      enabled: status != EmployeeStatus.offShift,
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: status.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uiText(context, brigade.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(color: status.color, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String employeeStatusLabel(EmployeeStatus status) {
    return switch (status) {
      EmployeeStatus.available => 'Свободен',
      EmployeeStatus.busy => 'В работе',
      EmployeeStatus.queued => 'В очереди',
      EmployeeStatus.offShift => 'Не на смене',
      EmployeeStatus.unknown => 'Неизвестно',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: brand,
          onPrimary: Colors.white,
          secondary: brand,
          onSecondary: Colors.white,
          secondaryContainer: lightBlue,
          onSecondaryContainer: brand,
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.selected) ? brand : Colors.white,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) =>
                  states.contains(WidgetState.selected) ? Colors.white : ink,
            ),
          ),
        ),
      ),
      child: PopScope(
        canPop: !creating && !discardingDraft,
        child: MasterScaffold(
          backgroundColor: MasterColors.background,
          appBar: AppBar(
            title: Text(
              uiText(context, 'Создание наряда'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          bottomNavigationBar: _buildBottomBar(),
          body: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('issue-order'),
                  style: priority == WorkOrderPriority.emergency
                      ? FilledButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                        )
                      : null,
                  onPressed:
                      issued ||
                          discardingDraft ||
                          creating ||
                          loadingReferences ||
                          !draftRestored ||
                          draftLoadFailed ||
                          pickingPhotos ||
                          voiceBusy ||
                          (creationPayload == null && missingInput != null)
                      ? null
                      : submit,
                  icon: creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    !creating && creationPayload != null
                        ? backendText(
                            context,
                            'Повторить сохранённый наряд',
                            'Сақталған нарядты қайта жіберу',
                          )
                        : uiText(
                            context,
                            creating
                                ? 'Создание...'
                                : missingInput ?? 'Выдать наряд',
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (draftRestored && !issued && draftStorage != null) {
      draftTimer?.cancel();
      draftTimer = Timer(const Duration(milliseconds: 350), saveDraft);
    }
    if (loadingReferences) {
      return const Center(child: CircularProgressIndicator());
    }

    if (pageError != null) {
      return BackendRefreshView(
        onRefresh: () async {
          if (!discardingDraft) await loadInitialData();
        },
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42, color: Colors.red),
              const SizedBox(height: 16),
              Text(pageError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: discardingDraft ? null : loadInitialData,
                icon: const Icon(Icons.replay),
                label: Text(uiText(context, 'Повторить')),
              ),
              if (draftLoadFailed) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const ValueKey('discard-order-draft'),
                  onPressed: discardingDraft ? null : discardDraft,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(strings(context).discardOrderDraftAction),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return BackendRefreshView(
      onRefresh: refreshReferences,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),

                if (!issued && creationPayload != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      backendText(
                        context,
                        'Отправка не подтверждена. Повтор отправит сохранённые '
                            'данные предыдущей попытки. Изменения формы '
                            'в этот повтор не попадут.',
                        'Жіберу расталмады. Қайта жібергенде алдыңғы әрекеттің '
                            'сақталған деректері жіберіледі. Формадағы өзгерістер '
                            'бұл қайта жіберуге қосылмайды.',
                      ),
                      key: const ValueKey('saved-order-retry-notice'),
                    ),
                  ),

                const SizedBox(height: 24),

                _buildEquipment(),
                _buildDescription(),
                _buildQuickSummary(),
                _buildExecutors(),
                ExpansionTile(
                  key: const ValueKey('order-advanced'),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  childrenPadding: const EdgeInsets.all(12),
                  backgroundColor: Colors.white,
                  collapsedBackgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  collapsedShape: RoundedRectangleBorder(
                    side: const BorderSide(color: border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  leading: const Icon(Icons.tune_rounded, color: brand),
                  title: Text(backendText(context, 'Дополнительно', 'Қосымша')),
                  children: [
                    _buildPlace(),
                    _buildDeadline(),
                    PhotoAttachments(
                      framed: false,
                      title: 'Фото неисправности · до 5',
                      photos: photos,
                      busy: pickingPhotos,
                      onCamera: photoPicker.supportsCamera
                          ? () => addPhotos(camera: true)
                          : null,
                      onGallery: () => addPhotos(camera: false),
                      onRemove: (index) {
                        setState(() {
                          photos.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? get missingInput {
    if (equipmentId == null) return 'Выберите оборудование';
    if (descriptionController.text.trim().length < 3) {
      return backendText(context, 'Опишите проблему', 'Мәселені сипаттаңыз');
    }
    if (assignBrigade ? brigadeId == null : executorId == null) {
      return assignBrigade ? 'Выберите бригаду' : 'Выберите исполнителя';
    }
    return null;
  }

  Widget _buildEquipment() {
    final selected = equipment.where((e) => e.id == equipmentId).firstOrNull;
    if (selected != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _selectionCard(
          key: const ValueKey('select-equipment'),
          title: uiText(context, 'Оборудование'),
          placeholder: '',
          value: selected,
          label: (e) => uiText(context, e.name),
          details: (e) => equipmentDetails(e),
          icon: Icons.precision_manufacturing_outlined,
          onTap: creating || voiceBusy || widget.lockEquipment
              ? null
              : _selectEquipment,
        ),
      );
    }
    final query = equipmentSearch.toLowerCase();
    final items = equipment
        .where(
          (e) =>
              '${e.name} ${e.inventoryNumber ?? ''} ${e.type ?? ''} ${equipmentDetails(e)}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return _OrderFormSection(
      title: 'Оборудование',
      icon: Icons.precision_manufacturing_outlined,
      child: Column(
        children: [
          TextField(
            key: const ValueKey('equipment-search'),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: backendText(context, 'Поиск', 'Іздеу'),
            ),
            onChanged: (value) => setState(() => equipmentSearch = value),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(backendText(context, 'Ничего не найдено', 'Ештеңе табылмады')),
          if (items.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: Material(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      key: ValueKey('equipment-${item.id}'),
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.precision_manufacturing_outlined,
                        color: brand,
                      ),
                      title: Text(
                        uiText(context, item.name),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(equipmentDetails(item)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: creating || voiceBusy
                          ? null
                          : () {
                              changeEquipment(item.id);
                              focusDescription();
                            },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  void focusDescription() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      descriptionFocus.requestFocus();
      final fieldContext = descriptionFocus.context;
      if (fieldContext != null) {
        Scrollable.ensureVisible(
          fieldContext,
          duration: const Duration(milliseconds: 250),
        );
      }
    });
  }

  String equipmentDetails(EquipmentReference item) => [
    item.inventoryNumber,
    areas
        .where((a) => a.id == item.areaId)
        .map((a) => uiText(context, a.name))
        .firstOrNull,
    if (item.criticality != null)
      backendText(
        context,
        'Критичность: ${item.criticality}/5',
        'Маңыздылық: ${item.criticality}/5',
      ),
  ].whereType<String>().join(' · ');

  Widget _buildQuickSummary() {
    if (equipmentId == null) return const SizedBox.shrink();
    final fault = faultCodes.where((f) => f.id == faultCodeId).firstOrNull;
    final norm = normatives.where((n) => n.id == normativeId).firstOrNull;
    final summaryDeadline = customDeadline
        ? deadline
        : DateTime.now().add(
            Duration(
              minutes: ((norm?.hoursValue ?? deadlineHours) * 60).round(),
            ),
          );
    final summaryDeadlineLabel =
        '${dateLabel(summaryDeadline)} · ${timeLabel(summaryDeadline)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loadingRecommendations
                ? backendText(context, 'ИИ уточняет…', 'ЖИ нақтылауда…')
                : uiText(context, 'Срок исполнения'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (fault != null)
            Text('${fault.code} · ${uiText(context, fault.name)}'),
          if (norm != null)
            Text(uiText(context, '${norm.name} · ${norm.hours} ч.')),
          if (workRecommendation?.explanation != null)
            Text(uiText(context, workRecommendation!.explanation!)),
          if (normativeId == null && !customDeadline) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final hours in [1, 2, 4, 8])
                  ChoiceChip(
                    label: Text(backendText(context, '$hours ч', '$hours сағ')),
                    selected: deadlineHours == hours,
                    onSelected: creating
                        ? null
                        : (_) => setState(() => deadlineHours = hours),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            backendText(
              context,
              'До $summaryDeadlineLabel',
              '$summaryDeadlineLabel дейін',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutors() {
    if (equipmentId == null || assignBrigade) return const SizedBox.shrink();
    return _OrderFormSection(
      title: 'Исполнитель',
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in recommendedExecutors.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: executorId == item.id ? lightBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: ValueKey('executor-${item.id}'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  title: Text(
                    item.fullName,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        uiText(context, item.statusLabel),
                        style: TextStyle(color: item.employeeStatus.color),
                      ),
                      if (item.specialty != null || item.grade != null)
                        Text(
                          [
                            if (item.specialty != null)
                              uiText(context, item.specialty!),
                            if (item.grade != null)
                              uiText(context, '${item.grade} разряд'),
                          ].join(' · '),
                          style: const TextStyle(fontSize: 12, color: muted),
                        ),
                      if (item.id == recommendedExecutors.first.id)
                        Text(
                          backendText(context, 'ИИ рекомендует', 'ЖИ ұсынады'),
                          style: const TextStyle(color: brand),
                        ),
                      for (final reason in item.reasons.skip(1))
                        Text(uiText(context, reason)),
                      if (item.equipmentRating != null)
                        Text('★ ${item.ratingLabel} · ${item.equipmentOrders}'),
                    ],
                  ),
                  trailing: Icon(
                    executorId == item.id
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: brand,
                  ),
                  onTap: creating
                      ? null
                      : () => setState(() {
                          executorId = item.id;
                          manualExecutor = true;
                        }),
                ),
              ),
            ),
          if (recommendedExecutors.isEmpty && !loadingRecommendations)
            Text(
              backendText(
                context,
                'На смене нет исполнителей',
                'Ауысымда орындаушылар жоқ',
              ),
            ),
          OutlinedButton(
            key: const ValueKey('select-executor'),
            onPressed: creating ? null : _selectExecutor,
            child: Text(
              backendText(
                context,
                'Все исполнители (${executors.length})',
                'Барлық орындаушылар (${executors.length})',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final stages = [
      (uiText(context, 'Оборудование'), equipmentId != null),
      (
        uiText(context, 'Описание работ'),
        descriptionController.text.trim().length >= 3,
      ),
      (
        uiText(context, 'Исполнитель'),
        assignBrigade ? brigadeId != null : executorId != null,
      ),
    ];
    return MasterSurface(
      color: MasterColors.tint,
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          for (var index = 0; index < stages.length; index++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  stages[index].$2
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: brand,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  stages[index].$1,
                  style: const TextStyle(
                    fontSize: 12,
                    color: brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return _OrderFormSection(
      title: 'Описание работ',
      icon: Icons.edit_note_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const ValueKey('order-description'),
            focusNode: descriptionFocus,
            controller: descriptionController,
            readOnly: creating,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: uiText(context, 'Проблема и необходимые работы'),
            ),
            validator: (value) {
              final text = value?.trim() ?? '';

              if (text.length < 3) {
                return uiText(context, 'Описание — минимум 3 символа');
              }

              return null;
            },
          ),
          const SizedBox(height: 12),
          VoiceDescriptionButton(
            api: widget.api,
            enabled: !creating,
            onBusyChanged: (busy) => setState(() => voiceBusy = busy),
            onText: (text) {
              descriptionController.text = [
                descriptionController.text.trim(),
                text.trim(),
              ].where((part) => part.isNotEmpty).join(' ');
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in WorkOrderPriority.values)
                ChoiceChip(
                  key: ValueKey('priority-${value.apiValue}'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  selectedColor: lightBlue,
                  backgroundColor: Colors.white,
                  side: BorderSide(color: priority == value ? brand : border),
                  label: Text(uiText(context, value.label)),
                  selected: priority == value,
                  onSelected: creating
                      ? null
                      : (_) => setState(() => priority = value),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlace() {
    return _OrderFormSection(
      title: 'Место и исполнитель',
      icon: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text(uiText(context, 'Исполнитель')),
              ),
              ButtonSegment(
                value: true,
                label: Text(backendText(context, 'Бригада', 'Бригада')),
              ),
            ],
            selected: {assignBrigade},
            onSelectionChanged: creating
                ? null
                : (value) {
                    setState(() {
                      assignBrigade = value.first;
                      manualExecutor = false;
                      executorId = null;
                    });
                    updateRecommendedExecutors();
                  },
          ),
          const SizedBox(height: 16),
          if (assignBrigade)
            DropdownButtonFormField<int>(
              key: ValueKey('brigade-$brigadeId'),
              initialValue: brigadeId,
              isExpanded: true,
              isDense: false,
              itemHeight: 64,
              decoration: InputDecoration(
                labelText: backendText(context, 'Бригада', 'Бригада'),
              ),
              items: [for (final brigade in brigades) _brigadeOption(brigade)],
              onChanged: creating
                  ? null
                  : (id) {
                      setState(() {
                        brigadeId = id;
                        manualExecutor = false;
                        executorId = null;
                      });
                      updateRecommendedExecutors();
                    },
              validator: (id) {
                if (id == null) return strings(context).selectBrigade;
                final brigade = brigades
                    .where((item) => item.id == id)
                    .firstOrNull;
                if (brigade == null) return strings(context).selectBrigade;
                if (brigade.assignmentStatus(executors) ==
                    EmployeeStatus.offShift) {
                  return strings(context).brigadeOffShift;
                }
                return null;
              },
            ),
          if (!assignBrigade)
            _selectionCard(
              key: const ValueKey('select-executor'),
              title: uiText(context, 'Исполнитель'),
              placeholder: uiText(context, 'Выберите исполнителя'),
              value: executorId == null ? null : findExecutor(executorId!),
              label: (item) => item.fullName,
              details: _executorStatusDetails,
              icon: Icons.person_outline,
              onTap: creating ? null : _selectExecutor,
            ),
        ],
      ),
    );
  }

  Widget _selectionCard<T extends Object>({
    required Key key,
    required String title,
    required String placeholder,
    required T? value,
    required String Function(T) label,
    required String Function(T) details,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return OutlinedButton(
      key: key,
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: muted)),
                const SizedBox(height: 3),
                Text(
                  value == null ? placeholder : label(value),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (value != null && details(value).isNotEmpty)
                  Text(
                    details(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.search_rounded, color: brand, size: 20),
        ],
      ),
    );
  }

  Future<T?> _pickOption<T extends Object>({
    required String title,
    required List<T> items,
    required String Function(T) label,
    required String Function(T) details,
    required bool Function(T) enabled,
    required bool Function(T) selected,
    required Widget Function(T) leading,
  }) async {
    String query = '';

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, update) {
            final normalizedQuery = query.trim().toLowerCase();

            final filtered = items.where((item) {
              final haystack = '${label(item)} ${details(item)}'.toLowerCase();

              return haystack.contains(normalizedQuery);
            }).toList();

            final keyboard = MediaQuery.viewInsetsOf(sheetContext).bottom;

            final height = MediaQuery.sizeOf(sheetContext).height - keyboard;

            return Padding(
              padding: EdgeInsets.only(bottom: keyboard),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: height * .7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Text(
                          uiText(sheetContext, title),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search_rounded),
                            hintText: backendText(context, 'Поиск', 'Іздеу'),
                          ),
                          onChanged: (value) {
                            query = value;

                            update(() {});
                          },
                        ),
                      ),

                      const SizedBox(height: 8),

                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  uiText(
                                    context,
                                    'По вашему запросу ничего не найдено',
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final item = filtered[index];

                                  return ListTile(
                                    leading: leading(item),
                                    title: Text(label(item)),
                                    subtitle: Text(details(item)),
                                    trailing: selected(item)
                                        ? const Icon(Icons.check, color: brand)
                                        : null,
                                    enabled: enabled(item),
                                    onTap: enabled(item)
                                        ? () {
                                            Navigator.pop(sheetContext, item);
                                          }
                                        : null,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectEquipment() async {
    try {
      final items = equipment;
      if (!mounted) return;
      final selected = await _pickOption<EquipmentReference>(
        title: uiText(context, 'Оборудование'),
        items: items,
        label: (item) => uiText(context, item.name),
        details: (item) => [
          areas
              .where((area) => area.id == item.areaId)
              .map((area) => uiText(context, area.name))
              .firstOrNull,
          item.inventoryNumber,
        ].whereType<String>().join(' · '),
        enabled: (_) => true,
        selected: (item) => item.id == equipmentId,
        leading: (_) => const Icon(Icons.precision_manufacturing_outlined),
      );
      if (!mounted || selected == null || selected.id == equipmentId) return;
      await changeEquipment(selected.id);
      if (mounted) focusDescription();
    } catch (error) {
      if (mounted) showMessage(context, backendError(context, error));
    }
  }

  Future<void> _selectExecutor() async {
    final recommendedIds = recommendedExecutors.map((item) => item.id).toSet();
    final ordered = [
      ...executors.where((item) => recommendedIds.contains(item.id)),
      ...executors.where((item) => !recommendedIds.contains(item.id)),
    ];
    final selected = await _pickOption<ExecutorReference>(
      title: uiText(context, 'Исполнитель'),
      items: ordered,
      label: (item) => item.fullName,
      details: (item) => [
        if (item.specialty?.trim().isNotEmpty == true)
          uiText(context, item.specialty!.trim()),
        _executorStatusDetails(item),
      ].join(' · '),
      enabled: (_) => true,
      selected: (item) => item.id == executorId,
      leading: (item) => Icon(
        Icons.circle,
        size: 12,
        color: employeeStatusColor(item.employeeStatus),
      ),
    );
    if (mounted && selected != null) {
      setState(() {
        executorId = selected.id;
        manualExecutor = true;
        assignBrigade = false;
      });
    }
  }

  Widget _buildDeadline() {
    return _OrderFormSection(
      title: 'Срок и приоритет',
      icon: Icons.schedule_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: true,
                label: Text(uiText(context, 'Норматив')),
              ),
              ButtonSegment(
                value: false,
                label: Text(uiText(context, 'Дата и время')),
              ),
            ],
            selected: {useNormative},
            onSelectionChanged: creating
                ? null
                : (value) {
                    setState(() {
                      useNormative = value.first;
                      manualWork = true;
                      customDeadline = !useNormative;
                      if (!useNormative) {
                        normativeId = null;
                        final now = DateTime.now();
                        if (!deadline.isAfter(now)) {
                          deadline = now.add(Duration(hours: deadlineHours));
                        }
                      }
                    });
                  },
          ),

          const SizedBox(height: 16),

          if (useNormative) ...[
            if (loadingNormatives) const LinearProgressIndicator(),

            if (loadingNormatives) const SizedBox(height: 12),

            DropdownButtonFormField<int>(
              key: ValueKey('normative-$equipmentId-$normativeId'),
              initialValue: normativeId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: uiText(context, 'Норматив'),
              ),
              items: [
                for (final normative in normatives)
                  DropdownMenuItem(
                    value: normative.id,
                    child: Text(
                      uiText(
                        context,
                        '${normative.name} · ${normative.hours} ч.',
                      ),
                    ),
                  ),
              ],
              onChanged: creating || loadingNormatives
                  ? null
                  : (value) {
                      setState(() {
                        normativeId = value;
                        faultCodeId = normatives
                            .where((n) => n.id == value)
                            .firstOrNull
                            ?.faultCodeId;
                        manualWork = true;
                        customDeadline = false;
                      });
                      updateRecommendedExecutors();
                    },
              validator: (value) {
                if (!useNormative) {
                  return null;
                }

                return value == null
                    ? uiText(context, 'Выберите норматив')
                    : null;
              },
            ),
          ] else
            OutlinedButton.icon(
              onPressed: creating ? null : selectDeadline,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                uiText(
                  context,
                  '${dateLabel(deadline)} · ${timeLabel(deadline)}',
                ),
              ),
            ),

          const SizedBox(height: 16),

          DropdownButtonFormField<int>(
            key: ValueKey('fault-$faultCodeId'),
            initialValue: faultCodeId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: backendText(
                context,
                'Код неисправности (необязательно)',
                'Ақау коды (міндетті емес)',
              ),
            ),
            items: [
              DropdownMenuItem<int>(
                value: null,
                child: Text(uiText(context, 'Не указан')),
              ),
              for (final fault in faultCodes)
                DropdownMenuItem(
                  value: fault.id,
                  child: Text('${fault.code} · ${uiText(context, fault.name)}'),
                ),
            ],
            onChanged: creating
                ? null
                : (value) {
                    setState(() {
                      faultCodeId = value;
                      manualWork = true;
                      normativeId = normatives
                          .where((n) => n.faultCodeId == value)
                          .firstOrNull
                          ?.id;
                      useNormative = normativeId != null && !customDeadline;
                    });
                    updateRecommendedExecutors();
                  },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: commentController,
            readOnly: creating,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: uiText(context, 'Комментарий'),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Form section

class _OrderFormSection extends StatelessWidget {
  const _OrderFormSection({
    required this.title,
    required this.icon,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: MasterSection(title: title, icon: icon, child: child),
  );
}
