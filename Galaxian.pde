// Group 1 
// Ishaan Arya, Matthew Tegegne, Kenneth Poh, Vrushali Asar, Derek Flint
// CS 1200.501 F16
// Project Phase 4

import sprites.utils.*;
import sprites.maths.*;
import sprites.*;
import processing.net.*;
import java.net.Socket;

// Game Networking Objects
Server server;
Client client;

// Game Configuration Variables
int monsterCols = 10, 
  monsterRows = 5, 
  mmStep = 1;
long mmCounter = 0;

// Game Operational Variables
Sprite ship, 
  rocket, 
  enemyRocket, 
  monsters[][] = new Sprite[monsterCols][monsterRows], 
  flyingMonster, 
  explosion, 
  gameOverSprite, 
  winSprite;
double fmRightAngle = 0.3490, //20 degrees
  fmLeftAngle = 2.79253, //160 degrees
  fmSpeed = 0, 
  upRadians = 4.71238898, 
  downRadians = 1.57079632, 
  rocketSpeed = 1000, 
  shipSpeed = 15;
int score = 0, 
  difficulty = 21, 
  minDifficulty = 3;
boolean gameOver = false, 
  rightBias = false, 
  isServer;
PImage background;
PFont font;

KeyboardController kbController = new KeyboardController(this);
StopWatch stopWatch = new StopWatch();
SoundPlayer soundPlayer;

void buildSprites() 
{
  // The Ship
  ship = buildShip();

  // The Rocket
  rocket = buildRocket();

  // Opposing Player's Rocket
  enemyRocket = buildEnemyRocket();

  // The Grid Monsters
  buildMonsterGrid();

  // Game Over Sprite
  gameOverSprite = new Sprite(this, "gameover.png", 100);
  gameOverSprite.setDead(true);

  // You Win Sprite
  winSprite = new Sprite(this, "youwin.png", 100);
  winSprite.setDead(true);
}

Sprite buildShip() 
{
  //Sprite ship = new Sprite(this, "ship.png", 50);
  Sprite ship = new Sprite(this, "elf.png", 2, 1, 90);
  ship.setFrameSequence(0, 1, 0.5);
  ship.setXY(width/2, height-30);
  ship.setVelXY(0.0f, 0);
  ship.setScale(.75);
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
  return rocket;
}

