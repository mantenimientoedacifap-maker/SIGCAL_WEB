import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_providers.dart';

final allLoansProvider = FutureProvider.autoDispose<List<LoanRecord>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return const [];

  final response = await client.from('tool_loans').select('''
      id,
      tool_id,
      workshop_id,
      borrower_id,
      borrower_name,
      workshop,
      loan_date,
      expected_return_date,
      returned_at,
      status,
      qr_payload,
      observations,
      return_observations,
      tools!inner(
        id,
        internal_code,
        nomenclature
      ),
      workshops(
        id,
        name
      ),
      borrowers(
        id,
        full_name,
        document_number,
        phone
      )
    ''').order('loan_date', ascending: false);

  return (response as List<dynamic>)
      .whereType<Map<String, dynamic>>()
      .map(LoanRecord.fromMap)
      .toList();
});

class LoanRecord {
  const LoanRecord({
    required this.id,
    required this.toolId,
    required this.toolCode,
    required this.toolName,
    this.workshopId,
    this.workshopName,
    this.borrowerId,
    this.borrowerName,
    this.borrowerDocument,
    this.borrowerPhone,
    required this.loanDate,
    this.expectedReturnDate,
    this.actualReturnDate,
    required this.status,
    this.qrPayload,
    this.observations,
  });

  factory LoanRecord.fromMap(Map<String, dynamic> map) {
    final tool = map['tools'] as Map<String, dynamic>?;
    final workshop = map['workshops'] as Map<String, dynamic>?;
    final borrower = map['borrowers'] as Map<String, dynamic>?;

    return LoanRecord(
      id: map['id'] as String? ?? '',
      toolId: map['tool_id'] as String? ?? '',
      toolCode: tool?['internal_code'] as String?,
      toolName: tool?['nomenclature'] as String? ?? 'Sin nombre',
      workshopId: map['workshop_id'] as String?,
      workshopName: workshop?['name'] as String? ?? map['workshop'] as String?,
      borrowerId: map['borrower_id'] as String?,
      borrowerName:
          borrower?['full_name'] as String? ?? map['borrower_name'] as String?,
      borrowerDocument: borrower?['document_number'] as String?,
      borrowerPhone: borrower?['phone'] as String?,
      loanDate: DateTime.tryParse(map['loan_date'] as String? ?? '') ??
          DateTime.now(),
      expectedReturnDate:
          DateTime.tryParse(map['expected_return_date'] as String? ?? ''),
      actualReturnDate:
          DateTime.tryParse(map['returned_at'] as String? ?? ''),
      status: map['status'] as String? ?? 'ABIERTO',
      qrPayload: map['qr_payload'] as String?,
      observations: map['observations'] as String?,
    );
  }

  final String id;
  final String toolId;
  final String? toolCode;
  final String toolName;
  final String? workshopId;
  final String? workshopName;
  final String? borrowerId;
  final String? borrowerName;
  final String? borrowerDocument;
  final String? borrowerPhone;
  final DateTime loanDate;
  final DateTime? expectedReturnDate;
  final DateTime? actualReturnDate;
  final String status;
  final String? qrPayload;
  final String? observations;

  bool get isOpen => actualReturnDate == null && status != 'RETORNADO' && status != 'CANCELADO';

  bool get isOverdue {
    if (!isOpen || expectedReturnDate == null) return false;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return expectedReturnDate!.isBefore(todayOnly);
  }

  int? get daysToReturn {
    if (expectedReturnDate == null) return null;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return expectedReturnDate!.difference(todayOnly).inDays;
  }

  String get statusLabel => switch (status) {
        'ABIERTO' => 'Activo',
        'RETORNADO' => 'Devuelto',
        'VENCIDO' => 'Vencido',
        'CANCELADO' => 'Cancelado',
        _ => status,
      };
}
