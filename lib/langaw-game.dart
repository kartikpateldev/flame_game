import 'dart:math';
import 'dart:ui';
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flame_game/components/backyard.dart';
import 'package:flame_game/components/credits-button.dart';
import 'package:flame_game/components/fly.dart';
import 'package:flame_game/components/help-button.dart';
import 'package:flame_game/components/highscore-display.dart';
import 'package:flame_game/components/house-fly.dart';
import 'package:flame_game/components/agile-fly.dart';
import 'package:flame_game/components/drooler-fly.dart';
import 'package:flame_game/components/hungry-fly.dart';
import 'package:flame_game/components/music-button.dart';
import 'package:flame_game/components/score-display.dart';
import 'package:flame_game/components/sound-button.dart';
import 'package:flame_game/views/credits-view.dart';
import 'package:flame_game/views/help-view.dart';
import 'package:flame_game/views/lost-view.dart';
import 'package:flame_game/components/macho-fly.dart';
import 'package:flame_game/components/start-button.dart';
import 'package:flame_game/controllers/spawner.dart';
import 'package:flame_game/views/home-view.dart';
import 'package:flutter/gestures.dart';
import 'package:flame_game/view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LangawGame extends Game {
  final SharedPreferences storage;
  Size screenSize;
  double tileSize;
  Random rnd;

  Backyard background;
  List<Fly> flies;
  StartButton startButton;
  HelpButton helpButton;
  CreditsButton creditsButton;

  FlySpawner spawner;

  View activeView = View.home;
  HomeView homeView;
  LostView lostView;
  HelpView helpView;
  CreditsView creditsView;

  int score;
  ScoreDisplay scoreDisplay;
  HighscoreDisplay highscoreDisplay;

  AudioPlayer homeBGM;
  AudioPlayer playingBGM;
  MusicButton musicButton;
  SoundButton soundButton;

  LangawGame(this.storage) {
    initialize();
  }

  void initialize() async {
    score = 0;
    rnd = Random();
    flies = List<Fly>();
    resize(await Flame.util.initialDimensions());

    background = Backyard(this);

    startButton = StartButton(this);
    helpButton = HelpButton(this);
    creditsButton = CreditsButton(this);

    spawner = FlySpawner(this);

    homeView = HomeView(this);
    lostView = LostView(this);
    helpView = HelpView(this);
    creditsView = CreditsView(this);
    scoreDisplay = ScoreDisplay(this);
    highscoreDisplay = HighscoreDisplay(this);

    homeBGM = await Flame.audio.loop('bgm/home.mp3', volume: .25);
    homeBGM.pause();
    playingBGM = await Flame.audio.loop('bgm/playing.mp3', volume: .25);
    playingBGM.pause();

    playHomeBGM();
  }

  void playHomeBGM() {
    playingBGM.pause();
    playingBGM.seek(Duration.zero);
    homeBGM.resume();
  }

  void playPlayingBGM() {
    homeBGM.pause();
    homeBGM.seek(Duration.zero);
    playingBGM.resume();
  }

  void spawnFly() {
    double x = rnd.nextDouble() * (screenSize.width - (tileSize * 2.025));
    double y = rnd.nextDouble() * (screenSize.height - (tileSize * 2.025));
    switch (rnd.nextInt(5)) {
      case 0:
        flies.add(HouseFly(this, x, y));
        break;
      case 1:
        flies.add(DroolerFly(this, x, y));
        break;
      case 2:
        flies.add(AgileFly(this, x, y));
        break;
      case 3:
        flies.add(MachoFly(this, x, y));
        break;
      case 4:
        flies.add(HungryFly(this, x, y));
        break;
    }
  }

  void render(Canvas canvas) {
    //first render the background
    background.render(canvas);

    highscoreDisplay.render(canvas);

    // render the score just after the background
    if (activeView == View.playing) scoreDisplay.render(canvas);

    flies.forEach((Fly fly) => fly.render(canvas));

    if (activeView == View.home) homeView.render(canvas);

    if (activeView == View.home || activeView == View.lost) {
      startButton.render(canvas);
      helpButton.render(canvas);
      creditsButton.render(canvas);
    }

    if (activeView == View.lost) lostView.render(canvas);

    helpButton.render(canvas);
    creditsButton.render(canvas);

    musicButton.render(canvas);
    soundButton.render(canvas);

    if (activeView == View.help) helpView.render(canvas);
    if (activeView == View.credits) creditsView.render(canvas);
  }

  void update(double t) {
    spawner.update(t);
    flies.forEach((Fly fly) => fly.update(t));
    flies.removeWhere((Fly fly) => fly.isOffScreen);
    if (activeView == View.playing) scoreDisplay.update(t);
  }

  void resize(Size size) {
    screenSize = size;
    tileSize = screenSize.width / 9;
  }

  void onTapDown(TapDownDetails d) {
    bool isHandled = false;

    // dialog boxes outside tap handling
    if (!isHandled) {
      if (activeView == View.help || activeView == View.credits) {
        activeView = View.home;
        isHandled = true;
      }
    }

    // music button
    if (!isHandled && musicButton.rect.contains(d.globalPosition)) {
      musicButton.onTapDown();
      isHandled = true;
    }

    // sound button
    if (!isHandled && soundButton.rect.contains(d.globalPosition)) {
      soundButton.onTapDown();
      isHandled = true;
    }

    // help button
    if (!isHandled && helpButton.rect.contains(d.globalPosition)) {
      if (activeView == View.home || activeView == View.lost) {
        helpButton.onTapDown();
        isHandled = true;
      }
    }

    // credits button
    if (!isHandled && creditsButton.rect.contains(d.globalPosition)) {
      if (activeView == View.home || activeView == View.lost) {
        creditsButton.onTapDown();
        isHandled = true;
      }
    }

    // start button
    if (!isHandled && startButton.rect.contains(d.globalPosition)) {
      if (activeView == View.home || activeView == View.lost) {
        startButton.onTapDown();
        isHandled = true;
      }
    }

    //flies
    if (!isHandled) {
      bool didHitAFly = false;
      flies.forEach((Fly fly) {
        if (fly.flyRect.contains(d.globalPosition)) {
          fly.onTapDown();
          isHandled = true;
          didHitAFly = true;
        }
      });
      if (activeView == View.playing && !didHitAFly) {
        if (soundButton.isEnabled) {
          Flame.audio.play('sfx/haha' + (rnd.nextInt(5) + 1).toString() + '.ogg');
        }
        playHomeBGM();
        activeView = View.lost;
      }
    }
  }
}