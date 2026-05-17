import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';

final toolDetailProvider = FutureProvider.autoDispose
    .family<ToolDetailRecord?, String>((ref, toolId) async {
      final client = ref.watch(supabaseClientProvider);

      if (client == null || toolId.isEmpty) {
        return null;
      }

      final toolResponse = await client
          .from('tools')
          .select('''
            id,
            internal_code,
            nomenclature,
            model,
            serial_number,
            part_number,
            description,
            category_id,
            manufacturer_id,
            current_location,
            current_status,
            retired_at,
            retirement_reason,
            retirement_location,
            quarantine_reason,
            quarantine_notes,
            quarantine_marked_at,
            photo_url,
            acquisition_date,
            manufacturer_certificate_url,
            data_sheet_url,
            qr_code,
            traceability_notes,
            categories(id, name),
            manufacturers(id, name)
          ''')
          .eq('id', toolId)
          .maybeSingle();

      if (toolResponse == null) {
        return null;
      }

      final calibrations = await client
          .from('calibrations')
          .select('''
            id,
            calibration_date,
            validity_months,
            expiration_date,
            calibration_center,
            provider_id,
            calibration_providers(name),
            certificate_number,
            certificate_file_url,
            result,
            observations,
            status,
            created_at
          ''')
          .eq('tool_id', toolId)
          .order('calibration_date', ascending: false);

      final shipments = await client
          .from('calibration_shipments')
          .select('''
            id,
            calibration_center,
            provider_id,
            calibration_providers(name),
            shipment_date,
            estimated_return_date,
            actual_return_date,
            shipment_status,
            remission_guide_number,
            remission_guide_file_url,
            observations,
            created_at
          ''')
          .eq('tool_id', toolId)
          .order('shipment_date', ascending: false);

      final documents = await client
          .from('tool_documents')
          .select('''
            id,
            document_type,
            title,
            file_name,
            file_url,
            mime_type,
            size_kb,
            created_at
          ''')
          .eq('tool_id', toolId)
          .order('created_at', ascending: false);

      final loans = await client
          .from('tool_loans')
          .select('''
            id,
            workshop,
            borrower_name,
            workshop_id,
            borrower_id,
            loan_date,
            expected_return_date,
            returned_at,
            status,
            qr_payload,
            observations,
            return_observations,
            created_at
          ''')
          .eq('tool_id', toolId)
          .order('loan_date', ascending: false);

      final traceability = await client
          .from('tool_traceability')
          .select('''
            id,
            trace_type,
            title,
            description,
            event_date,
            document_url,
            created_at
          ''')
          .eq('tool_id', toolId)
          .order('event_date', ascending: false);

      final map = Map<String, dynamic>.from(toolResponse)
        ..['calibrations'] = calibrations
        ..['calibration_shipments'] = shipments
        ..['tool_documents'] = documents
        ..['tool_loans'] = loans
        ..['tool_traceability'] = traceability;

      return ToolDetailRecord.fromMap(map);
    });

class ToolDetailRecord {
  const ToolDetailRecord({
    required this.id,
    required this.nomenclature,
    required this.currentStatus,
    required this.calibrations,
    required this.shipments,
    required this.documents,
    required this.loans,
    required this.traceability,
    this.internalCode,
    this.model,
    this.serialNumber,
    this.partNumber,
    this.description,
    this.categoryId,
    this.manufacturerId,
    this.currentLocation,
    this.retiredAt,
    this.retirementReason,
    this.retirementLocation,
    this.quarantineReason,
    this.quarantineNotes,
    this.quarantineMarkedAt,
    this.photoUrl,
    this.acquisitionDate,
    this.manufacturerCertificateUrl,
    this.dataSheetUrl,
    this.qrCode,
    this.traceabilityNotes,
    this.category,
    this.manufacturer,
  });

