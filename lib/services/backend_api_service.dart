import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:essentiel/resources/category.dart';

/// Service to fetch data from the backend API
/// The backend API provides categories and questions from Google Sheets
/// without exposing credentials in the web build
class BackendApiService {
  final String baseUrl;

  BackendApiService({required this.baseUrl});

  /// Fetch all categories from the backend API
  /// Returns a list of QuestionCategory objects
  Future<List<QuestionCategory>> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categoriesJson = data['categories'] as List;

        // Convert API response to QuestionCategory objects
        final categories = categoriesJson.map((categoryJson) {
          final name = categoryJson['name'] as String;
          final color = categoryJson['color'] as String;

          // Create category using the same format as GSheets
          final category = QuestionCategory(name, color);
          CategoryStore.put(name, category);
          return category;
        }).toList();

        return categories;
      } else if (response.statusCode == 503) {
        throw Exception('Service indisponible. Impossible de récupérer les données.');
      } else {
        throw Exception('Erreur lors de la récupération des catégories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion au serveur: $e');
    }
  }

  /// Fetch all questions from the backend API
  /// Returns a list of question data as Maps
  /// Note: The API does not return forParentChild - it must be derived client-side
  Future<List<Map<String, dynamic>>> fetchQuestions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/questions'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final questionsJson = data['questions'] as List;

        // Convert API response to format compatible with EssentielCardData.fromGSheet
        // API returns: {question, category, forCouples, forFamilies}
        // We need to map to: {Question, Catégorie, Pour Couples, Pour Familles}
        final questions = questionsJson.map((questionJson) {
          return {
            'Question': questionJson['question'],
            'Catégorie': questionJson['category'],
            'Pour Couples': questionJson['forCouples'] ? 'Oui' : 'Non',
            'Pour Familles': questionJson['forFamilies'] ? 'Oui' : 'Non',
            // Note: forParentChild is NOT in API response - derived from category in EssentielCardData.fromGSheet
          };
        }).toList();

        return questions;
      } else if (response.statusCode == 503) {
        throw Exception('Service indisponible. Impossible de récupérer les questions.');
      } else {
        throw Exception('Erreur lors de la récupération des questions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur de connexion au serveur: $e');
    }
  }
}
