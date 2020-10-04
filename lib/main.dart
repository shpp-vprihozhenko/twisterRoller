import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
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
      home: MyHomePage(title: 'Интерактивный твистер-роллер'),
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

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: EdgeInsets.all(12),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Привет! \nЯ - интерактивный помощник для игры Твистер.',
                textScaleFactor: 1.3, textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                'Следующий игрок - голосовая команда "ОК",\nПовторить задание - команда "Повтори".',
                textScaleFactor: 1.3, textAlign: TextAlign.center
              ),
              SizedBox(height: 20),
              Text(
                'Для начала игры укажи количество игроков и нажми или скажи "Старт"!',
                textScaleFactor: 1.3, textAlign: TextAlign.center
              ),
              SizedBox(height: 20),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30, height: 30,
                    child: FloatingActionButton(
                      onPressed: (){
                        setState(() {
                          numPlayers--;
                        });
                      },
                      tooltip: 'Decrement',
                      child: Icon(Icons.exposure_minus_1),
                    ),
                  ), // This trailing co,
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Text('$numPlayers', textScaleFactor: 2,),
                  ),
                  Container(
                    width: 35, height: 35,
                    child: FloatingActionButton(
                      onPressed: (){
                        setState(() {
                          numPlayers++;
                        });
                      },
                      tooltip: 'Increment',
                      child: Icon(Icons.exposure_plus_1),
                    ),
                  ), // This trailing co,
                ],
              ),
              SizedBox(height: 20),
              FlatButton(
                color: Colors.blueAccent,
                onPressed: (){
                  print('start with $numPlayers');
                }, 
                child: Container(
                  height: 40,
                  child: Center(child: Text('Старт!'))),
              )            
            ],
          ),
        ),
      ),
      /*
      floatingActionButton: FloatingActionButton(
        onPressed: (){},
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      */
    );
  }
}
