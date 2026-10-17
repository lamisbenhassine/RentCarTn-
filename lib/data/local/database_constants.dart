/// Noms de tables, version et fichier SQLite (sqflite).
///
/// Schéma réservé : les tables seront créées au prochain incrément
/// de [DatabaseConstants.version] lorsque les DAO seront branchés.
abstract final class DatabaseConstants {
  static const String fileName = 'rentcar_tunisia.db';

  /// Version 3 : tables examens + questions (CRUD admin examen final).
  static const int version = 3;

  static const String users = 'users';
  static const String cars = 'cars';
  static const String reservations = 'reservations';
  static const String payments = 'payments';
  static const String auctions = 'auctions';
  static const String bids = 'bids';
  static const String quizResults = 'quiz_results';
  static const String roadSigns = 'road_signs';
  static const String exams = 'exams';
  static const String examQuestions = 'exam_questions';
}
