import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/config/supabase_providers.dart';

final calibrationRepositoryProvider = Provider<CalibrationRepository>((ref) {
  return CalibrationRepository(ref.watch(supabaseClientProvider));
});

class CalibrationRepository {
  const CalibrationRepository(this._client);

  final SupabaseClient? _client;

  Future<String> createCalibration({
    required String toolId,
    required DateTime calibrationDate,
    required int validityMonths,
    required DateTime expirationDate,
    required String result,
    String? providerId,
    String? calibrationCenter,
    String? certificateNumber,
    Uint8List? certificateBytes,
    String? certificateFileName,
    String? certificateContentType,
    String? observations,
    String? quarantineReason,
    String? quarantineNotes,
  }) async {
    final activeClient = _requireClient();
    final userId = activeClient.auth.currentUser?.id;
    final certificatePath = certificateBytes == null
        ? null
        : await _uploadCertificate(
            client: activeClient,
            toolId: toolId,
            bytes: certificateBytes,
            fileName: certificateFileName,
            contentType: certificateContentType,
          );

    final response = await activeClient
        .from('calibrations')
        .insert({
          'tool_id': toolId,
          'calibration_date': _dateOnly(calibrationDate),
          'validity_months': validityMonths,
          'expiration_date': _dateOnly(expirationDate),
          'calibration_center': _cleanString(calibrationCenter),
          'provider_id': _cleanString(providerId),
          'certificate_number': _cleanString(certificateNumber),
          'certificate_file_url': certificatePath,
          'result': result,
          'observations': _cleanString(observations),
          'created_by': userId,
          'updated_by': userId,
        })
        .select('id')
        .single();
    final calibrationId = response['id'] as String;

    if (certificatePath != null) {
      await activeClient.from('tool_documents').insert({
        'tool_id': toolId,
        'calibration_id': calibrationId,
        'document_type': 'CERTIFICADO',
        'title': certificateNumber == null || certificateNumber.trim().isEmpty
            ? 'Certificado de calibracion'
            : 'Certificado $certificateNumber',
        'file_name': certificateFileName,
        'file_url': certificatePath,
        'mime_type': certificateContentType ?? 'application/pdf',
        'size_kb': (certificateBytes!.length / 1024).ceil(),
        'uploaded_by': userId,
        'created_by': userId,
        'updated_by': userId,
      });
    }

    await activeClient.from('tool_traceability').insert({
      'tool_id': toolId,
      'trace_type': 'CALIBRACION',
      'title': 'Calibracion registrada',
      'description':
          'Resultado $result. Vencimiento ${_dateOnly(expirationDate)}.',
      'event_date': _dateOnly(calibrationDate),
      'document_url': certificatePath,
      'created_by': userId,
      'updated_by': userId,
    });

    final isNonConforming = result == 'NO_CONFORME';

    await activeClient
        .from('tools')
        .update({
          'current_status': isNonConforming
              ? 'FUERA_DE_SERVICIO'
              : 'DISPONIBLE',
          'quarantine_reason': isNonConforming
              ? (_cleanString(quarantineReason) ?? 'NO_CONFORME')
              : null,
          'quarantine_notes': isNonConforming
              ? _cleanString(quarantineNotes ?? observations)
              : null,
          'quarantine_marked_at': isNonConforming
              ? DateTime.now().toIso8601String()
              : null,
          'updated_by': userId,
        })
        .eq('id', toolId);

    return calibrationId;
  }

