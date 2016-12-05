// Group 1 
// Ishaan Arya, Matthew Tegegne, Kenneth Poh, Vrushali Asar, Derek Flint
// CS 1200.501 F16
// Project Phase 4

import sprites.utils.*;
import sprites.maths.*;
import sprites.*;

// Game Configuration Variables
int monsterCols = 3,
    monsterRows = 2,
    mmStep = 1;
long mmCounter = 0;

// Game Operational Variables
Sprite ship,
       rocket,
       monsters[][] = new Sprite[monsterCols][monsterRows],
       flyingMonster,
       explosion,
       gameOverSprite;
double fmRightAngle = 0.3490, //20 degrees
       fmLeftAngle = 2.79253, //160 degrees
       fmSpeed = 0,
       upRadians = 4.71238898,
       rocketSpeed = 1000,
       shipSpeed = 15;
int score = 0,
    difficulty = 21,
    minDifficulty = 3;
PImage background;
PFont font;

KeyboardController kbController = new KeyboardController(this);
StopWatch stopWatch = new StopWatch();
SoundPlayer soundPlayer;

void setup() 
{
  registerMethod("pre", this);
  size(700, 500);
  frameRate(50);
  buildSprites();
  resetMonsters();
  soundPlayer = new SoundPlayer(this);
  background = loadImage("bg.jpg");
}

void buildSprites() 
{
  // The Ship
  ship = buildShip();

  // The Rocket
  rocket = buildRocket();

  // The Grid Monsters
  buildMonsterGrid();
  
  // Game Over Sprite
  gameOverSprite = new Sprite(this, "gameover.png", 100);
  gameOverSprite.setDead(true);
}

Sprite buildShip() 
{
  Sprite ship = new Sprite(this, "ship.png", 50);
  ship.setXY(width/2, height-30);
  ship.setVelXY(0.0f, 0);
  ship.setScale(.75);
  // Domain keeps the moving sprite within specific screen area  
  ship.setDomain(0, height - ship.getHeight(), width, height, Sprite.HALT);
  return ship;
}

Sprite buildRocket() 
{
  Sprite rocket = new Sprite(this, "snowy.png", 50);
  rocket.setXY(width/2, height-30);
  rocket.setVelXY(0.0f, 0);
  rocket.setScale(.75);
  rocket.setDead(true);
  // Domain keeps the moving sprite within specific screen area  
  //rocket.setDomain(0, height - ship.getHeight(), width, height, Sprite.HALT);
  return rocket;
}

// Populate the monsters grid 
void buildMonsterGrid() 
{
  for (int idx = 0; idx < monsterCols; ++idx ) {
    for (int idy = 0; idy < monsterRows; ++idy ) {
      Sprite newMonster = buildMonster();
      monsters[idx][idy] = newMonster;
    }
  }
}

// Build individual monster
Sprite buildMonster() 
{
  Sprite monster = new Sprite(this, "monster.png", 30);
  monster.setScale(.5);
  monster.setDead(false);
  // Ship Explosion Sprite
  explosion = new Sprite(this, "explosion_strip16.png", 17, 1, 90);
  explosion.setScale(1);
  return monster;
}

// Reset the monster grid along with the inital monster's 
// positions and direction of movement.
void resetMonsters() 
{
  for (int idx = 0; idx < monsterCols; ++idx ) {
    for (int idy = 0; idy < monsterRows; ++idy ) {
      // Move Monsters back to first positions
      Sprite monster = monsters[idx][idy];
      double mwidth = monster.getWidth() + 20;
      double totalWidth = mwidth * monsterCols;
      double start = (width - totalWidth)/2 - 25;
      double mheight = monster.getHeight();  
      monster.setXY((idx*mwidth)+start, (idy*mheight)+50);
      monster.setSpeed(0);
      // Re-enable monsters that were previously marked dead.
      monster.setDead(false);
    }
  }
  mmCounter = 0;
  mmStep = 1;// + 1 * (21 - difficulty);
}
       
void fireRocket()  
{
  if (rocket.isDead() && !ship.isDead())
  {
    rocket.setPos(ship.getPos());
    rocket.setSpeed(rocketSpeed, upRadians);
    rocket.setDead(false);
    soundPlayer.shootSnow();
  }
}

void stopRocket()
{
  rocket.setSpeed(0, upRadians);
  rocket.setDead(true);
}

void checkKeys() 
{
  if (focused) { // Is game window in focus?
    if (kbController.isLeft()) {
    ship.setX(ship.getX()-shipSpeed);
    }
    if (kbController.isRight()) {
    ship.setX(ship.getX()+shipSpeed);
    }
    if (kbController.isSpace()) {
    // fireRocket is implemented in Phase 2
    fireRocket();
  }
  }
}

