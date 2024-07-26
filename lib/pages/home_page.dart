import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:location/location.dart';
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
  final Location _location = Location();
  LocationData? _locationData; // Store location data

  bool _speechEnabled = false;
  String _wordsSpoken = "";

  @override
  void initState() {
    super.initState();
    initSpeechToText();
    initTextToSpeech();
    fetchLocation();
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

  Future<void> fetchLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return; // If service is not enabled, exit
      }
    }

    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return; // If permission is denied, exit
      }
    }

    final locationData = await _location.getLocation();
    setState(() {
      _locationData = locationData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            // Location
            Container(
              padding: const EdgeInsets.all(8.0),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blueGrey,
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: _locationData != null
                  ? Text(
                      "Latitude: ${_locationData!.latitude}, Longitude: ${_locationData!.longitude}",
                      style: const TextStyle(fontSize: 20),
                    )
                  : const Text(
                      "Fetching location...",
                      style: TextStyle(fontSize: 20),
                    ),
            ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_speechToText.isNotListening) {
            _startListening();
          } else if (_speechToText.isListening) {
            final speech = await _openAiServices.chatGPTAPI(_wordsSpoken);
            await systemSpeak(speech);
            _stopListening();
          } else {
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
