class FileUtils {
  FileUtils._();

  static const allowedDocumentExtensions = ['pdf', 'jpg', 'jpeg', 'png'];

  static bool isAllowedCalibrationDocument(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    return allowedDocumentExtensions.contains(extension);
  }
}
