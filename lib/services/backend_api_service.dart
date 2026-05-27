import 'dart:convert';
import 'dart:typed_data';
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
  /// Set [forceRefresh] to true to bypass cache and fetch fresh data from spreadsheet
  Future<List<QuestionCategory>> fetchCategories({bool forceRefresh = false}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/categories');
      final uriWithParams = forceRefresh
        ? uri.replace(queryParameters: {'refresh': 'true'})
        : uri;

      final response = await http.get(
        uriWithParams,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Explicitly decode as UTF-8 to handle French accents correctly
        final data = json.decode(utf8.decode(response.bodyBytes));
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
  /// Set [forceRefresh] to true to bypass cache and fetch fresh data from spreadsheet
  Future<List<Map<String, dynamic>>> fetchQuestions({bool forceRefresh = false}) async {
    try {
      final uri = Uri.parse('$baseUrl/api/questions');
      final uriWithParams = forceRefresh
        ? uri.replace(queryParameters: {'refresh': 'true'})
        : uri;

      final response = await http.get(
        uriWithParams,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Explicitly decode as UTF-8 to handle French accents correctly
        final data = json.decode(utf8.decode(response.bodyBytes));
        final questionsJson = data['questions'] as List;

        // Convert API response to format compatible with EssentielCardData.fromGSheet
        // API returns: {question, category, forCouples, forFamilies}
        // We need to map to: {Question, Catégorie, Pour Couples, Pour Familles}
        final questions = questionsJson.map((questionJson) {
          // Safely extract boolean values with fallback to false
          final forCouples = questionJson['forCouples'] == true;
          final forFamilies = questionJson['forFamilies'] == true;

          return {
            'Question': questionJson['question'] as String? ?? '',
            'Catégorie': questionJson['category'] as String? ?? '',
            'Pour Couples': forCouples ? 'Oui' : 'Non',
            'Pour Familles': forFamilies ? 'Oui' : 'Non',
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
