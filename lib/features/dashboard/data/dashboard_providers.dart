import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_providers.dart';

final dashboardSnapshotProvider = FutureProvider.autoDispose<DashboardSnapshot>(
  (ref) async {
    final client = ref.watch(supabaseClientProvider);

    if (client == null) {
      return DashboardSnapshot.empty();
    }

    final response = await client
        .from('tools')
        .select('''
        id,
        internal_code,
        nomenclature,
        current_status,
        current_location,
        photo_url,
        retired_at,
        retirement_reason,
        retirement_location,
        quarantine_reason,
        quarantine_notes,
        quarantine_marked_at,
        categories(name),
        manufacturers(name),
        calibrations(
          calibration_date,
          expiration_date,
          result,
          calibration_center,
          certificate_number,
          status,
          created_at
        ),
        calibration_shipments(
          calibration_center,
          shipment_date,
          estimated_return_date,
          actual_return_date,
          shipment_status,
          created_at
        )
      ''')
        .order('nomenclature');

    final rows = (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(DashboardTool.fromMap)
        .toList();

    return DashboardSnapshot.fromTools(
      rows.where((tool) => !tool.isRetired).toList(),
    );
  },
);

final retiredToolsProvider = FutureProvider.autoDispose<List<DashboardTool>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);

  if (client == null) {
    return const [];
  }

  final response = await client
      .from('tools')
      .select('''
        id,
        internal_code,
        nomenclature,
        current_status,
        current_location,
        photo_url,
        retired_at,
        retirement_reason,
        retirement_location,
        quarantine_reason,
        quarantine_notes,
        quarantine_marked_at,
        categories(name),
        manufacturers(name),
        calibrations(
          calibration_date,
          expiration_date,
          result,
          calibration_center,
          certificate_number,
          status,
          created_at
        ),
        calibration_shipments(
          calibration_center,
          shipment_date,
          estimated_return_date,
          actual_return_date,
          shipment_status,
          created_at
        )
      ''')
      .or('current_status.eq.BAJA,retired_at.not.is.null')
      .order('retired_at', ascending: false);

  return (response as List<dynamic>)
      .whereType<Map<String, dynamic>>()
      .map(DashboardTool.fromMap)
      .toList();
});

final quarantineToolsProvider = FutureProvider.autoDispose<List<DashboardTool>>(
  (ref) async {
    final snapshot = await ref.watch(dashboardSnapshotProvider.future);

    return snapshot.tools.where((tool) => tool.isInQuarantine).toList()
      ..sort((a, b) {
        final aDays = a.daysToExpiration ?? 9999;
        final bDays = b.daysToExpiration ?? 9999;

        return aDays.compareTo(bDays);
      });
  },
);

enum ComplianceState {
  compliant,
  grace,
  warning,
  expired,
  inCalibration,
  withoutCalibration,
}

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.tools,
    required this.totalTools,
    required this.compliant,
    required this.grace,
    required this.warning,
    required this.expired,
    required this.inCalibration,
    required this.withoutCalibration,
    required this.expiringSoon,
    required this.recentActivity,
  });

  factory DashboardSnapshot.empty() {
    return const DashboardSnapshot(
      tools: [],
      totalTools: 0,
      compliant: 0,
      grace: 0,
      warning: 0,
      expired: 0,
      inCalibration: 0,
      withoutCalibration: 0,
      expiringSoon: [],
      recentActivity: [],
    );
  }

  factory DashboardSnapshot.fromTools(List<DashboardTool> tools) {
    final stateCounts = <ComplianceState, int>{
      for (final state in ComplianceState.values) state: 0,
    };

    for (final tool in tools) {
      stateCounts[tool.complianceState] =
          (stateCounts[tool.complianceState] ?? 0) + 1;
    }

    final expiringSoon =
        tools.where((tool) {
          final days = tool.daysToExpiration;

          return days != null &&
              days >= 0 &&
              days <= 30 &&
              (tool.complianceState == ComplianceState.warning ||
                  tool.complianceState == ComplianceState.grace);
        }).toList()..sort((a, b) {
          return (a.daysToExpiration ?? 9999).compareTo(
            b.daysToExpiration ?? 9999,
          );
        });

    final recentActivity = <DashboardActivity>[
      for (final tool in tools)
        if (tool.activeShipment != null)
          DashboardActivity(
            iconName: 'shipment',
            title: '${tool.displayName} enviado a calibracion',
            detail: tool.activeShipment!.calibrationCenter,
            date: tool.activeShipment!.shipmentDate,
          ),
      for (final tool in tools)
        if (tool.latestCalibration != null)
          DashboardActivity(
            iconName: 'calibration',
            title: '${tool.displayName} calibrado',
            detail: tool.latestCalibration!.calibrationCenter,
            date: tool.latestCalibration!.calibrationDate,
          ),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return DashboardSnapshot(
      tools: tools,
      totalTools: tools.length,
      compliant: stateCounts[ComplianceState.compliant] ?? 0,
      grace: stateCounts[ComplianceState.grace] ?? 0,
      warning: stateCounts[ComplianceState.warning] ?? 0,
      expired: stateCounts[ComplianceState.expired] ?? 0,
      inCalibration: stateCounts[ComplianceState.inCalibration] ?? 0,
      withoutCalibration: stateCounts[ComplianceState.withoutCalibration] ?? 0,
      expiringSoon: expiringSoon.take(6).toList(),
      recentActivity: recentActivity.take(6).toList(),
    );
  }

  final List<DashboardTool> tools;
  final int totalTools;
  final int compliant;
  final int grace;
  final int warning;
  final int expired;
  final int inCalibration;
  final int withoutCalibration;
  final List<DashboardTool> expiringSoon;
  final List<DashboardActivity> recentActivity;

  int get actionRequired => warning + expired;

  int get healthy => compliant + grace;

  double get healthScore {
    if (totalTools == 0) {
      return 0;
    }

    return (healthy / totalTools) * 100;
  }
}

