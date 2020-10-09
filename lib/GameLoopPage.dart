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
//  List <Color> colorsList = [Colors.green, Colors.blue, Colors.red, Colors.yellow];
//  List <String> imgList = ['leftFoot.gif', 'rightFoot.gif', 'leftHand.gif', 'rightHand.gif'];
//  List <String> bodyParts = ['Левая нога', 'Правая нога', 'Левая рука', 'Правая рука'];
//  List <String> colorNames = ['Зелёный', 'Синий', 'Красный', 'Жёлтый'];
  List <String> fullImgList = [
    'greenLeftFoot.gif', 'greenRightFoot.gif', 'greenLeftHand.gif', 'greenRightHand.gif',
    'blueLeftFoot.gif', 'blueRightFoot.gif', 'blueLeftHand.gif', 'blueRightHand.gif',
    'redLeftFoot.gif', 'redRightFoot.gif', 'redLeftHand.gif', 'redRightHand.gif',
    'yellowLeftFoot.gif', 'yellowRightFoot.gif', 'yellowLeftHand.gif', 'yellowRightHand.gif',
  ];
  List <String> fullImgListNames = [
    'Левая нога на Зелёный', 'Правая нога на Зелёный', 'Левая рука на Зелёный', 'Правая рука на Зелёный',
    'Левая нога на Синий', 'Правая нога на Синий', 'Левая рука на Синий', 'Правая рука на Синий',
    'Левая нога на Красный', 'Правая нога на Красный', 'Левая рука на Красный', 'Правая рука на Красный',
    'Левая нога на Жёлтый', 'Правая нога на Жёлтый', 'Левая рука на Жёлтый', 'Правая рука на Жёлтый',
  ];
  int _count = 0, _lastKey = 0; //_colorCount = 0,
  //Color _color = Colors.green;
  static const int refreshPeriodMS = 300;
  int numLoopsToFindResult = 15, numLoop = 0;
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

  var rng = new Random();

  @override
  void initState() {
    initTtsAndStt();
    super.initState();
    Future.delayed(const Duration(milliseconds: refreshPeriodMS), randomizerLoop);
  }

  randomizerLoop(){
    showMic = false;
    int _newCount = rng.nextInt(16);
    print('got new count $_newCount');
    numLoop++;
    _lastKey = _count; // + (_colorCount+1)*16
    if (numLoop < numLoopsToFindResult) {
      Future.delayed(const Duration(milliseconds: refreshPeriodMS), randomizerLoop);
    } else {
      Future.delayed(const Duration(milliseconds: refreshPeriodMS), (){
        startSpeakAndWaitMode(_newCount);
      });
    }
    setState(() {
      _count = _newCount;
    });
  }

  startSpeakAndWaitMode(_newCount) async {
    numLoop = 0;
    setState(() {
      //playerTask = bodyParts[_newCount] + ' на ' + colorNames[_newColorCount] + '!';
      playerTask = fullImgListNames[_newCount] + '!';
      showMic = true;
    });
    await _speakSync('Игрок № $playerNumber');
    await _speakSync(playerTask);
    startListening();
  }

  void initTtsAndStt() async {
    await initSTT();
    await initTts();
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
    print("Received GLP error status: $error, listening: ${speech.isListening}");
    setState(() {
      showMic = false;
    });
    startListening();
  }

  void statusListener(String status) {
    print("Received GLP listener status: $status, listening: ${speech.isListening}");
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
      List <String> recognizedWords = result.recognizedWords.toString().toUpperCase().split(' ');
      if (recognizedWords.indexOf('OK') > -1 || recognizedWords.indexOf('О\'КЕЙ') > -1 || recognizedWords.indexOf('ОК') > -1) {
        print('start new random loop');
        startNextPlayerLoop();
      } else if (recognizedWords.indexOf('ПОВТОРИ') > -1) {
        print('repeat');
        repeatAndStartListeningAgain();
      } else {
        print('no keywords. StartListening again.');
        print(recognizedWords);
        startListening();
      }
    }
  }

  repeatAndStartListeningAgain() async {
    await _speakSync('Игрок № $playerNumber');
    await _speakSync(playerTask);
    startListening();
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
                    key: ValueKey<int>(_count), // + (_colorCount+1)*16
                    width: picSize, height: picSize,
/*
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _color,
                    ),
                  child: Center(
                  child: Image.asset('images/${imgList[_count]}', width: picSize*0.9, height: picSize*0.9,)
                    )
 */
                      child: Image.asset('images/${fullImgList[_count]}')
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
                      startNextPlayerLoop();
                    },
                    child: Icon(Icons.mic, color: Colors.blueAccent, size: 50,)
                  ),
                ),
              ),
            )
            :SizedBox(),
            SizedBox(height: 10,),
            showMic? FlatButton(
              color: Colors.lightBlueAccent,
              child: Text('Следующий игрок', textScaleFactor: 1.5,),
              onPressed: startNextPlayerLoop,
            )
            : SizedBox(),
          ],
        )
      ),
    );
  }

  startNextPlayerLoop(){
    playerNumber++;
    if (playerNumber > numPlayers) {
      playerNumber = 1;
    }
    setState(() {
      showMic = false;
      playerTask = '';
    });
    randomizerLoop();
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
