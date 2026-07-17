// lib/models/poll.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

class PollOption {
  final int optionId; // ID строки из poll_options (для API голосования)
  final int optionNumber; // Номер опции (0-based index, для внутреннего использования и отображения)
  final String text;
  final int votes;
  final double percentage;
  final bool isSelected;
  final bool? isCorrect; // Только для викторин, после голосования

  PollOption({
    required this.optionId,
    required this.optionNumber,
    required this.text,
    required this.votes,
    required this.percentage,
    required this.isSelected,
    this.isCorrect,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      optionId: json['option_id'] as int? ?? -1, // Используем ID строки из poll_options
      optionNumber: json['option_number'] as int? ?? -1, // Используем option_number
      text: json['text'] as String? ?? '',
      votes: json['votes'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      isSelected: json['is_selected'] as bool? ?? false,
      isCorrect: json['is_correct'] as bool?, // Может быть null до голосования или если не викторина
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'option_id': optionId,
      'option_number': optionNumber,
      'text': text,
      'votes': votes,
      'percentage': percentage,
      'is_selected': isSelected,
      if (isCorrect != null) 'is_correct': isCorrect,
    };
  }
}

class Poll {
  final String pollId;
  final String question;
  final bool isQuiz;
  final int? correctOptionId; // Может быть null до голосования или если не викторина
  final List<PollOption> options;
  final int totalVotes;
  final bool hasVoted;

  Poll({
    required this.pollId,
    required this.question,
    required this.isQuiz,
    this.correctOptionId,
    required this.options,
    required this.totalVotes,
    required this.hasVoted,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      pollId: json['poll_id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      isQuiz: json['is_quiz'] as bool? ?? false,
      correctOptionId: json['correct_option_id'] as int?,
      options: (json['options'] as List<dynamic>?)
              ?.map((optJson) => PollOption.fromJson(optJson))
              .toList() ??
          [],
      totalVotes: json['total_votes'] as int? ?? 0,
      hasVoted: json['has_voted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'poll_id': pollId,
      'question': question,
      'is_quiz': isQuiz,
      if (correctOptionId != null) 'correct_option_id': correctOptionId,
      'options': options.map((opt) => opt.toJson()).toList(),
      'total_votes': totalVotes,
      'has_voted': hasVoted,
    };
  }
}