// Executed before draw() is called 
public void pre() 
{
  checkKeys();
  // Check Stop Rocket Here in Phase 2
  // If rocket flies off screen
  //screem?
  if (!rocket.isDead() && !rocket.isOnScreem()){
    stopRocket();
  }
  processCollisions();
  moveMonsters();
  S4P.updateSprites(stopWatch.getElapsedTime());

  if (pickNonDeadMonster() == null) {
    // Increase difficulty
    difficulty -= difficulty > minDifficulty ? 2 : 0;
    resetMonsters();
  }
    
  //Add new flying monster if non exist
  if (flyingMonster == null) {
    flyingMonster = pickNonDeadMonster();
    if (flyingMonster == null) {
      resetMonsters();
      flyingMonster = pickNonDeadMonster();
    }
    double direction = (int(random(2)) == 1) ? fmRightAngle : fmLeftAngle;

    //custom flying monster speed scaling based on difficulty
    fmSpeed = 150 + 12 * (21 - difficulty);
    flyingMonster.setSpeed(fmSpeed, direction);
     
    // Domain keeps the moving sprite withing specific screen area
    flyingMonster.setDomain(0, 0, width, height+100, Sprite.REBOUND);
  }
  
     // If flying monster is off screen
  if (flyingMonster != null && !flyingMonster.isOnScreem()) {
    flyingMonster.setDead(true);
    flyingMonster = null;
  }

  if (!soundPlayer.isBGPlaying()){
    soundPlayer.playBG();
  }
}

// Detect collisions between game pieces
void processCollisions() 
{
  for (int idx = 0; idx < monsterCols; ++idx ) {
    for (int idy = 0; idy < monsterRows; ++idy ) {
      Sprite monster = monsters[idx][idy];
      if (!monster.isDead() && !rocket.isDead() && rocket.bb_collision(monster))
      {
        monster.setDead(true);
        rocket.setDead(true);
        score = score + 10;
        soundPlayer.boomMonster();
      }
    }
  }
  if (flyingMonster != null && flyingMonster.isDead() && rocket.bb_collision(flyingMonster))
  {
   flyingMonster = null; 
   soundPlayer.boomMonster();
   score = score + 10;
  }

  boolean gameOver = false;
  // Between Flying Monster and Ship
  if (flyingMonster != null && !ship.isDead()
                    && flyingMonster.bb_collision(ship)) {
    explodeShip();
    monsterHit(flyingMonster);
    flyingMonster = null;
    gameOver = true;
    //Called GameOver fucntion here
    drawGameOver();
  } 
}

void explodeShip()
{
  ship.setDead(true);
  soundPlayer.playExplosion();
  explosion.setPos(ship.getPos());
  explosion.setFrameSequence(0, 16, 0.1, 1);
  ship.setDead(true);
}

void monsterHit(Sprite flyingMonster)
{
  flyingMonster.setDead(true);
}

// Return null if they are all dead.
Sprite pickNonDeadMonster()
{
  for (int idy = monsterRows; idy > 0; idy-- ) {
    for (int idx = monsterCols; idx > 0; idx-- ) {
      Sprite monster = monsters[idx-1][idy-1];
      if (!monster.isDead()) {
        return monster;
      }
    }
  }
  return null;
}

void moveMonsters() 
{
  // Reverse the direction of the monster grid movement
  mmStep *= (++mmCounter % 100 == 0) ? -1 : 1;
   
  // Move Grid Monsters
  for (int idx = 0; idx < monsterCols; ++idx ) {
    for (int idy = 0; idy < monsterRows; ++idy ) {
      Sprite monster = monsters[idx][idy];
      if (!monster.isDead() && monster != flyingMonster) {
        monster.setXY(monster.getX()+mmStep, monster.getY());
      }
   }
  }
  
  // Move Flying Monster
  if (flyingMonster != null) {
    if (int(random(difficulty)) == 0) {
      // Change FM Speed
      double newSpeed = flyingMonster.getSpeed() + random(-20,40);
      flyingMonster.setSpeed(newSpeed);
      // Reverse FM direction.
      if(flyingMonster.getDirection() == fmRightAngle)  
        flyingMonster.setDirection(fmLeftAngle);
      else
        flyingMonster.setDirection(fmRightAngle);
    }
  }
}

void drawScore()  
{
  font = loadFont("kristen.vlw");
  textSize(32);
  textFont(font);
  String msg = " Score: " + score;
  text(msg, 10, 40);
}

void drawGameOver()  
{
  gameOverSprite.setXY(width/2, height/2);
  gameOverSprite.setDead(false);
}

public void draw() 
{
  background(background);
  S4P.drawSprites();
  drawScore();
}