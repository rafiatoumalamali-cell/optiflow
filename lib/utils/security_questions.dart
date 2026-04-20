import 'dart:math';

class SecurityQuestions {
  SecurityQuestions._();

  static const List<Map<String, String>> questions = [
    {
      'id': 'pet_name',
      'question': 'What was the name of your first pet?',
      'example': 'e.g., Max, Buddy, Luna',
    },
    {
      'id': 'mother_maiden',
      'question': 'What is your mother\'s maiden name?',
      'example': 'e.g., Smith, Johnson, Williams',
    },
    {
      'id': 'first_school',
      'question': 'What was the name of your first school?',
      'example': 'e.g., Lincoln Elementary, Central High',
    },
    {
      'id': 'birth_city',
      'question': 'In what city were you born?',
      'example': 'e.g., Accra, Lagos, Kumasi',
    },
    {
      'id': 'childhood_friend',
      'question': 'What is the name of your childhood best friend?',
      'example': 'e.g., Kwame, Amina, David',
    },
    {
      'id': 'favorite_teacher',
      'question': 'What was the name of your favorite teacher?',
      'example': 'e.g., Mr. Johnson, Mrs. Davis',
    },
    {
      'id': 'first_car',
      'question': 'What was the make and model of your first car?',
      'example': 'e.g., Toyota Camry, Honda Civic',
    },
    {
      'id': 'childhood_nickname',
      'question': 'What was your childhood nickname?',
      'example': 'e.g., Junior, Champ, Speedy',
    },
    {
      'id': 'favorite_food',
      'question': 'What is your favorite food?',
      'example': 'e.g., Jollof rice, Banku, Fufu',
    },
    {
      'id': 'dream_job',
      'question': 'What did you want to be when you were a child?',
      'example': 'e.g., Doctor, Pilot, Teacher',
    },
  ];

  static Map<String, String> getRandomQuestions() {
    final random = Random();
    final shuffled = List<Map<String, String>>.from(questions)..shuffle(random);
    return shuffled.take(3).toList().asMap().map((index, question) => MapEntry(
      'question_${index + 1}',
      question['question']!,
    ));
  }

  static List<Map<String, String>> getAvailableQuestions() {
    return questions;
  }

  static String? getQuestionById(String id) {
    final question = questions.firstWhere(
      (q) => q['id'] == id,
      orElse: () => {},
    );
    return question['question'];
  }

  static bool validateAnswer(String answer) {
    return answer.trim().isNotEmpty && answer.trim().length >= 2;
  }

  static String sanitizeAnswer(String answer) {
    return answer.trim().toLowerCase();
  }

  static bool compareAnswers(String provided, String stored) {
    return sanitizeAnswer(provided) == sanitizeAnswer(stored);
  }
}