class DashboardTool {
  const DashboardTool({
    required this.id,
    required this.displayName,
    required this.currentStatus,
    this.internalCode,
    this.currentLocation,
    this.photoUrl,
    this.retiredAt,
    this.retirementReason,
    this.retirementLocation,
    this.quarantineReason,
    this.quarantineNotes,
    this.quarantineMarkedAt,
    this.category,
    this.manufacturer,
    this.latestCalibration,
    this.activeShipment,
  });

  factory DashboardTool.fromMap(Map<String, dynamic> map) {
    final calibrations =
        _listFrom(
            map['calibrations'],
          ).map(DashboardCalibration.fromMap).toList()
          ..sort((a, b) => b.calibrationDate.compareTo(a.calibrationDate));

    final shipments =
        _listFrom(
            map['calibration_shipments'],
          ).map(DashboardShipment.fromMap).toList()
          ..sort((a, b) => b.shipmentDate.compareTo(a.shipmentDate));

    final activeShipments = shipments.where((shipment) {
      return shipment.actualReturnDate == null &&
          shipment.status != 'RETORNADO';
    }).toList();

    return DashboardTool(
      id: map['id'] as String? ?? '',
      internalCode: map['internal_code'] as String?,
      displayName: map['nomenclature'] as String? ?? 'Sin nomenclatura',
      currentStatus: map['current_status'] as String? ?? 'DISPONIBLE',
      currentLocation: map['current_location'] as String?,
      photoUrl: map['photo_url'] as String?,
      retiredAt: DateTime.tryParse(map['retired_at'] as String? ?? ''),
      retirementReason: map['retirement_reason'] as String?,
      retirementLocation: map['retirement_location'] as String?,
      quarantineReason: map['quarantine_reason'] as String?,
      quarantineNotes: map['quarantine_notes'] as String?,
      quarantineMarkedAt: DateTime.tryParse(
        map['quarantine_marked_at'] as String? ?? '',
      ),
      category: _nestedName(map['categories']),
      manufacturer: _nestedName(map['manufacturers']),
      latestCalibration: _latestActive(calibrations),
      activeShipment: activeShipments.isEmpty ? null : activeShipments.first,
    );
  }

  final String id;
  final String? internalCode;
  final String displayName;
  final String currentStatus;
  final String? currentLocation;
  final String? photoUrl;
  final DateTime? retiredAt;
  final String? retirementReason;
  final String? retirementLocation;
  final String? quarantineReason;
  final String? quarantineNotes;
  final DateTime? quarantineMarkedAt;
  final String? category;
  final String? manufacturer;
  final DashboardCalibration? latestCalibration;
  final DashboardShipment? activeShipment;

  bool get isRetired => retiredAt != null || currentStatus == 'BAJA';