  factory ToolDetailRecord.fromMap(Map<String, dynamic> map) {
    final calibrations =
        _listFrom(
            map['calibrations'],
          ).map(ToolCalibrationRecord.fromMap).toList()
          ..sort((a, b) => b.calibrationDate.compareTo(a.calibrationDate));
    final shipments =
        _listFrom(
            map['calibration_shipments'],
          ).map(ToolShipmentRecord.fromMap).toList()
          ..sort((a, b) => b.shipmentDate.compareTo(a.shipmentDate));
    final documents =
        _listFrom(
            map['tool_documents'],
          ).map(ToolDocumentRecord.fromMap).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final loans =
        _listFrom(map['tool_loans']).map(ToolLoanRecord.fromMap).toList()
          ..sort((a, b) => b.loanDate.compareTo(a.loanDate));
    final traceability =
        _listFrom(
            map['tool_traceability'],
          ).map(ToolTraceabilityRecord.fromMap).toList()
          ..sort((a, b) => b.eventDate.compareTo(a.eventDate));

    return ToolDetailRecord(
      id: map['id'] as String? ?? '',
      internalCode: map['internal_code'] as String?,
      nomenclature: map['nomenclature'] as String? ?? 'Sin nomenclatura',
      model: map['model'] as String?,
      serialNumber: map['serial_number'] as String?,
      partNumber: map['part_number'] as String?,
      description: map['description'] as String?,
      categoryId: map['category_id'] as String?,
      manufacturerId: map['manufacturer_id'] as String?,
      currentLocation: map['current_location'] as String?,
      currentStatus: map['current_status'] as String? ?? 'DISPONIBLE',
      retiredAt: DateTime.tryParse(map['retired_at'] as String? ?? ''),
      retirementReason: map['retirement_reason'] as String?,
      retirementLocation: map['retirement_location'] as String?,
      quarantineReason: map['quarantine_reason'] as String?,
      quarantineNotes: map['quarantine_notes'] as String?,
      quarantineMarkedAt: DateTime.tryParse(
        map['quarantine_marked_at'] as String? ?? '',
      ),
      photoUrl: map['photo_url'] as String?,
      acquisitionDate: DateTime.tryParse(
        map['acquisition_date'] as String? ?? '',
      ),
      manufacturerCertificateUrl:
          map['manufacturer_certificate_url'] as String?,
      dataSheetUrl: map['data_sheet_url'] as String?,
      qrCode: map['qr_code'] as String?,
      traceabilityNotes: map['traceability_notes'] as String?,
      category: _nestedName(map['categories']),
      manufacturer: _nestedName(map['manufacturers']),
      calibrations: calibrations,
      shipments: shipments,
      documents: documents,
      loans: loans,
      traceability: traceability,
    );
  }

  final String id;
  final String? internalCode;
  final String nomenclature;
  final String? model;
  final String? serialNumber;
  final String? partNumber;
  final String? description;
  final String? categoryId;
  final String? manufacturerId;
  final String? currentLocation;
  final String currentStatus;
  final DateTime? retiredAt;
  final String? retirementReason;
  final String? retirementLocation;
  final String? quarantineReason;
  final String? quarantineNotes;
  final DateTime? quarantineMarkedAt;
  final String? photoUrl;
  final DateTime? acquisitionDate;
  final String? manufacturerCertificateUrl;
  final String? dataSheetUrl;
  final String? qrCode;
  final String? traceabilityNotes;
  final String? category;
  final String? manufacturer;
  final List<ToolCalibrationRecord> calibrations;
  final List<ToolShipmentRecord> shipments;
  final List<ToolDocumentRecord> documents;
  final List<ToolLoanRecord> loans;
  final List<ToolTraceabilityRecord> traceability;

  bool get isRetired => retiredAt != null || currentStatus == 'BAJA';

  bool get hasQuarantineReason =>
      quarantineReason != null && quarantineReason!.isNotEmpty;

