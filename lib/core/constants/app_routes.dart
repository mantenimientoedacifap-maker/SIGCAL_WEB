class AppRoutes {
  const AppRoutes._();

  static const home = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const tools = '/tools';
  static const newTool = '/tools/new';
  static const retiredTools = '/tools/retired';
  static const quarantineTools = '/tools/quarantine';
  static const alerts = '/alerts';
  static const shipments = '/shipments';
  static const newShipment = '/shipments/new';
  static const reports = '/reports';
  static const users = '/users';
  static const settings = '/settings';
  static const resetPassword = '/reset-password';
  static const loans = '/loans';

  static String toolDetail(String id) => '/tools/$id';

  static String editTool(String id) => '/tools/$id/edit';

  static String newCalibration(String id) => '/tools/$id/calibrations/new';

  static String editCalibration(String toolId, String calibrationId) =>
      '/tools/$toolId/calibrations/$calibrationId/edit';
}
