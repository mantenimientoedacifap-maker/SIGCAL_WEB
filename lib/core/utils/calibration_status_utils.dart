import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum CalibrationStatus {
  vigente,
  alertaAmarilla,
  alertaNaranja,
  vencido,
  sinCalibracion,
  enCalibracion,
}

extension CalibrationStatusPresentation on CalibrationStatus {
  String get label {
    return switch (this) {
      CalibrationStatus.vigente => '',
      CalibrationStatus.alertaAmarilla => 'Alerta amarilla',
      CalibrationStatus.alertaNaranja => 'Alerta naranja',
      CalibrationStatus.vencido => 'Vencido',
      CalibrationStatus.sinCalibracion => '',
      CalibrationStatus.enCalibracion => '',
    };
  }

  Color get color {
    return switch (this) {
      CalibrationStatus.vigente => AppColors.success,
      CalibrationStatus.alertaAmarilla => AppColors.warning,
      CalibrationStatus.alertaNaranja => AppColors.critical,
      CalibrationStatus.vencido => AppColors.danger,
      CalibrationStatus.sinCalibracion => AppColors.muted,
      CalibrationStatus.enCalibracion => AppColors.calibration,
    };
  }
}

class CalibrationStatusUtils {
  CalibrationStatusUtils._();

  static CalibrationStatus resolve({
    DateTime? expirationDate,
    bool hasActiveShipment = false,
    DateTime? currentDate,
  }) {
    if (hasActiveShipment) {
      return CalibrationStatus.enCalibracion;
    }

    if (expirationDate == null) {
      return CalibrationStatus.sinCalibracion;
    }

    final today = DateUtils.dateOnly(currentDate ?? DateTime.now());
    final expiration = DateUtils.dateOnly(expirationDate);
    final daysRemaining = expiration.difference(today).inDays;

    if (daysRemaining < 0) {
      return CalibrationStatus.vencido;
    }

    if (daysRemaining <= 15) {
      return CalibrationStatus.alertaNaranja;
    }

    if (daysRemaining <= 30) {
      return CalibrationStatus.alertaAmarilla;
    }

    return CalibrationStatus.vigente;
  }
}
