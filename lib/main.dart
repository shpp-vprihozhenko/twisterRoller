import 'package:flutter/services.dart';

import 'GameLoopPage.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) => runApp(MyApp()));
  //runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Твистер-роллер',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Твистер-роллер'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  int numPlayers = 3;
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
  initState() {
    super.initState();
    initTtsAndSttAndFirstSpeech();
  }

  void initTtsAndSttAndFirstSpeech() async {
    await initSTT();
    await initTts();
    //firstSpeech();
    startListening();
  }

  initSTT() async {
    print('init STT from main');
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
    print('start listening');
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
      if (recognizedWords.indexOf('СТАРТ') == -1) {
        print('no start, repeat stt loop');
        startListening();
      } else {
        goToStartGamePage();
      }
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

  firstSpeech() async {
    await _speakSync('Привет! Я - интерактивный помощник для игры в Твистер.');
    await _speakSync('Я понимаю такие голосовые команды:');
    await _speakSync('"ОК" - следующий игрок.');
    await _speakSync('"А ну повтори!" - повторить задание.');
    await _speakSync('Для начала игры укажи количество игроков и нажми или скажи "Старт"!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, textScaleFactor: 1.4, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Container(
        padding: EdgeInsets.all(12),
        child: Center(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(10.0),
            children: <Widget>[
              buildSmileIcon(),
              Text(
                '\nПривет! \nЯ - интерактивный помощник для игры Твистер.',
                textScaleFactor: 1.3, textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                  'Я понимаю такие госовые команды: \n   "ОК" - следующий игрок,\n   "А ну повтори!" - повторить задание.',
                  textScaleFactor: 1.3, textAlign: TextAlign.center
              ),
              SizedBox(height: 20),
              Text(
                  'Для начала игры укажи количество игроков и нажми или скажи "Старт"!',
                  textScaleFactor: 1.3, textAlign: TextAlign.center
              ),
              SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: EdgeInsets.all(10),
                      width: 30, height: 30,
                      child: FloatingActionButton(
                        onPressed: (){
                          setState(() {
                            numPlayers--;
                          });
                        },
                        tooltip: 'уменьшить',
                        child: Icon(Icons.exposure_minus_1),
                        heroTag: 'decrease',
                      ),
                    ), // This trailing co,
                    Container(
                      padding: EdgeInsets.all(10),
                      child: Text('$numPlayers', textScaleFactor: 2.2,),
                    ),
                    Container(
                      margin: EdgeInsets.all(10),
                      width: 35, height: 35,
                      child: FloatingActionButton(
                        onPressed: (){
                          setState(() {
                            numPlayers++;
                          });
                        },
                        tooltip: 'увеличить',
                        child: Icon(Icons.exposure_plus_1),
                        heroTag: 'increase',
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              FlatButton(
                color: Colors.blueAccent,
                onPressed: (){
                  print('start with $numPlayers');
                  goToStartGamePage();
                },
                child: Container(
                    height: 40,
                    child: Center(child: Text('Старт!', textScaleFactor: 1.5, style: TextStyle(color: Colors.white)))),
              ),
              SizedBox(height: 10,),
              showMic?
              Center(
                child: Container(
                  width: 40, height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                          blurRadius: .26,
                          spreadRadius: level * 1.5,
                          color: Colors.black.withOpacity(.1))
                    ],
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.all(Radius.circular(50)),
                  ),
                  child: IconButton(icon: Icon(Icons.mic, color: Colors.blueAccent)),
                ),
              )
                //IconButton(icon: Icon(Icons.mic, color: Colors.blueAccent,), onPressed: (){})
                :SizedBox(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSmileIcon() {
    return speakingMode? Image.asset('images/speakingSmile.gif', width: 100, height: 100,)
        : Image.asset('images/notSpeakingSmile.jpg', width: 100, height: 100,);
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

  goToStartGamePage() {
    try {
      print('speech.stop from goToStartGamePage');
      speech.errorListener = null;
      speech.statusListener = null;
      speech.stop();
    } catch (e) {
      print('err on speech stop $e');
    }
    print('start game for $numPlayers');
    Navigator.push(context,
        MaterialPageRoute(builder: (context) => GameLoopPage(numPlayers))
    ).then((result){
      print('cb from push');
      Future.delayed(const Duration(milliseconds: 200), () async {
        await initSTT();
        speech.errorListener = errorListener;
        speech.statusListener = statusListener;
        startListening();
      });
    });
  }
}
