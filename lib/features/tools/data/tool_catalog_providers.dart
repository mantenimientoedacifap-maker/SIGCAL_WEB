import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/config/supabase_providers.dart';
import 'tool_detail_providers.dart';

final toolCatalogsProvider = FutureProvider.autoDispose<ToolCatalogs>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);

  if (client == null) {
    return const ToolCatalogs.empty();
  }

  final categories = await client
      .from('categories')
      .select('id, name, description, type_code')
      .eq('active', true)
      .order('name');
  final manufacturers = await client
      .from('manufacturers')
      .select('id, name')
      .eq('active', true)
      .order('name');
  final providers = await client
      .from('calibration_providers')
      .select('id, name, contact_name, phone, address')
      .eq('active', true)
      .order('name');
  final workshops = await client
      .from('workshops')
      .select('id, name, workshop_type, description')
      .eq('active', true)
      .order('name');
  final borrowers = await client
      .from('borrowers')
      .select('id, full_name, document_number, email, phone, workshop_id')
      .eq('active', true)
      .order('full_name');

  return ToolCatalogs(
    categories: _catalogItems(categories),
    manufacturers: _catalogItems(manufacturers),
    providers: _providerItems(providers),
    workshops: _workshopItems(workshops),
    borrowers: _borrowerItems(borrowers),
  );
});

final toolMutationRepositoryProvider = Provider<ToolMutationRepository>((ref) {
  return ToolMutationRepository(ref.watch(supabaseClientProvider));
});

class ToolMutationRepository {
  const ToolMutationRepository(this._client);

  final SupabaseClient? _client;

  Future<String> saveTool({
    required Map<String, dynamic> payload,
    String? toolId,
  }) async {
    final activeClient = _requireClient();
    final cleanPayload = _compactPayload(payload);
    final userId = activeClient.auth.currentUser?.id;

    if (toolId != null && toolId.isNotEmpty) {
      cleanPayload['updated_by'] = userId;
      final response = await activeClient
          .from('tools')
          .update(cleanPayload)
          .eq('id', toolId)
          .select('id')
          .single();

      return response['id'] as String;
    }

    cleanPayload['created_by'] = userId;
    cleanPayload['updated_by'] = userId;
    final response = await activeClient
        .from('tools')
        .insert(cleanPayload)
        .select('id')
        .single();

    return response['id'] as String;
  }

  Future<void> updateToolPhotoUrl({
    required String toolId,
    required String photoUrl,
  }) async {
    final activeClient = _requireClient();

    await activeClient
        .from('tools')
        .update({
          'photo_url': photoUrl,
          'updated_by': activeClient.auth.currentUser?.id,
        })
        .eq('id', toolId);
  }

  Future<String> uploadToolImage({
    required String toolId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final activeClient = _requireClient();
    final path = '$toolId/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await activeClient.storage
        .from('tool-images')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return activeClient.storage.from('tool-images').getPublicUrl(path);
  }

  /// Sube un manual técnico (PDF) al bucket privado [support-documents]
  /// y actualiza `tools.data_sheet_url`.
  Future<String> uploadManual({
    required String toolId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final activeClient = _requireClient();
    final userId = activeClient.auth.currentUser?.id;
    final cleanName = _sanitizeFileName(fileName);
    final extension = cleanName.contains('.')
        ? cleanName.split('.').last.toLowerCase()
        : 'pdf';
    final path =
        '$toolId/manual-${DateTime.now().millisecondsSinceEpoch}.$extension';

    await activeClient.storage
        .from('support-documents')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );

    await activeClient
        .from('tools')
        .update({
          'data_sheet_url': path,
          'updated_by': userId,
        })
        .eq('id', toolId);

    return path;
  }

  String _sanitizeFileName(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '')
        .toLowerCase();
  }