  Future<String> _uploadCertificate({
    required SupabaseClient client,
    required String toolId,
    required Uint8List bytes,
    required String? fileName,
    required String? contentType,
  }) async {
    final cleanName = _sanitizeFileName(fileName ?? 'certificado.pdf');
    final extension = cleanName.contains('.')
        ? cleanName.split('.').last.toLowerCase()
        : 'pdf';
    final path = '$toolId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await client.storage
        .from('calibration-certificates')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType ?? 'application/pdf',
            upsert: false,
          ),
        );

    return path;
  }

  SupabaseClient _requireClient() {
    final activeClient = _client;

    if (activeClient == null) {
      throw StateError(SupabaseConfig.runtimeInfo.message);
    }

    return activeClient;
  }

  /// Actualiza una calibración existente (modo edición).
  ///
  /// Si se provee un nuevo [certificateBytes], se sube al bucket y se
  /// reemplaza el archivo anterior. Si es null, se conserva el existente.
  Future<void> updateCalibration({
    required String calibrationId,
    required String toolId,
    required DateTime calibrationDate,
    required int validityMonths,
    required DateTime expirationDate,
    required String result,
    String? providerId,
    String? calibrationCenter,
    String? certificateNumber,
    Uint8List? certificateBytes,
    String? certificateFileName,
    String? certificateContentType,
    String? observations,
    String? quarantineReason,
    String? quarantineNotes,
  }) async {
    final activeClient = _requireClient();
    final userId = activeClient.auth.currentUser?.id;

    // Subir nuevo certificado si se proveyó
    String? certificatePath;
    if (certificateBytes != null) {
      certificatePath = await _uploadCertificate(
        client: activeClient,
        toolId: toolId,
        bytes: certificateBytes,
        fileName: certificateFileName,
        contentType: certificateContentType,
      );
    }

    final payload = <String, dynamic>{
      'calibration_date': _dateOnly(calibrationDate),
      'validity_months': validityMonths,
      'expiration_date': _dateOnly(expirationDate),
      'calibration_center': _cleanString(calibrationCenter),
      'provider_id': _cleanString(providerId),
      'certificate_number': _cleanString(certificateNumber),
      'result': result,
      'observations': _cleanString(observations),
      'updated_by': userId,
    };

    if (certificatePath != null) {
      payload['certificate_file_url'] = certificatePath;
    }

    await activeClient
        .from('calibrations')
        .update(payload)
        .eq('id', calibrationId);

    final isNonConforming = result == 'NO_CONFORME';

    await activeClient
        .from('tools')
        .update({
          'current_status': isNonConforming
              ? 'FUERA_DE_SERVICIO'
              : 'DISPONIBLE',
          'quarantine_reason': isNonConforming
              ? (_cleanString(quarantineReason) ?? 'NO_CONFORME')
              : null,
          'quarantine_notes': isNonConforming
              ? _cleanString(quarantineNotes ?? observations)
              : null,
          'quarantine_marked_at': isNonConforming
              ? DateTime.now().toIso8601String()
              : null,
          'updated_by': userId,
        })
        .eq('id', toolId);

    await activeClient.from('tool_traceability').insert({
      'tool_id': toolId,
      'trace_type': 'CALIBRACION',
      'title': 'Calibracion corregida',
      'description':
          'Resultado $result. Vencimiento ${_dateOnly(expirationDate)}.',
      'event_date': _dateOnly(DateTime.now()),
      'document_url': certificatePath,
      'created_by': userId,
      'updated_by': userId,
    });
  }

  /// Anula una calibración, dejando trazabilidad del evento.
  ///
  /// Marca `status = 'ANULADO'` y registra el motivo. Si la calibración
  /// anulada era la más reciente, el estado de la herramienta se recalcula
  /// tomando la siguiente calibración vigente.
  Future<void> annulCalibration({
    required String calibrationId,
    required String toolId,
    required String reason,
  }) async {
    final activeClient = _requireClient();
    final userId = activeClient.auth.currentUser?.id;
    final now = DateTime.now();

    await activeClient
        .from('calibrations')
        .update({
          'status': 'ANULADO',
          'annulment_reason': _cleanString(reason),
          'annulled_at': now.toIso8601String(),
          'updated_by': userId,
        })
        .eq('id', calibrationId);

    // Buscar la siguiente calibración vigente más reciente para
    // determinar el estado correcto de la herramienta.
    final nextCal = await activeClient
        .from('calibrations')
        .select('result, expiration_date')
        .eq('tool_id', toolId)
        .neq('id', calibrationId)
        .neq('status', 'ANULADO')
        .order('calibration_date', ascending: false)
        .limit(1)
        .maybeSingle();

    if (nextCal != null) {
      final nextResult = nextCal['result'] as String?;
      final nextExp = nextCal['expiration_date'] as String?;
      final isExpired = nextExp != null &&
          DateTime.tryParse(nextExp)?.isBefore(
              DateTime(now.year, now.month, now.day)) == true;

      await activeClient.from('tools').update({
        'current_status': nextResult == 'NO_CONFORME'
            ? 'FUERA_DE_SERVICIO'
            : isExpired
                ? 'FUERA_DE_SERVICIO'
                : 'DISPONIBLE',
        'updated_by': userId,
      }).eq('id', toolId);
    } else {
      // Sin calibraciones vigentes: la herramienta queda sin calibrar
      await activeClient.from('tools').update({
        'current_status': 'DISPONIBLE',
        'quarantine_reason': null,
        'quarantine_notes': null,
        'quarantine_marked_at': null,
        'updated_by': userId,
      }).eq('id', toolId);
    }

    await activeClient.from('tool_traceability').insert({
      'tool_id': toolId,
      'trace_type': 'CALIBRACION',
      'title': 'Calibracion anulada',
      'description':
          'Anulada por ${_cleanString(reason) ?? 'motivo no especificado'}.',
      'event_date': _dateOnly(now),
      'created_by': userId,
      'updated_by': userId,
    });
  }
}

String _sanitizeFileName(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '')
      .toLowerCase();
}

String? _cleanString(String? value) {
  final clean = value?.trim();

  return clean == null || clean.isEmpty ? null : clean;
}

String _dateOnly(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
