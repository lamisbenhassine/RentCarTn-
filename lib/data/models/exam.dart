import 'dart:convert';

import 'package:flutter/material.dart';

import 'learning.dart';

/// Question d'un examen (QCM).
class ExamQuestion {
  const ExamQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.sortOrder = 0,
  });

  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int sortOrder;

  bool isCorrect(int index) => index == correctIndex;

  ExamQuestion copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? correctIndex,
    String? explanation,
    int? sortOrder,
  }) {
    return ExamQuestion(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      explanation: explanation ?? this.explanation,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toMap({String? examId}) => {
        'id': id,
        'exam_id': ?examId,
        'question': question,
        'options_json': jsonEncode(options),
        'correct_index': correctIndex,
        'explanation': explanation,
        'sort_order': sortOrder,
      };

  factory ExamQuestion.fromMap(Map<String, Object?> map) {
    final rawOptions = map['options_json'];
    List<String> options;
    if (rawOptions is String) {
      options = (jsonDecode(rawOptions) as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    } else if (rawOptions is List) {
      options = rawOptions.map((e) => e.toString()).toList();
    } else {
      options = const [];
    }

    return ExamQuestion(
      id: map['id']! as String,
      question: map['question']! as String,
      options: options,
      correctIndex: (map['correct_index'] as num?)?.toInt() ?? 0,
      explanation: (map['explanation'] as String?) ?? '',
      sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'sortOrder': sortOrder,
      };

  factory ExamQuestion.fromJson(Map<String, Object?> json) {
    return ExamQuestion(
      id: json['id']! as String,
      question: json['question']! as String,
      options: (json['options'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: (json['explanation'] as String?) ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Examen administrable (CRUD). Le passage utilisateur viendra plus tard.
class Exam {
  const Exam({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    this.passingPercent = 70,
    this.isPublished = true,
    this.isFinal = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final List<ExamQuestion> questions;
  final int passingPercent;
  final bool isPublished;
  final bool isFinal;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  int get questionCount => questions.length;

  Exam copyWith({
    String? id,
    String? title,
    String? description,
    List<ExamQuestion>? questions,
    int? passingPercent,
    bool? isPublished,
    bool? isFinal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exam(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      passingPercent: passingPercent ?? this.passingPercent,
      isPublished: isPublished ?? this.isPublished,
      isFinal: isFinal ?? this.isFinal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'title': title,
        'description': description,
        'passing_percent': passingPercent,
        'is_published': isPublished ? 1 : 0,
        'is_final': isFinal ? 1 : 0,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
        'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      };

  factory Exam.fromRow(
    Map<String, Object?> row, {
    List<ExamQuestion> questions = const [],
  }) {
    return Exam(
      id: row['id']! as String,
      title: row['title']! as String,
      description: (row['description'] as String?) ?? '',
      passingPercent: (row['passing_percent'] as num?)?.toInt() ?? 70,
      isPublished: ((row['is_published'] as num?)?.toInt() ?? 1) == 1,
      isFinal: ((row['is_final'] as num?)?.toInt() ?? 1) == 1,
      questions: questions,
      createdAt: DateTime.tryParse((row['created_at'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((row['updated_at'] as String?) ?? ''),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'passingPercent': passingPercent,
        'isPublished': isPublished,
        'isFinal': isFinal,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'questions': questions.map((q) => q.toJson()).toList(),
      };

  factory Exam.fromJson(Map<String, Object?> json) {
    final rawQuestions = (json['questions'] as List<dynamic>? ?? [])
        .map((e) => ExamQuestion.fromJson(Map<String, Object?>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Exam(
      id: json['id']! as String,
      title: json['title']! as String,
      description: (json['description'] as String?) ?? '',
      passingPercent: (json['passingPercent'] as num?)?.toInt() ?? 70,
      isPublished: json['isPublished'] as bool? ?? true,
      isFinal: json['isFinal'] as bool? ?? true,
      questions: rawQuestions,
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((json['updatedAt'] as String?) ?? ''),
    );
  }

  /// Adaptateur pour l'écran quiz / dashboard utilisateur.
  Quiz toQuiz() {
    return Quiz(
      id: id,
      title: title,
      description: description,
      icon: Icons.workspace_premium_rounded,
      color: const Color(0xFF7C3AED),
      isFinalTest: isFinal,
      passingPercent: passingPercent,
      questions: [
        for (final q in questions)
          QuizQuestion(
            id: q.id,
            question: q.question,
            options: q.options,
            correctIndex: q.correctIndex,
            explanation: q.explanation,
          ),
      ],
    );
  }
}