Sprite buildEnemyRocket() 
{
  Sprite enemyRocket = new Sprite(this, "snowy.png", 50);
  enemyRocket.setXY(width/2, height-30);
  enemyRocket.setVelXY(0.0f, 0);
  enemyRocket.setScale(.75);
  enemyRocket.setDead(true);
  return enemyRocket;
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

void fireEnemyRocket(double xLoc)
{
  enemyRocket.setXY(xLoc, 0.0);
  enemyRocket.setSpeed(rocketSpeed, downRadians);
  enemyRocket.setDead(false);
  soundPlayer.shootSnow();
}

void stopEnemyRocket()
{
  enemyRocket.setSpeed(0, upRadians);
  enemyRocket.setDead(true);
}

//Rockets that reach the top of the screen are sent to the opposing client's screen
//Opposing rockets can hit players but not monsters
//If one player dies, the other wins
void updateServer()
{
  if (server.active()) {
    byte game = (byte) (gameOver ? 1 : 0), 
      enemyRocketPos = -1;
    if (!rocket.isDead() && rocket.getY() < 10) {
      //transcode positional int of value {0...700} to byte of value {-128...127}
      enemyRocketPos = (byte) (rocket.getX() / 700.0 * 256.0);
    }
    //Processing networking can only send byte[], int, & String
    byte writeData[] = {enemyRocketPos, game};
    server.write(writeData);

    client = server.available();
    if (client != null) {
      byte readData[] = client.readBytes();
      //array length check in case of network misshaps, otherwise potential outofbounds
      if (readData.length == 2) {
        if (readData[0] != -1) {
          //signed byte to "unsigned" int using a bitmask
          fireEnemyRocket((0xFF & readData[0]) / 256.0 * 700.0);
        }
        if (readData[1] == 1) {
          drawWin();
        }
      }
    }
  }
}

void updateClient()
{
  if (client.active()) {
    byte game = (byte) (gameOver ? 1 : 0), 
      enemyRocketPos = -1;
    if (!rocket.isDead() && rocket.getY() < 10) {
      //transcode positional int of value {0...700} to byte of value {-128...127}
      enemyRocketPos = (byte) (rocket.getX() / 700.0 * 256.0);
    }
    //Processing networking can only send byte[], int, & String
    byte writeData[] = {enemyRocketPos, game};
    client.write(writeData);

    if (client.available() > 0) {
      byte readData[] = client.readBytes();
      //array length check in case of network misshaps, otherwise potential outofbounds
      if (readData.length == 2) {
        if (readData[0] != -1) {
          //signed byte to "unsigned" int using a bitmask
          fireEnemyRocket((0xFF & readData[0]) / 256.0 * 700.0);
        }
        if (readData[1] == 1) {
          drawWin();
        }
      }
    }
  }
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

// Detect collisions between game pieces
void processCollisions() 
{
  if (winSprite.isDead()) {
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

    // Between Flying Monster and Ship
    if (flyingMonster != null && !ship.isDead()
      && flyingMonster.bb_collision(ship)) {
      explodeShip();
      monsterHit(flyingMonster);
      flyingMonster = null;
      gameOver = true;
      drawGameOver();
    } 

    // Between Enemy Player Rocket and Ship
    if (!enemyRocket.isDead() && !ship.isDead()
      && enemyRocket.bb_collision(ship)) {
      explodeShip();
      enemyRocket.setDead(true);
      gameOver = true;
      drawGameOver();
    }
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
      if (int(random(100)) < 5)
        rightBias = !rightBias;
      // Change FM Speed
      double newSpeed;
      if (rightBias)
        newSpeed = flyingMonster.getSpeed() + random(-35, 40);
      else
        newSpeed = flyingMonster.getSpeed() + random(-40, 35);
      flyingMonster.setSpeed(newSpeed);
      // Reverse FM direction.
      if (flyingMonster.getDirection() == fmRightAngle)  
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

void drawWin()  
{
  winSprite.setXY(width/2, height/2);
  winSprite.setDead(false);
}

public static boolean serverListening(String host, int port)
{
  Socket s = null;
  try {
    s = new Socket(host, port);
    return true;
  }
  catch (Exception e) {
    return false;
  }
  finally {
    if (s != null) {
      try {
        s.close();
      }
      catch(Exception e) {
      }
    }
  }
}

void setup() 
{
  registerMethod("pre", this);
  soundPlayer = new SoundPlayer(this);

  if (serverListening("127.0.0.1", 5204)) {
    isServer = false;
    client = new Client(this, "127.0.0.1", 5204);
  } else {
    isServer = true;
    server = new Server(this, 5204, "127.0.0.1");
  }

  size(700, 500);
  frameRate(50);

  background = loadImage("bg.jpg");

  buildSprites();
  resetMonsters();
}

// Executed before draw() is called 
public void pre() 
{
  checkKeys();
  if (isServer) {
    updateServer();
  } else {
    updateClient();
  }
  //screem?
  if (!rocket.isDead() && !rocket.isOnScreem()) {
    stopRocket();
  }
  if (!enemyRocket.isDead() && !enemyRocket.isOnScreem()) {
    stopEnemyRocket();
  }
  processCollisions();
  moveMonsters();
  S4P.updateSprites(stopWatch.getElapsedTime());

  if (pickNonDeadMonster() == null) {
    // Increase difficulty
    difficulty -= difficulty > minDifficulty ? 2 : 0;
    resetMonsters();
  }

  //Add new flying monster if none exist
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

  if (!soundPlayer.isBGPlaying()) {
    soundPlayer.playBG();
  }
}

public void draw() 
{
  background(background);
  S4P.drawSprites();
  drawScore();
}