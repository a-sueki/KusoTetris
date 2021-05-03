import 'dart:collection';

import 'package:flutter/material.dart';
import 'score_bar.dart';
import 'game.dart';
import 'next_block.dart';
import 'package:provider/provider.dart';
import 'block.dart';
import 'package:flutter/services.dart';

void main() => runApp(
  ChangeNotifierProvider(
    create: (context) => Data(),
    child: MyApp(),
  ),
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    return MaterialApp(home: Tetoris(),);
  }
}

class Tetoris extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TetorisState();
}

class _TetorisState extends State<Tetoris> {
  GlobalKey<GameState> _keyGame = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Data(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('くそテトリス'),
          centerTitle: true,
          backgroundColor: Colors.brown,
        ),
        backgroundColor: Colors.brown,
        body: Builder(
            builder: (BuildContext newContext){
              return SafeArea(
                child: Column(
                  children: <Widget>[
                    ScoreBar(),
                    Expanded(
                      child: Center(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Flexible(
                              flex: 3,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(10.0, 10.0, 5.0, 10.0),
                                child: Game(key: _keyGame),
                              ),
                            ),
                            Flexible(
                              flex: 1,
                              child: Padding(
                                padding: EdgeInsets.fromLTRB(5.0, 10.0, 10.0, 10.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    NextBlock(),
                                    SizedBox(height: 30,),
                                    ElevatedButton(
                                      child: Text(
                                        newContext.read<Data>().isPlaying
                                            ? 'おわり' : 'はじめ',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[200],
                                        ),
                                      ),
                                      style: ButtonStyle(
                                        backgroundColor: MaterialStateProperty.all<
                                            Color>(Colors.brown[700]),
                                      ),
                                      onPressed: () {
                                        newContext.read<Data>().isPlaying
                                            ? _keyGame.currentState.endGame()
                                            : _keyGame.currentState.startGame();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
        ),
      ),
    );
  }
}

class Data with ChangeNotifier {
  int score = 0;
  bool isPlaying = false;
  Block nextBlock;

  void setScore(score) {
    this.score = score;
    notifyListeners();
  }

  void addScore(score) {
    this.score += score;
    notifyListeners();
  }

  void setIsPlaying(isPlaying) {
    this.isPlaying = isPlaying;
    notifyListeners();
  }

  void setNextBlock(Block nextBlock){
    this.nextBlock = nextBlock;
    notifyListeners();
  }

  Widget getNextBlockWidget() {
    if (!isPlaying) return Container();

    var width = nextBlock.width;
    var height = nextBlock.height;
    var color;
    List<Widget> columns = [];
    for (var y = 0; y < height; ++y) {
      List<Widget> rows = [];
      for (var x = 0; x < width; ++x) {
        if (nextBlock.subBlocks
            .where((subBlock) => subBlock.x == x && subBlock.y == y)
            .length > 0
        ) {
          rows.add(
            Container(width: 12, height: 12,
            child: Image(
              image: AssetImage("images/unchi.png"),
              fit: BoxFit.contain
              ),
            ),
          );
        } else {
          color = Colors.transparent;
          rows.add(Container(width: 12, height: 12, color: color));
        }
      }

      columns.add(
          Row(mainAxisAlignment: MainAxisAlignment.center, children: rows));
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: columns,
    );
  }
}
