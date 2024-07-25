import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:voice/services/openai_services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final OpenAiServices _openAiServices = OpenAiServices();
  bool _speechEnabled = false;
  String _wordsSpoken = "";

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    initTextToSpeech();
  }

  void initSpeechToText() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult);
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(result) {
    setState(() {
      _wordsSpoken = result.recognizedWords;
    });
  }

  void initTextToSpeech() async {
    await _tts.setSharedInstance(true);
    setState(() {});
  }

  Future<void> systemSpeak(String content) async {
    await _tts.speak(content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App Bar
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: const Text(
          "AI Voice Assistant",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            // Heading
            Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blueGrey,
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Text(
                _speechToText.isListening
                    ? "Listening..."
                    : _speechEnabled
                        ? "Tap the microphone to start listening."
                        : "Speech not available",
                style: const TextStyle(fontSize: 20.0),
              ),
            ),
            // Spoken Words (visible only when listening)
            if (_speechToText.isListening)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(8.0),
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.blueGrey,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Text(
                    _wordsSpoken,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      // Floating Action Button (controls mic input)
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_speechToText.isNotListening) {
            // print("Start listening...");
            _startListening();
          } else if (_speechToText.isListening) {
            // print("Stop listening...");
            // const _wordsSpokenTest = "tell me about ai in simple words";
            final speech = await _openAiServices.chatGPTAPI(_wordsSpoken);
            // print("Received response from chatGPTAPI: $speech");
            await systemSpeak(speech);
            // print("Spoken: $speech");
            _stopListening();
            print("Stopped listening.");
          } else {
            // print("Initialize speech to text...");
            initSpeechToText();
          }
        },
        tooltip: "Listen",
        backgroundColor: Colors.deepPurpleAccent,
        child: Icon(
          _speechToText.isNotListening ? Icons.mic_off : Icons.mic,
          color: Colors.white,
        ),
      ),
    );
  }
}