  /// Sube un informe técnico (PDF) al bucket privado [support-documents]
  /// y lo registra en la tabla [tool_documents].
  Future<String> uploadTechnicalReport({
    required String toolId,
    required String documentType,
    required String title,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final activeClient = _requireClient();
    final userId = activeClient.auth.currentUser?.id;
    final cleanName = _sanitizeFileName(fileName);
    final extension = cleanName.contains('.')
        ? cleanName.split('.').last.toLowerCase()
        : 'pdf';
    final path =
        '$toolId/report-${DateTime.now().millisecondsSinceEpoch}.$extension';

    await activeClient.storage
        .from('support-documents')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );

    final response = await activeClient
        .from('tool_documents')
        .insert({
          'tool_id': toolId,
          'document_type': documentType,
          'title': title,
          'file_name': fileName,
          'file_url': path,
          'mime_type': 'application/pdf',
          'size_kb': (bytes.length / 1024).ceil(),
          'uploaded_by': userId,
          'created_by': userId,
          'updated_by': userId,
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  Future<String> createManufacturer(String name) async {
    final activeClient = _requireClient();
    final response = await activeClient
        .from('manufacturers')
        .insert({
          'name': _upperClean(name),
          'updated_by': activeClient.auth.currentUser?.id,
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  Future<String> createProvider({
    required String name,
    String? contactName,
    String? phone,
    String? address,
  }) async {
    final activeClient = _requireClient();
    final response = await activeClient
        .from('calibration_providers')
        .insert({
          'name': _upperClean(name),
          'contact_name': _upperClean(contactName),
          'phone': _cleanString(phone),
          'address': _upperClean(address),
          'updated_by': activeClient.auth.currentUser?.id,
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  Future<String> createWorkshop({
    required String name,
    String type = 'TALLER',
    String? description,
  }) async {
    final activeClient = _requireClient();
    final response = await activeClient
        .from('workshops')
        .insert({
          'name': _upperClean(name),
          'workshop_type': _upperClean(type) ?? 'TALLER',
          'description': _upperClean(description),
          'updated_by': activeClient.auth.currentUser?.id,
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  Future<String> createBorrower({
    required String fullName,
    String? documentNumber,
    String? email,
    String? phone,
    String? workshopId,
  }) async {
    final activeClient = _requireClient();
    final response = await activeClient
        .from('borrowers')
        .insert({
          'full_name': _upperClean(fullName),
          'document_number': _upperClean(documentNumber),
          'email': _cleanString(email),
          'phone': _cleanString(phone),
          'workshop_id': _cleanString(workshopId),
          'updated_by': activeClient.auth.currentUser?.id,
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  Future<void> retireTool({
    required String toolId,
    required String reason,
  }) async {
    final activeClient = _requireClient();
    final userId = activeClient.auth.currentUser?.id;
    final now = DateTime.now();

    await activeClient
        .from('tools')
        .update({
          'current_status': 'BAJA',
          'current_location': 'ALMACEN DE BAJAS',
          'retired_at': now.toIso8601String(),
          'retired_by': userId,
          'retirement_reason': _upperClean(reason),
          'retirement_location': 'ALMACEN DE BAJAS',
          'updated_by': userId,
        })
        .eq('id', toolId);

    await activeClient.from('tool_traceability').insert({
      'tool_id': toolId,
      'trace_type': 'BAJA',
      'title': 'Herramienta dada de baja',
      'description': _upperClean(reason),
      'event_date': _dateOnly(now),
      'created_by': userId,
      'updated_by': userId,
    });
  }

  Future<String> createLoan({
    required ToolDetailRecord tool,
    required WorkshopRecord workshop,
    required BorrowerRecord borrower,
    DateTime? expectedReturnDate,
    String? observations,
  }) async {
    final activeClient = _requireClient();
    final now = DateTime.now();
    final userId = activeClient.auth.currentUser?.id;
    final qrPayload = [
      'SIGCAL-VALE',
      'tool=${tool.id}',
      'tool_qr=${tool.qrCode ?? '-'}',
      'code=${tool.internalCode ?? '-'}',
      'borrower=${borrower.fullName}',
      'workshop=${workshop.name}',
      'issued=${now.toIso8601String()}',
    ].join('|');

    final response = await activeClient
        .from('tool_loans')
        .insert({
          'tool_id': tool.id,
          'workshop': workshop.name,
          'borrower_name': borrower.fullName,
          'workshop_id': workshop.id,
          'borrower_id': borrower.id,
          'loan_date': _dateOnly(now),
          'expected_return_date': _dateOnly(expectedReturnDate),
          'status': 'ABIERTO',
          'qr_payload': qrPayload,
          'observations': _cleanString(observations),
          'created_by': userId,
          'updated_by': userId,
        })
        .select('id')
        .single();

    await activeClient
        .from('tools')
        .update({
          'current_status': 'EN_USO',
          'current_location': workshop.name,
          'updated_by': userId,
        })
        .eq('id', tool.id);

    await activeClient.from('tool_traceability').insert({
      'tool_id': tool.id,
      'trace_type': 'PRESTAMO',
      'title': 'Prestamo generado',
      'description': 'Retirado por ${borrower.fullName} para ${workshop.name}.',
      'event_date': _dateOnly(now),
      'created_by': userId,
      'updated_by': userId,
    });

    return response['id'] as String;
  }

  Future<void> returnLoan({
    required ToolDetailRecord tool,
    required ToolLoanRecord loan,
    String? observations,
  }) async {
    final activeClient = _requireClient();
    final userId = activeClient.auth.currentUser?.id;
    final now = DateTime.now();

    await activeClient
        .from('tool_loans')
        .update({
          'status': 'RETORNADO',
          'returned_at': now.toIso8601String(),
          'return_observations': _cleanString(observations),
          'updated_by': userId,
        })
        .eq('id', loan.id);

    await activeClient
        .from('tools')
        .update({
          'current_status': 'DISPONIBLE',
          'current_location': 'Almacen',
          'updated_by': userId,
        })
        .eq('id', tool.id);

    await activeClient.from('tool_traceability').insert({
      'tool_id': tool.id,
      'trace_type': 'DEVOLUCION',
      'title': 'Herramienta devuelta',
      'description':
          'Devuelta por ${loan.borrowerName}. ${_cleanString(observations) ?? ''}'
              .trim(),
      'event_date': _dateOnly(now),
      'created_by': userId,
      'updated_by': userId,
    });
  }

  /// Variante de [returnLoan] para usar desde vistas que solo disponen de IDs
  /// (ej. `loans_page.dart`). Realiza las mismas 3 operaciones: cerrar el
  /// préstamo, restaurar la herramienta a DISPONIBLE y registrar trazabilidad.
  Future<void> returnLoanById({
    required String loanId,
    required String toolId,
    required String borrowerName,
    String? observations,
  }) async {
    final activeClient = _requireClient();
    final userId = activeClient.auth.currentUser?.id;
    final now = DateTime.now();

    await activeClient
        .from('tool_loans')
        .update({
          'status': 'RETORNADO',
          'returned_at': now.toIso8601String(),
          'return_observations': _cleanString(observations),
          'updated_by': userId,
        })
        .eq('id', loanId);

    await activeClient
        .from('tools')
        .update({
          'current_status': 'DISPONIBLE',
          'current_location': 'Almacen',
          'updated_by': userId,
        })
        .eq('id', toolId);

    await activeClient.from('tool_traceability').insert({
      'tool_id': toolId,
      'trace_type': 'DEVOLUCION',
      'title': 'Herramienta devuelta',
      'description':
          'Devuelta por $borrowerName. ${_cleanString(observations) ?? ''}'
              .trim(),
      'event_date': _dateOnly(now),
      'created_by': userId,
      'updated_by': userId,
    });
  }

  SupabaseClient _requireClient() {
    final activeClient = _client;

    if (activeClient == null) {
      throw StateError(SupabaseConfig.runtimeInfo.message);
    }

    return activeClient;
  }
}

class ToolCatalogs {
  const ToolCatalogs({
    required this.categories,
    required this.manufacturers,
    required this.providers,
    required this.workshops,
    required this.borrowers,
  });

  const ToolCatalogs.empty()
    : categories = const [],
      manufacturers = const [],
      providers = const [],
      workshops = const [],
      borrowers = const [];

  final List<CatalogItem> categories;
  final List<CatalogItem> manufacturers;
  final List<CalibrationProviderRecord> providers;
  final List<WorkshopRecord> workshops;
  final List<BorrowerRecord> borrowers;

  WorkshopRecord? workshopByName(String? name) {
    if (name == null || name.isEmpty) {
      return null;
    }

    for (final workshop in workshops) {
      if (workshop.name == name) {
        return workshop;
      }
    }

    return null;
  }

  List<BorrowerRecord> borrowersForWorkshop(String? workshopId) {
    final filtered = borrowers
        .where((borrower) => borrower.workshopId == workshopId)
        .toList();

    return filtered.isEmpty ? borrowers : filtered;
  }
}

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    this.description,
    this.typeCode,
  });

  factory CatalogItem.fromMap(Map<String, dynamic> map) {
    return CatalogItem(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      typeCode: map['type_code'] as String?,
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? typeCode;
}

class CalibrationProviderRecord {
  const CalibrationProviderRecord({
    required this.id,
    required this.name,
    this.contactName,
    this.phone,
    this.address,
  });

  factory CalibrationProviderRecord.fromMap(Map<String, dynamic> map) {
    return CalibrationProviderRecord(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      contactName: map['contact_name'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
    );
  }

  final String id;
  final String name;
  final String? contactName;
  final String? phone;
  final String? address;
}

class WorkshopRecord {
  const WorkshopRecord({
    required this.id,
    required this.name,
    required this.type,
    this.description,
  });

  factory WorkshopRecord.fromMap(Map<String, dynamic> map) {
    return WorkshopRecord(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: map['workshop_type'] as String? ?? 'TALLER',
      description: map['description'] as String?,
    );
  }

  final String id;
  final String name;
  final String type;
  final String? description;
}

class BorrowerRecord {
  const BorrowerRecord({
    required this.id,
    required this.fullName,
    this.documentNumber,
    this.email,
    this.phone,
    this.workshopId,
  });

  factory BorrowerRecord.fromMap(Map<String, dynamic> map) {
    return BorrowerRecord(
      id: map['id'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      documentNumber: map['document_number'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      workshopId: map['workshop_id'] as String?,
    );
  }

  final String id;
  final String fullName;
  final String? documentNumber;
  final String? email;
  final String? phone;
  final String? workshopId;
}

List<CatalogItem> _catalogItems(Object? value) {
  return _rows(value).map(CatalogItem.fromMap).toList();
}

List<CalibrationProviderRecord> _providerItems(Object? value) {
  return _rows(value).map(CalibrationProviderRecord.fromMap).toList();
}

List<WorkshopRecord> _workshopItems(Object? value) {
  return _rows(value).map(WorkshopRecord.fromMap).toList();
}

List<BorrowerRecord> _borrowerItems(Object? value) {
  return _rows(value).map(BorrowerRecord.fromMap).toList();
}

List<Map<String, dynamic>> _rows(Object? value) {
  if (value is! List<dynamic>) {
    return const [];
  }

  return value.whereType<Map<String, dynamic>>().toList();
}

Map<String, dynamic> _compactPayload(Map<String, dynamic> payload) {
  return {
    for (final entry in payload.entries)
      entry.key: entry.value is String
          ? _cleanString(entry.value as String)
          : entry.value,
  };
}

String? _cleanString(String? value) {
  final clean = value?.trim();

  return clean == null || clean.isEmpty ? null : clean;
}

String? _upperClean(String? value) {
  final clean = _cleanString(value);

  return clean?.toUpperCase();
}

String? _dateOnly(DateTime? value) {
  if (value == null) {
    return null;
  }

  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
