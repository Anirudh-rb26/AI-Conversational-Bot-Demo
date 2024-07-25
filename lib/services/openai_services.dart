import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:voice/env/secrets.dart';

class OpenAiServices {
  Future<String> chatGPTAPI(String prompt) async {
    List<Map<String, String>> messages = [
      {'role': 'user', 'content': prompt}
    ];

    try {
      final res = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $openAiApiKey',
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": messages,
        }),
      );

      if (res.statusCode == 200) {
        dynamic responseData = jsonDecode(res.body);
        String content = responseData['choices'][0]['message']['content'];
        content = content.trim();

        messages.add({
          'role': 'assistant',
          'content': content,
        });

        return content;
      } else {
        print('Error: ${res.statusCode} - ${res.reasonPhrase}');
        return 'An internal error occurred. Status code: ${res.statusCode}';
      }
    } catch (e) {
      print('Exception during API call: $e');
      return 'An internal error occurred. Exception: $e';
    }
  }
}
