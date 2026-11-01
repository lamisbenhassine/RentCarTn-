/// Noms de tables, version et fichier SQLite (sqflite).
///
/// Schéma réservé : les tables seront créées au prochain incrément
/// de [DatabaseConstants.version] lorsque les DAO seront branchés.
abstract final class DatabaseConstants {
  static const String fileName = 'rentcar_tunisia.db';

  /// Version 4 : purge des seeds démo (cars / panneaux / examens).
  /// Versions 5 à 7 (équipe) : users.city, public_username, role, puis
  /// réparation du schéma users (auth APK).
  /// Version 8 : colonnes de profil (module User : position, permis,
  /// score de confiance, email_verified…).
  /// Version 9 : table complaints (module Réclamations).
  static const int version = 9;

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
  static const String complaints = 'complaints';
}
