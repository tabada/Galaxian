// Group 1 
// Ishaan Arya, Matthew Tegegne, Kenneth Poh, Vrushali Asar, Derek Flint
// CS 1200.501 F16
// Project Phase 1

/*
*/
import sprites.utils.*;
import sprites.maths.*;
import sprites.*;

// Game Configuration Varaibles
int monsterCols = 10;
int monsterRows = 5;
long mmCounter = 0;
int mmStep = 1;

// Game Operational Variables
Sprite ship;
Sprite rocket;
Sprite monsters[][] = new Sprite[monsterCols][monsterRows];

KeyboardController kbController = new KeyboardController(this);
StopWatch stopWatch = new StopWatch();

void setup() 
{
  registerMethod("pre", this);
  size(700, 500);
  frameRate(50);
  buildSprites();
  resetMonsters();
}

void buildSprites()
{
  // The Ship
  ship = buildShip();

  // The Rocket
  rocket = buildRocket();

  // The Grid Monsters 
  buildMonsterGrid();
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
  // Implemented in phase 2
  
  return rocket;
}

// Populate the monsters grid 
void buildMonsterGrid() 
{
  for (int idx = 0; idx < monsterCols; idx++ ) {
    for (int idy = 0; idy < monsterRows; idy++ ) {
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

  return monster;
}

// Reset the monster grid along with the inital monster's 
// positions and direction of movement.
void resetMonsters() 
{
  for (int idx = 0; idx < monsterCols; idx++ ) {
    for (int idy = 0; idy < monsterRows; idy++ ) {
      // Move Monsters back to first positions
      Sprite monster = monsters[idx][idy];
      double mwidth = monster.getWidth() + 20;
      double totalWidth = mwidth * monsterCols;
      double start = (width - totalWidth)/2 - 25;
      double mheight = monster.getHeight();  
      monster.setXY((idx*mwidth)+start, (idy*mheight)+50);
      
      // Re-enable monsters that were previously marked dead.
      monster.setDead(false);
    }
  }
  mmCounter = 0;
  mmStep = 1;
}

// Executed before draw() is called 
public void pre() 
{
  checkKeys();
  // Check Stop Rocket Here in Phase 2
  //processCollisions();
  moveMonsters();
  S4P.updateSprites(stopWatch.getElapsedTime());
} 

void checkKeys() 
{
  if (focused) { // Is game window in focus?
    if (kbController.isLeft()) {
    ship.setX(ship.getX()-10);
    }
    if (kbController.isRight()) {
    ship.setX(ship.getX()+10);
    }
    if (kbController.isSpace()) {
    // fireRocket is implemented in Phase 2
    //fireRocket();
  }
  }
}

// Detect collisions between game pieces
/*void processCollisions() 
{
  // Implemented in Phase 2
}*/

void moveMonsters() 
{
  // Reverse the direction of the monster grid movement
  if ((++mmCounter % 100) == 0) mmStep *= - 1;
   
  // Move Grid Monsters
  for (int idx = 0; idx < monsterCols; idx++ ) {
  for (int idy = 0; idy < monsterRows; idy++ ) {
    Sprite monster = monsters[idx][idy];
    if (!monster.isDead()) {
      monster.setXY(monster.getX()+mmStep, monster.getY());
    }
  }
}
}

public void draw() 
{
  background(0);
  S4P.drawSprites();
}