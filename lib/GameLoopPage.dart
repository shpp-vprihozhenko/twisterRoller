import 'dart:math';

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

  double picSize = 200.0;
  List <Color> colorsList = [Colors.green, Colors.blue, Colors.red, Colors.yellow];
  List <String> imgList = ['leftFoot.gif', 'rightFoot.gif', 'leftHand.gif', 'rightHand.gif'];
  List <String> bodyParts = ['Левая нога', 'Правая нога', 'Левая рука', 'Правая рука'];
  List <String> colorNames = ['Зелёный', 'Синий', 'Красный', 'Жёлтый'];
  int _count = 0, _colorCount = 0, _lastKey = 0;
  Color _color = Colors.green;
  static const int refreshPeriodMS = 500;
  int numLoopsToFindResult = 8, numLoop = 0;
  bool speakingMode = false;
  int playerNumber = 1;
  String playerTask = '';

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
    //initTtsAndSttAndFirstSpeech();
    super.initState();
    Future.delayed(const Duration(milliseconds: refreshPeriodMS), randomizerLoop);
  }

  randomizerLoop(){
    showMic = false;
    var rng = new Random();
    int _newCount, _newColorCount; Color _newColor;
    do {
      _newCount = rng.nextInt(4);
      _newColorCount = rng.nextInt(4);
      _newColor = colorsList[_newColorCount];
    } while (_newCount == _count || _newColor == _color);
    numLoop++;
    _lastKey = _count + (_colorCount+1)*16;
    if (numLoop < numLoopsToFindResult) {
      Future.delayed(const Duration(milliseconds: refreshPeriodMS), randomizerLoop);
    } else {
      Future.delayed(const Duration(milliseconds: refreshPeriodMS), (){
        startSpeakAndWaitMode(_newCount, _newColorCount);
      });
    }
    setState(() {
      _count = _newCount;
      _colorCount = _newColorCount;
      _color = _newColor;
    });
  }

  startSpeakAndWaitMode(_newCount, _newColorCount){
    setState(() {
      playerTask = bodyParts[_newCount] + ' на ' + colorNames[_newColorCount] + '!';
      showMic = true;
    });
  }

  void initTtsAndSttAndFirstSpeech() async {
    await initSTT();
    await initTts();
    //firstSpeech();
    //startListening();
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
    //startListening();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Вращаем барабан!', textScaleFactor: 1.4, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10,),
            Center(child: Text('Задание для игрока', textScaleFactor: 2,)),
            SizedBox(height: 10,),
            Center(child: Text('№ $playerNumber', textScaleFactor: 2.5,)),
            SizedBox(height: 20,),
            Center(
              child: Container(
                height: picSize*1.1,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: refreshPeriodMS),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    //return ScaleTransition(child: child, scale: animation);
                    //return FadeTransition(child: child, opacity: animation);
                    //return RotationTransition(child: child, turns: animation);

                    //final offsetAnimation = Tween<Offset>(begin: Offset(-1.0, 0.0), end: Offset(0.0, 0.0)).animate(animation);
                    //return ClipRect(child: SlideTransition(child: child, position: offsetAnimation));

                    final inAnimation =
                    Tween<Offset>(begin: Offset(1.0, 0.0), end: Offset(0.0, 0.0))
                        .animate(animation);
                    final outAnimation =
                    Tween<Offset>(begin: Offset(-1.0, 0.0), end: Offset(0.0, 0.0))
                        .animate(animation);

                    if (child.key == ValueKey(_lastKey)) {
                      return ClipRect(
                        child: SlideTransition(
                          position: inAnimation,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: child,
                          ),
                        ),
                      );
                    } else {
                      return ClipRect(
                        child: SlideTransition(
                          position: outAnimation,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: child,
                          ),
                        ),
                      );
                    }
                    //return ClipRect(child: SlideTransition(child: child, position: offsetAnimation));
                  },
                  child: Container(
                    key: ValueKey<int>(_count + (_colorCount+1)*16),
                    width: picSize, height: picSize,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _color,
                    ),
                    child: Center(
                        child: Image.asset('images/${imgList[_count]}', width: picSize*0.9, height: picSize*0.9,)
                    )
                  ),
                ),
              ),
            ),
            SizedBox(height: 20,),
            Center(child: Text(playerTask, textScaleFactor: 2,)),
            SizedBox(height: 20,),
            showMic?
            Center(
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                        blurRadius: .26,
                        spreadRadius: level * 1.5,
                        color: Colors.black.withOpacity(.1))
                  ],
                  color: Colors.lightGreenAccent,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
                child: Center(
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    onPressed: (){
                      playerNumber++;
                      if (playerNumber > numPlayers) {
                        playerNumber = 1;
                      }
                      setState(() {
                        showMic = false;
                        playerTask = '';
                        numLoop = 0;
                      });
                      randomizerLoop();
                    },
                      child: Icon(Icons.mic, color: Colors.blueAccent, size: 50,)
                  ),
                ),
              ),
            )
            :SizedBox(),
          ],
        )
      ),
    );
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