  bool get isInQuarantine {
    if (isRetired || currentStatus == 'EN_CALIBRACION') {
      return false;
    }

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

  ToolCalibrationRecord? get latestCalibration {
    for (final cal in calibrations) {
      if (!cal.isAnnuled) return cal;
    }
    return null;
  }

  String get toolQrPayload {
    final certificate =
        latestCalibration?.certificateFileUrl?.isNotEmpty == true
        ? latestCalibration!.certificateFileUrl!
        : latestCalibration?.certificateNumber ?? 'SIN_CERTIFICADO';
    final dataSheet = dataSheetUrl?.isNotEmpty == true
        ? dataSheetUrl!
        : 'SIN_DATA_SHEET';

    return [
      'SIGCAL-HERRAMIENTA',
      'id=$id',
      'qr=${qrCode ?? '-'}',
      'codigo=${internalCode ?? '-'}',
      'certificado=$certificate',
      'data_sheet=$dataSheet',
    ].join('|');
  }

  ToolLoanRecord? get activeLoan {
    final active = loans.where((loan) => loan.status == 'ABIERTO').toList();

    return active.isEmpty ? null : active.first;
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
    if (currentStatus == 'EN_CALIBRACION') {
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

  double get healthScore {
    final days = daysToExpiration;

    if (days == null) {
      return 0;
    }

    if (days <= 0) {
      return 8;
    }

    return (days / 365 * 100).clamp(12, 100).toDouble();
  }
}

class ToolCalibrationRecord {
  const ToolCalibrationRecord({
    required this.id,
    required this.calibrationDate,
    required this.validityMonths,
    this.expirationDate,
    this.calibrationCenter,
    this.providerId,
    this.providerName,
    this.certificateNumber,
    this.certificateFileUrl,
    this.result,
    this.observations,
    this.status = 'ACTIVO',
  });

  factory ToolCalibrationRecord.fromMap(Map<String, dynamic> map) {
    return ToolCalibrationRecord(
      id: map['id'] as String? ?? '',
      calibrationDate:
          DateTime.tryParse(map['calibration_date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      validityMonths: map['validity_months'] as int? ?? 0,
      expirationDate: DateTime.tryParse(
        map['expiration_date'] as String? ?? '',
      ),
      calibrationCenter: map['calibration_center'] as String?,
      providerId: map['provider_id'] as String?,
      providerName: _nestedName(map['calibration_providers']),
      certificateNumber: map['certificate_number'] as String?,
      certificateFileUrl: map['certificate_file_url'] as String?,
      result: map['result'] as String?,
      observations: map['observations'] as String?,
      status: map['status'] as String? ?? 'ACTIVO',
    );
  }

  final String id;
  final DateTime calibrationDate;
  final int validityMonths;
  final DateTime? expirationDate;
  final String? calibrationCenter;
  final String? providerId;
  final String? providerName;
  final String? certificateNumber;
  final String? certificateFileUrl;
  final String? result;
  final String? observations;
  final String status;

  bool get isAnnuled => status == 'ANULADO';
}

class ToolShipmentRecord {
  const ToolShipmentRecord({
    required this.id,
    required this.shipmentDate,
    required this.status,
    this.calibrationCenter,
    this.providerId,
    this.providerName,
    this.estimatedReturnDate,
    this.actualReturnDate,
    this.remissionGuideNumber,
    this.remissionGuideFileUrl,
    this.observations,
  });

  factory ToolShipmentRecord.fromMap(Map<String, dynamic> map) {
    return ToolShipmentRecord(
      id: map['id'] as String? ?? '',
      shipmentDate:
          DateTime.tryParse(map['shipment_date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: map['shipment_status'] as String? ?? 'ENVIADO',
      calibrationCenter: map['calibration_center'] as String?,
      providerId: map['provider_id'] as String?,
      providerName: _nestedName(map['calibration_providers']),
      estimatedReturnDate: DateTime.tryParse(
        map['estimated_return_date'] as String? ?? '',
      ),
      actualReturnDate: DateTime.tryParse(
        map['actual_return_date'] as String? ?? '',
      ),
      remissionGuideNumber: map['remission_guide_number'] as String?,
      remissionGuideFileUrl: map['remission_guide_file_url'] as String?,
      observations: map['observations'] as String?,
    );
  }

  final String id;
  final DateTime shipmentDate;
  final String status;
  final String? calibrationCenter;
  final String? providerId;
  final String? providerName;
  final DateTime? estimatedReturnDate;
  final DateTime? actualReturnDate;
  final String? remissionGuideNumber;
  final String? remissionGuideFileUrl;
  final String? observations;
}

class ToolDocumentRecord {
  const ToolDocumentRecord({
    required this.id,
    required this.documentType,
    required this.title,
    required this.createdAt,
    this.fileName,
    this.fileUrl,
    this.mimeType,
    this.sizeKb,
  });

  factory ToolDocumentRecord.fromMap(Map<String, dynamic> map) {
    return ToolDocumentRecord(
      id: map['id'] as String? ?? '',
      documentType: map['document_type'] as String? ?? 'GENERAL',
      title: map['title'] as String? ?? 'Documento',
      fileName: map['file_name'] as String?,
      fileUrl: map['file_url'] as String?,
      mimeType: map['mime_type'] as String?,
      sizeKb: map['size_kb'] as int?,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String documentType;
  final String title;
  final String? fileName;
  final String? fileUrl;
  final String? mimeType;
  final int? sizeKb;
  final DateTime createdAt;
}

class ToolLoanRecord {
  const ToolLoanRecord({
    required this.id,
    required this.workshop,
    required this.borrowerName,
    required this.loanDate,
    required this.status,
    required this.qrPayload,
    this.workshopId,
    this.borrowerId,
    this.expectedReturnDate,
    this.returnedAt,
    this.observations,
    this.returnObservations,
  });

  factory ToolLoanRecord.fromMap(Map<String, dynamic> map) {
    return ToolLoanRecord(
      id: map['id'] as String? ?? '',
      workshop: map['workshop'] as String? ?? 'Sin taller',
      borrowerName: map['borrower_name'] as String? ?? 'Sin responsable',
      workshopId: map['workshop_id'] as String?,
      borrowerId: map['borrower_id'] as String?,
      loanDate:
          DateTime.tryParse(map['loan_date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      expectedReturnDate: DateTime.tryParse(
        map['expected_return_date'] as String? ?? '',
      ),
      returnedAt: DateTime.tryParse(map['returned_at'] as String? ?? ''),
      status: map['status'] as String? ?? 'ABIERTO',
      qrPayload: map['qr_payload'] as String? ?? '',
      observations: map['observations'] as String?,
      returnObservations: map['return_observations'] as String?,
    );
  }

  final String id;
  final String workshop;
  final String borrowerName;
  final String? workshopId;
  final String? borrowerId;
  final DateTime loanDate;
  final DateTime? expectedReturnDate;
  final DateTime? returnedAt;
  final String status;
  final String qrPayload;
  final String? observations;
  final String? returnObservations;
}

class ToolTraceabilityRecord {
  const ToolTraceabilityRecord({
    required this.id,
    required this.traceType,
    required this.title,
    required this.eventDate,
    this.description,
    this.documentUrl,
  });

  factory ToolTraceabilityRecord.fromMap(Map<String, dynamic> map) {
    return ToolTraceabilityRecord(
      id: map['id'] as String? ?? '',
      traceType: map['trace_type'] as String? ?? 'GENERAL',
      title: map['title'] as String? ?? 'Evento',
      description: map['description'] as String?,
      eventDate:
          DateTime.tryParse(map['event_date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      documentUrl: map['document_url'] as String?,
    );
  }

  final String id;
  final String traceType;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String? documentUrl;
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