  bool get hasQuarantineReason =>
      quarantineReason != null && quarantineReason!.isNotEmpty;

  bool get isInQuarantine {
    if (isRetired ||
        currentStatus == 'EN_CALIBRACION' ||
        activeShipment != null) {
      return false;
    }

    // Sin calibracion, vencido, o con motivo de cuarentena
    return daysToExpiration == null ||
        hasQuarantineReason ||
        daysToExpiration! < 0;
  }

  String get quarantineLabel {
    if (hasQuarantineReason) {
      return switch (quarantineReason) {
        'IRREPARABLE' => 'Irreparable',
        'INOPERATIVA' => 'Inoperativa',
        'NO_CALIBRABLE' => 'No calibrable',
        'NO_CONFORME' => 'No conforme',
        _ => quarantineReason!,
      };
    }

    final days = daysToExpiration;

    if (days != null && days < 0) {
      return 'Certificado vencido';
    }

    return 'Pendiente de accion';
  }

  int? get daysToExpiration {
    final expirationDate = latestCalibration?.expirationDate;

    if (expirationDate == null) {
      return null;
    }

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return expirationDate.difference(todayOnly).inDays;
  }

  ComplianceState get complianceState {
    if (activeShipment != null || currentStatus == 'EN_CALIBRACION') {
      return ComplianceState.inCalibration;
    }

    final days = daysToExpiration;

    if (days == null) {
      return ComplianceState.withoutCalibration;
    }

    if (days < 0) {
      return ComplianceState.expired;
    }

    if (days <= 15) {
      return ComplianceState.warning;
    }

    if (days <= 30) {
      return ComplianceState.grace;
    }

    return ComplianceState.compliant;
  }
}

class DashboardCalibration {
  const DashboardCalibration({
    required this.calibrationDate,
    this.expirationDate,
    this.result,
    this.calibrationCenter,
    this.certificateNumber,
    this.status = 'ACTIVO',
  });

  factory DashboardCalibration.fromMap(Map<String, dynamic> map) {
    return DashboardCalibration(
      calibrationDate:
          DateTime.tryParse(map['calibration_date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      expirationDate: DateTime.tryParse(
        map['expiration_date'] as String? ?? '',
      ),
      result: map['result'] as String?,
      calibrationCenter: map['calibration_center'] as String?,
      certificateNumber: map['certificate_number'] as String?,
      status: map['status'] as String? ?? 'ACTIVO',
    );
  }

  final DateTime calibrationDate;
  final DateTime? expirationDate;
  final String? result;
  final String? calibrationCenter;
  final String? certificateNumber;
  final String status;

  bool get isAnnuled => status == 'ANULADO';
}

class DashboardShipment {
  const DashboardShipment({
    required this.shipmentDate,
    required this.status,
    this.calibrationCenter,
    this.estimatedReturnDate,
    this.actualReturnDate,
  });

  factory DashboardShipment.fromMap(Map<String, dynamic> map) {
    return DashboardShipment(
      shipmentDate:
          DateTime.tryParse(map['shipment_date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: map['shipment_status'] as String? ?? 'PENDIENTE_ENVIO',
      calibrationCenter: map['calibration_center'] as String?,
      estimatedReturnDate: DateTime.tryParse(
        map['estimated_return_date'] as String? ?? '',
      ),
      actualReturnDate: DateTime.tryParse(
        map['actual_return_date'] as String? ?? '',
      ),
    );
  }

  final DateTime shipmentDate;
  final String status;
  final String? calibrationCenter;
  final DateTime? estimatedReturnDate;
  final DateTime? actualReturnDate;
}

class DashboardActivity {
  const DashboardActivity({
    required this.iconName,
    required this.title,
    required this.date,
    this.detail,
  });

  final String iconName;
  final String title;
  final DateTime date;
  final String? detail;
}

List<Map<String, dynamic>> _listFrom(Object? value) {
  if (value is! List<dynamic>) {
    return const [];
  }

  return value.whereType<Map<String, dynamic>>().toList();
}

String? _nestedName(Object? value) {
  if (value is Map<String, dynamic>) {
    return value['name'] as String?;
  }

  return null;
}

DashboardCalibration? _latestActive(List<DashboardCalibration> calibrations) {
  for (final cal in calibrations) {
    if (!cal.isAnnuled) return cal;
  }
  return null;
}
