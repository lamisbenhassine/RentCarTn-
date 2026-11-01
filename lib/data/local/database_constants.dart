/// Noms de tables, version et fichier SQLite (sqflite).
///
/// Schéma réservé : les tables seront créées au prochain incrément
/// de [DatabaseConstants.version] lorsque les DAO seront branchés.
abstract final class DatabaseConstants {
  static const String fileName = 'rentcar_tunisia.db';

  /// Version 4 : purge des seeds démo (cars / panneaux / examens).
  /// Version 5 : colonnes de profil complètes sur la table users.
  /// Version 6 : users.email_verified (vérification de l'e-mail).
  /// Version 7 : table complaints (module Réclamations).
  static const int version = 7;

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
