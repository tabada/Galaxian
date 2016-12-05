
import ddf.minim.*; // Import Sound Library

class SoundPlayer {
  Minim minimplay;
  AudioSample boomPlayer, popPlayer, boomMonster, shootSnow;
  AudioPlayer backgroundMusic;

  SoundPlayer(Object app) {
    minimplay = new Minim(app); 
    boomPlayer = minimplay.loadSample("OOT_Arrow_Hit_Ice.wav", 1024); 
    popPlayer = minimplay.loadSample("pop.wav", 1024);
    backgroundMusic = minimplay.loadFile("bg.mp3", 1024);
    boomMonster = minimplay.loadSample("hitmarker.wav", 1024);
    shootSnow = minimplay.loadSample("shoot.wav", 1024);
  }

  void playExplosion() {
    boomPlayer.trigger();
  }

  void playPop() {
    popPlayer.trigger();
  }
  
  void playBG(){
    backgroundMusic.rewind();
    backgroundMusic.play();
  }
  
  void boomMonster(){
    boomMonster.trigger();
  }
  
  void shootSnow(){
    shootSnow.trigger();
  }

  boolean isBGPlaying(){
    return backgroundMusic.isPlaying();
  }
}