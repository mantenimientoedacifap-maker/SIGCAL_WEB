import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_providers.dart';
import '../../dashboard/data/dashboard_providers.dart';

final shipmentsProvider = FutureProvider.autoDispose<List<ShipmentRecord>>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);

  if (client == null) {
    return const [];
  }

  final response = await client
      .from('calibration_shipments')
      .select('''
        id,
        tool_id,
        provider_id,
        calibration_center,
        shipment_date,
        estimated_return_date,
        actual_return_date,
        shipment_status,
        remission_guide_number,
        remission_guide_file_url,
        observations,
        created_at,
        tools(id, internal_code, nomenclature, current_status),
        calibration_providers(id, name)
      ''')
      .order('shipment_date', ascending: false);

  return (response as List<dynamic>)
      .whereType<Map<String, dynamic>>()
      .map(ShipmentRecord.fromMap)
      .toList();
});

final shipmentRepositoryProvider = Provider<ShipmentRepository>((ref) {
  return ShipmentRepository(ref.watch(supabaseClientProvider));
});

class ShipmentRepository {
  const ShipmentRepository(this._client);

  final SupabaseClient? _client;

  Future<String> createShipment({
    required String toolId,
    required String calibrationCenter,
    String? providerId,
    required DateTime shipmentDate,
    DateTime? estimatedReturnDate,
    String? remissionGuideNumber,
    String? observations,
    Uint8List? remissionGuideBytes,
    String? remissionGuideFileName,
  }) async {
    final client = _requireClient();
    final userId = client.auth.currentUser?.id;
    final center = calibrationCenter.trim().toUpperCase();

    // Subir archivo de guía si se proveyó
    String? guidePath;
    if (remissionGuideBytes != null) {
      final cleanName =
          (remissionGuideFileName ?? 'guia.pdf').trim().toLowerCase();
      final ext = cleanName.contains('.')
          ? cleanName.split('.').last
          : 'pdf';
      guidePath =
          '$toolId/guia-${DateTime.now().millisecondsSinceEpoch}.$ext';

      await client.storage
          .from('remission-guides')
          .uploadBinary(
            guidePath,
            remissionGuideBytes,
            fileOptions: FileOptions(
              contentType: ext == 'pdf' ? 'application/pdf' : 'image/$ext',
              upsert: false,
            ),
          );
    }
    final response = await client
        .from('calibration_shipments')
        .insert({
          'tool_id': toolId,
          'provider_id': _clean(providerId),
          'calibration_center': center,
          'shipment_date': _dateOnly(shipmentDate),
          'estimated_return_date': _dateOnly(estimatedReturnDate),
          'remission_guide_number': _upperClean(remissionGuideNumber),
          'remission_guide_file_url': guidePath,
          'shipment_status': 'ENVIADO',
          'observations': _upperClean(observations),
          'created_by': userId,
          'updated_by': userId,
        })
        .select('id')
        .single();

    await client
        .from('tools')
        .update({
          'current_status': 'EN_CALIBRACION',
          'current_location': center,
          'updated_by': userId,
        })
        .eq('id', toolId);

    await client.from('tool_traceability').insert({
      'tool_id': toolId,
      'trace_type': 'ENVIO_CALIBRACION',
      'title': 'Envio a calibracion',
      'description': 'ENVIADO A $center.',
      'event_date': _dateOnly(shipmentDate),
      'created_by': userId,
      'updated_by': userId,
    });

    return response['id'] as String;
  }

  Future<void> updateShipmentStatus({
    required ShipmentRecord shipment,
    required String status,
  }) async {
    final client = _requireClient();
    final userId = client.auth.currentUser?.id;
    final isReturned = status == 'RETORNADO';
    final now = DateTime.now();

    await client
        .from('calibration_shipments')
        .update({
          'shipment_status': status,
          if (isReturned) 'actual_return_date': _dateOnly(now),
          'updated_by': userId,
        })
        .eq('id', shipment.id);

    if (isReturned) {
      await client
          .from('tools')
          .update({
            'current_status': 'DISPONIBLE',
            'current_location': 'ALMACEN',
            'updated_by': userId,
          })
          .eq('id', shipment.toolId);

      await client.from('tool_traceability').insert({
        'tool_id': shipment.toolId,
        'trace_type': 'RETORNO_CALIBRACION',
        'title': 'Retorno de calibracion',
        'description': 'RETORNADO DESDE ${shipment.calibrationCenter}.',
        'event_date': _dateOnly(now),
        'created_by': userId,
        'updated_by': userId,
      });
    }
  }

  SupabaseClient _requireClient() {
    final client = _client;

    if (client == null) {
      throw StateError('Supabase no esta configurado para esta sesion.');
    }

    return client;
  }
}

class ShipmentRecord {
  const ShipmentRecord({
    required this.id,
    required this.toolId,
    required this.calibrationCenter,
    required this.shipmentDate,
    required this.status,
    this.providerId,
    this.providerName,
    this.toolCode,
    this.toolName,
    this.estimatedReturnDate,
    this.actualReturnDate,
    this.remissionGuideNumber,
    this.remissionGuideFileUrl,
    this.observations,
  });

  factory ShipmentRecord.fromMap(Map<String, dynamic> map) {
    final tool = _mapFrom(map['tools']);
    final provider = _mapFrom(map['calibration_providers']);

    return ShipmentRecord(
      id: map['id'] as String? ?? '',
      toolId: map['tool_id'] as String? ?? '',
      providerId: map['provider_id'] as String?,
      providerName: provider?['name'] as String?,
      calibrationCenter: map['calibration_center'] as String? ?? '',
      shipmentDate:
          DateTime.tryParse(map['shipment_date'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      estimatedReturnDate: DateTime.tryParse(
        map['estimated_return_date'] as String? ?? '',
      ),
      actualReturnDate: DateTime.tryParse(
        map['actual_return_date'] as String? ?? '',
      ),
      status: map['shipment_status'] as String? ?? 'ENVIADO',
      remissionGuideNumber: map['remission_guide_number'] as String?,
      remissionGuideFileUrl: map['remission_guide_file_url'] as String?,
      observations: map['observations'] as String?,
      toolCode: tool?['internal_code'] as String?,
      toolName: tool?['nomenclature'] as String?,
    );
  }

  final String id;
  final String toolId;
  final String? providerId;
  final String? providerName;
  final String calibrationCenter;
  final DateTime shipmentDate;
  final DateTime? estimatedReturnDate;
  final DateTime? actualReturnDate;
  final String status;
  final String? remissionGuideNumber;
  final String? remissionGuideFileUrl;
  final String? observations;
  final String? toolCode;
  final String? toolName;

  bool get isOpen => status != 'RETORNADO';

  int? get daysToReturn {
    if (estimatedReturnDate == null || !isOpen) {
      return null;
    }

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    return estimatedReturnDate!.difference(todayOnly).inDays;
  }

  ComplianceState get urgency {
    final days = daysToReturn;

    if (days == null) {
      return isOpen ? ComplianceState.grace : ComplianceState.compliant;
    }

    if (days < 0) {
      return ComplianceState.expired;
    }

    if (days <= 2) {
      return ComplianceState.warning;
    }

    return ComplianceState.compliant;
  }
}

Map<String, dynamic>? _mapFrom(Object? value) {
  return value is Map<String, dynamic> ? value : null;
}

String? _clean(String? value) {
  final clean = value?.trim();

  return clean == null || clean.isEmpty ? null : clean;
}

String? _upperClean(String? value) {
  return _clean(value)?.toUpperCase();
}

String? _dateOnly(DateTime? value) {
  if (value == null) {
    return null;
  }

  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
