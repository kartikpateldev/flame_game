import 'dart:ui';
import 'package:flame/flame.dart';
import 'package:flame_game/components/callout.dart';
import 'package:flame_game/langaw-game.dart';
import 'package:flame/sprite.dart';
import 'package:flame_game/view.dart';

class Fly {

  final LangawGame game;
  Rect flyRect;
//  Paint flyPaint;
  bool isDead = false;
  bool isOffScreen = false;
  List<Sprite> flyingSprite;
  Sprite deadSprite;
  double flyingSpriteIndex = 0;
  Offset targetLocation;
  Callout callout;

  /*Fly(this.game, double x, double y) {
    flyRect = Rect.fromLTWH(x, y, game.tileSize, game.tileSize);
    flyPaint = Paint();
    flyPaint.color = Color(0xff6ab04c);
  }*/

  Fly(this.game){
    setTargetLocation();
    callout = Callout(this);
  }

  double get speed => game.tileSize * 3;

  void render(Canvas c) {
    if (isDead) {
      deadSprite.renderRect(c, flyRect.inflate(2));
    } else {
      flyingSprite[flyingSpriteIndex.toInt()].renderRect(c, flyRect.inflate(2));
    }
    if (game.activeView == View.playing) {
      callout.render(c);
    }
  }

  void update(double t) {
    if (isDead) {
      flyRect = flyRect.translate(0, game.tileSize * 12 * t);
      if (flyRect.top > game.screenSize.height) {
        isOffScreen = true;
      }
    }else{
      flyingSpriteIndex += 30 * t;
      if (flyingSpriteIndex >= 2) {
        flyingSpriteIndex -= 2;
      }

      double stepDistance = speed * t; // how much we should move the fly
      Offset toTarget = targetLocation - Offset(flyRect.left, flyRect.top); // targetLocation - currentLocation
      if (stepDistance < toTarget.distance) {
        Offset stepToTarget = Offset.fromDirection(toTarget.direction, stepDistance);
        flyRect = flyRect.shift(stepToTarget);
      } else {
        flyRect = flyRect.shift(toTarget);
        setTargetLocation();
      }
      callout.update(t);
    }
  }

  void onTapDown() {
    if (!isDead) {
      isDead = true;
      if (game.soundButton.isEnabled) {
        Flame.audio.play('sfx/ouch' + (game.rnd.nextInt(11) + 1).toString() + '.ogg');
      }


      if (game.activeView == View.playing) {
        // increase the score by one each time.
        game.score += 1;

        // it current score is highest store it using shared prefs and show it on screen
        if (game.score > (game.storage.getInt('highscore') ?? 0)) {
          game.storage.setInt('highscore', game.score);
          game.highscoreDisplay.updateHighscore();
        }
      }
    }
  }

  void setTargetLocation() {
    double x = game.rnd.nextDouble() * (game.screenSize.width - (game.tileSize * 2.025));
    double y = game.rnd.nextDouble() * (game.screenSize.height - (game.tileSize * 2.025));
    targetLocation = Offset(x, y);
  }
}