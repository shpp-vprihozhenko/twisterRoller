import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

class GameLoopPage extends StatefulWidget {
  final numPlayers;
  GameLoopPage(this.numPlayers);

  @override
  _GameLoopPageState createState() => _GameLoopPageState(numPlayers);
}

class _GameLoopPageState extends State<GameLoopPage> {
  final numPlayers;
  _GameLoopPageState(this.numPlayers);

  bool speakingMode = false;

  final SpeechToText speech = SpeechToText();
  bool showMic = false;
  double level=0;

  FlutterTts flutterTts;
  dynamic languages;
  String language;
  double volume = 1;
  double pitch = 1.2;
  double rate = 1.2;

  @override
  void initState() {
    initTtsAndSttAndFirstSpeech();
    super.initState();
  }

  void initTtsAndSttAndFirstSpeech() async {
    await initSTT();
    await initTts();
    //firstSpeech();
    startListening();
  }

  initSTT() async {
    bool hasSpeech = await speech.initialize(
        onError: errorListener, onStatus: statusListener);

    speech.errorListener = errorListener;
    speech.statusListener = statusListener;

    print('initSpeechState hasSpeech $hasSpeech');

    if (hasSpeech) {
      //var _localeNames = await speech.locales();
      var systemLocale = await speech.systemLocale();
      var _currentLocaleId = systemLocale.localeId;
      print('initSpeechState _currentLocaleId $_currentLocaleId');
    }

    if (!hasSpeech) {
      print('STT not mounted.');
      return;
    }
  }

  void errorListener(SpeechRecognitionError error) {
    print("Received Eng error status: $error, listening: ${speech.isListening}");
    setState(() {
      showMic = false;
    });
    startListening();
  }

  void statusListener(String status) {
    print("Received listener status: $status, listening: ${speech.isListening}");
  }

  void startListening() {
    setState(() {
      showMic = true;
    });
    speech.listen(
      onResult: resultListener,
      // listenFor: Duration(seconds: 60),
      // pauseFor: Duration(seconds: 3),
      localeId: 'ru_RU', // en_US uk_UA ru_RU
      onSoundLevelChange: soundLevelListener,
      cancelOnError: true,
      partialResults: true,
      // onDevice: true,
      // listenMode: ListenMode.confirmation,
      // sampleRate: 44100,
    );
  }

  void soundLevelListener(double level) {
    setState(() {
      this.level = level;
    });
  }

  void resultListener(SpeechRecognitionResult result) async {
    print ('got result $result');

    if (result.finalResult) {
      setState(() {
        showMic = false;
      });
      String recognizedWords = result.recognizedWords.toString().toUpperCase();
//      if (recognizedWords.indexOf('СТАРТ') == -1) {
//        print('no start, repeat stt loop');
//        startListening();
//      } else {
//        goToStartGamePage();
//      }
    }
  }

  Future _getLanguages() async {
    languages = await flutterTts.getLanguages;
    if (!isSupportedLanguageInList()) {
      showAlertPage(
          'Извините, в Вашем телефоне не установлен требуемый TTS-язык. Обновите ваш синтезатор речи (Google TTS).');
    }
  }

  isSupportedLanguageInList() {
    for (var lang in languages) {
      if (lang.toString().toUpperCase() == 'RU-RU') {
        print('ru lang present');
        return true;
      }
    }
    print('no ru lang present');
    return false;
  }

  Future _setSpeakParameters() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    // ru-RU uk-UA en-US
    await flutterTts.setLanguage('ru-RU');
  }

  Future<void> _speak(String _text, bool asyncMode) async {
    if (_text != null) {
      if (_text.isNotEmpty) {
        if (asyncMode) {
          flutterTts.speak(_text);
        } else {
          await flutterTts.speak(_text);
        }
      }
    }
  }

  Future<void> _speakSync(String _text) {
    final c = new Completer();
    speakingMode = true;
    flutterTts.setCompletionHandler(() {
      c.complete("ok");
      setState((){
        speakingMode = false;
      });
    });
    _speak(_text, false);
    return c.future;
  }

  initTts() async {
    flutterTts = FlutterTts();
    _getLanguages();
    await _setSpeakParameters();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  showAlertPage(String msg) {
    showAboutDialog(
      context: context,
      applicationName: 'Alert',
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 15), child: Center(child: Text(msg)))
      ],
    );
  }

}
