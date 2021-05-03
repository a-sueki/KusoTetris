import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'block.dart';
import 'dart:math';
import 'dart:async';
import 'sub_block.dart';
import 'main.dart';

enum Collision {
  LANDED, LANDED_BLOCK, HIT_WALL, HIT_BLOCK, NONE
}

const BLOCK_X = 10;
const BLOCK_Y = 20;
const GAME_AREA_BORDER_WIDTH = 2.0;
const REFRESH_RATE = 300;
const SUB_BLOCK_EDGE_WIDTH = 2.0;


class Game extends StatefulWidget {
  Game({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => GameState();
}

class GameState extends State<Game> {
  double subBlockWidth;
  Block block;
  GlobalKey _keyGameArea = GlobalKey();
  Duration duration = Duration(milliseconds: REFRESH_RATE);
  Timer timer;
  BlockMovement action;
  bool isGameOver = false;

  List<SubBlock> oldSubBlocks;

  Block getNewBlock() {
    int blockType = Random().nextInt(7);
    int orientationIndex = Random().nextInt(4);

    switch (blockType){
      case 0:
        return IBlock(orientationIndex);
      case 1:
        return JBlock(orientationIndex);
      case 2:
        return LBlock(orientationIndex);
      case 3:
        return OBlock(orientationIndex);
      case 4:
        return TBlock(orientationIndex);
      case 5:
        return SBlock(orientationIndex);
      case 6:
        return ZBlock(orientationIndex);
      default:
        return null;
    }
  }

  void startGame() {
    Provider.of<Data>(context, listen: false).setIsPlaying(true);
    Provider.of<Data>(context, listen: false).setScore(0);

    isGameOver = false;
    oldSubBlocks = <SubBlock>[];

    RenderBox renderBoxGame = _keyGameArea.currentContext.findRenderObject();
    subBlockWidth =
        (renderBoxGame.size.width - GAME_AREA_BORDER_WIDTH * 2) / BLOCK_X;

    Provider.of<Data>(context, listen: false).setNextBlock(getNewBlock());

    block = getNewBlock();
    timer = Timer.periodic(duration, onPlay);
  }

  void endGame() {
    Provider.of<Data>(context, listen: false).setIsPlaying(false);
    timer.cancel();
  }

  void onPlay(Timer timer) {
    var status = Collision.NONE;

    setState(() {
      if(action != null) {
        if (!checkOnEdge(action)) {
          block.move(action);
        }
      }

      for (var oldSubBlock in oldSubBlocks) {
        for (var subBlock in block.subBlocks) {
          var x = block.x + subBlock.x;
          var y = block.y + subBlock.y;
          if (x == oldSubBlock.x && y == oldSubBlock.y) {
            switch (action) {
              case BlockMovement.LEFT:
                block.move(BlockMovement.RIGHT);
                break;
              case BlockMovement.RIGHT:
                block.move(BlockMovement.LEFT);
                break;
              case BlockMovement.ROTATE_CLOCKWISE:
                block.move(BlockMovement.ROTATE_COUNTER_CLOCKWISE);
                break;
              default:
                break;
            }
          }
        }
      }

      if (!checkAtBottom()) {
        if (!checkAboveBlock()){
          block.move(BlockMovement.DOWN);
        } else {
          status = Collision.LANDED_BLOCK;
        }
      } else {
        status = Collision.LANDED;
      }

      if (status == Collision.LANDED_BLOCK && block.y < 0) {
        isGameOver = true;
        endGame();
      } else if (status == Collision.LANDED || status == Collision.LANDED_BLOCK) {
        block.subBlocks.forEach((subBlock){
          subBlock.x += block.x;
          subBlock.y += block.y;
          oldSubBlocks.add(subBlock);
        });
        block = Provider.of<Data>(context, listen: false).nextBlock;
        Provider.of<Data>(context, listen: false).setNextBlock(getNewBlock());
      }

      action = null;
      updateScore();

    });
  }


  void updateScore() {
    var combo = 1;
    Map<int, int> rows = Map();
    List<int> rowsToBeRemoved = [];

    oldSubBlocks?.forEach((subBlock) {
      rows.update(subBlock.y, (value) => ++value, ifAbsent: () => 1);
    });

    rows.forEach((rowNum, count) {
      if(count == BLOCK_X){
        Provider.of<Data>(context, listen: false).addScore(combo++);
        rowsToBeRemoved.add(rowNum);
      }
    });

    if(rowsToBeRemoved.length > 0){
      removeRows(rowsToBeRemoved);
    }
  }

  void removeRows(List<int> rowsToBeRemoved) {
    rowsToBeRemoved.sort();
    rowsToBeRemoved.forEach((rowNum) {
      oldSubBlocks.removeWhere((subBlock) => subBlock.y == rowNum);
      oldSubBlocks.forEach((subBlock) {
        if (subBlock.y < rowNum) {
          ++subBlock.y;
        }
      });
    });
  }

  bool checkAtBottom() {
    return block.y + block.height == BLOCK_Y;
  }

  bool checkAboveBlock(){
    for (var oldSubBlock in oldSubBlocks){
      for (var subBlock in block.subBlocks){
        var x = block.x + subBlock.x;
        var y = block.y + subBlock.y;
        if (x == oldSubBlock.x && y + 1 == oldSubBlock.y){
          return true;
        }
      }
    }
    return false;
  }

  bool checkOnEdge(BlockMovement action) {
    return (action == BlockMovement.LEFT && block.x <= 0) ||
        (action == BlockMovement.RIGHT && block.x + block.width >= BLOCK_X);
  }

  Widget getPositionedSquareContainer(Color color, int x, int y) {
    return Positioned(
      left: x * subBlockWidth,
      top: y * subBlockWidth,
      child: Container(
        width: subBlockWidth - SUB_BLOCK_EDGE_WIDTH,
        height: subBlockWidth - SUB_BLOCK_EDGE_WIDTH,
        child: Image(image: AssetImage("images/unchi.png"),
        fit: BoxFit.contain),
      ),
    );
  }

  Widget drawBlocks() {
    if (block == null) return null;
    List<Positioned> subBlocks = [];

    block.subBlocks.forEach((subBlock){
      subBlocks.add(getPositionedSquareContainer(
          subBlock.color,
          subBlock.x + block.x,
          subBlock.y + block.y));
    });

    oldSubBlocks?.forEach((oldSubBlock) {
      subBlocks.add(getPositionedSquareContainer(
          oldSubBlock.color, oldSubBlock.x, oldSubBlock.y));
    });

    if (isGameOver) {
      subBlocks.add(getGameOverRect());
    }
    return Stack(children: subBlocks,);
  }

  Widget getGameOverRect() {
    return Positioned(
        child: Container(
          width: subBlockWidth * 8.0,
          height: subBlockWidth * 3.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          child: Text('げーむおーばー',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.white
            ),
          ),
        ),
      left: subBlockWidth * 1.0,
      top: subBlockWidth * 6.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if(details.delta.dx > 0) {
          action = BlockMovement.RIGHT;
        } else {
          action = BlockMovement.LEFT;
        }
      },
      onTap: (){
        action = BlockMovement.ROTATE_CLOCKWISE;
      },
      child: AspectRatio(
        aspectRatio: BLOCK_X / BLOCK_Y,
        child: Container(
          key: _keyGameArea,
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                width: GAME_AREA_BORDER_WIDTH,
                color: Colors.blueGrey,
              ),
              borderRadius: BorderRadius.all(Radius.circular(10))
          ),
          child: drawBlocks(),
        ),
      ),
    );
  }
}