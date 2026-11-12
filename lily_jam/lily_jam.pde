
import processing.serial.*;
import processing.sound.*;
import java.util.*;
import java.io.File;

// main text: dark brown = 89, 61, 53
// p1: green = 40, 104, 62
// p2: red = 181, 47, 65

Serial port;
SoundFile song;

float BPM = 170, BEAT = 60.0 / BPM;
float OFFSET = 2.9, DURATION = 60;
float HIT_Y = 480, SPEED = 180;
float PERFECT = 0.08, GOOD = 0.15;
int finalRank = -1;

ArrayList<Note> notes = new ArrayList<Note>();
ArrayList<Entry> board = new ArrayList<Entry>();

PImage[] avatars = new PImage[2];

String[] names = {"", ""};
String[] feedback = {"", ""};
int[] feedbackAt = {0, 0};
int state = 0;
int nameIndex = 0;
int score = 0
int perfects = 0;
int goods = 0;
int misses = 0;


void setup() {
  size(800, 600);
  pixelDensity(displayDensity());
  textAlign(CENTER, CENTER);
  
  PFont pixelated;
  pixelated = createFont("PixelPurl.ttf", 128);
  textFont(pixelated);
  
  printArray(Serial.list());
  port = new Serial(this, Serial.list()[4], 115200);
  
  song = new SoundFile(this, "what_is_love.mp3");
  
  avatars[0] = loadImage("lily.png");
  avatars[1] = loadImage("jam.png");
  noSmooth();
  
  loadBoard();
}


void makeChart() {
  notes.clear();
  int[] counts = {0, 0};

  for (float t = OFFSET; t < DURATION; t += BEAT) {
    // randomize mapping of notes
    int p = counts[0] == counts[1] ? int(random(2)) :
            (counts[0] < counts[1] ? 0 : 1);

    int b = int(random(2));

    notes.add(new Note(p, b, t));
    counts[p]++;
  }
}

void draw() {
  background(246, 229, 206);
  fill(88, 60, 51);

  // display main menu (start screen)
  if (state == 0) {
    fill(89, 61, 53);
    textSize(52);
    text("lily jam", 400, 90);
  
    image(avatars[0], 250, 150, 100, 100);
    image(avatars[1], 450, 150, 100, 100);
  
    textSize(28);
    fill(40, 104, 62);
    text("Player 0: " + names[0] + (nameIndex == 0 ? "_" : ""), 300, 290);
  
    fill(181, 47, 65);
    text("Player 1: " + names[1] + (nameIndex == 1 ? "_" : ""), 500, 290);
  
    fill(89, 61, 53);
    text("Press ENTER to continue", 400, 360);
  
    drawBoard(430);
    return;
  }

  // game over screen
  if (state == 2) {
    textSize(50);
    text("SONG COMPLETE!", 400, 55);
  
    textSize(24);
    fill(40, 104, 62);
    text(names[0] + " + " + names[1], 400, 105);
  
    textSize(30);
    text("Final score: " + score, 400, 155);
  
    textSize(24);
    fill(181, 47, 65);
    text("Perfect: " + perfects + "   Good: " + goods +
         "   Miss: " + misses, 400, 230);
  
    textSize(30);
    fill(89, 61, 53);
    if (finalRank > 0)
      text("Leaderboard Rank #" + finalRank, 400, 275);
    else
      text("Not in Top 5", 400, 275);
  
    drawBoard(350);
  
    textSize(30);
    text("Press R to restart", 400, 555);
    return;
  }


  float t = song.position();
  readButtons();

  textSize(44);
  text(score, 400, 35);

  // draw lanes
  for (int p = 0; p < 2; p++) {
    int center = 250 + p * 300;
    fill(p == 0 ? color(40, 104, 62) : color(181, 47, 65));
    textSize(22);
    image(avatars[p], center - 55, 65, 45, 45);
    text(names[p], center + 15, 90);

    for (int b = 0; b < 2; b++) {
      int x = 200 + p * 300 + b * 100;
      fill(p == 0 ? color(200, 230, 186) : color(247, 199, 191));
      rect(x - 45, 120, 90, 400, 8);
      fill(p == 0 ? color(168, 201, 160) : color(230, 161, 154));
      text(b == 0 ? "left" : "right", x, 535);
    }

    if (millis() - feedbackAt[p] < 500) {
      fill(89, 61, 53);
      text(feedback[p], center, 570);
    }
  }

  stroke(255);
  strokeWeight(3);
  line(100, HIT_Y, 700, HIT_Y);
  noStroke();

  // draw and score notes
  for (Note n : notes) {
    float y = HIT_Y - (n.time - t) * SPEED;
    int x = 200 + n.player * 300 + n.button * 100;

    if (n.points == -1 && t > n.time + GOOD) {
      n.points = 0;
      misses++;
      showFeedback(n.player, "MISS!");
    }

    if (n.points == -1 && y >= 120 && y <= 520) {
      fill(n.player == 0 ? color(85, 173, 101) : color(233, 75, 85));
      rect(x - 35, y - 13, 70, 26, 6);
    }
    else if (n.points > 0 && millis() - n.hitAt < 200) {
      fill(n.points == 100 ? color(255) :
           n.player == 0 ? color(255, 200, 225) : color(209, 245, 229));
      rect(x - 35, y - 13, 70, 26, 6);
    }
  }

  // game ends when song ends
  if (t >= DURATION + GOOD || !song.isPlaying()) {
    song.stop();
    saveScore();
    state = 2;
  }
}

void showFeedback(int p, String message) {
  feedback[p] = message;
  feedbackAt[p] = millis();
}

void readButtons() {
  while (port.available() > 0) {
    String line = port.readStringUntil('\n');
    if (line == null) break;
    String[] parts = split(trim(line), ',');

    if (parts.length != 2) continue;
    int p = int(parts[0]), b = int(parts[1]);
    if (p < 0 || p > 1 || b < 0 || b > 1) continue;

    Note closest = null;
    float best = GOOD;

    for (Note n : notes) {
      float diff = abs(n.time - song.position());
      if (n.player == p && n.button == b &&
          n.points == -1 && diff <= best) {
        closest = n;
        best = diff;
      }
    }

    if (closest != null) {
      closest.points = best <= PERFECT ? 100 : 50;
      closest.hitAt = millis();
      score += closest.points;

      if (closest.points == 100) {
        perfects++;
        showFeedback(p, "PERFECT!");
      } else {
        goods++;
        showFeedback(p, "GOOD!");
      }
    }
  }
}

float accuracy() {
  return notes.size() == 0 ? 0 : 100.0 * score / (100 * notes.size());
}

void keyPressed() {
  if (state == 2 && (key == 'r' || key == 'R')) {
    state = 0;
    nameIndex = 0;
    names = new String[]{"", ""};
  } 
  else if (state == 0) {
    if (key == ENTER || key == RETURN) {
      if (trim(names[nameIndex]).isEmpty()) {
        return;
      }
      
      if (nameIndex == 0) {
        nameIndex = 1;
      }
      else {
        score = perfects = goods = misses = 0;
        feedbackAt = new int[]{-10000, -10000};
        makeChart();
        port.clear();
        song.stop();
        song.play();
        state = 1;
      }
    } 
    else if (key == BACKSPACE && names[nameIndex].length() > 0) {
      names[nameIndex] = names[nameIndex].substring(0, names[nameIndex].length()-1);
    } 
    else if (key >= 32 && key <= 126 && key != '|' &&
               names[nameIndex].length() < 16) {
      names[nameIndex] += key;
    }
  }
}


void loadBoard() {
  if (!new File(sketchPath("leaderboard.txt")).exists()) return;
  for (String line : loadStrings("leaderboard.txt")) {
    String[] s = split(line, '|');
    if (s.length == 3)
      board.add(new Entry(s[0], int(s[1]), float(s[2])));
  }
  sortBoard();
}


void sortBoard() {
  board.sort((a, b) -> Float.compare(b.accuracy, a.accuracy));
  
  while (board.size() > 5) {
    board.remove(board.size()-1);
  }
}

void saveScore() {
  String team = names[0] + " + " + names[1];
  boolean found = false;

  for (Entry e : board) {
    if (e.name.equalsIgnoreCase(team)) {
      if (accuracy() > e.accuracy) {
        e.score = score;
        e.accuracy = accuracy();
      }
      
      found = true;
      break;
    }
  }

  if (!found) {
    board.add(new Entry(team, score, accuracy()));
  }

  sortBoard();

  // get team ranking
  finalRank = -1;
  for (int i = 0; i < board.size(); i++) {
    if (board.get(i).name.equalsIgnoreCase(team)) {
      finalRank = i + 1;
      break;
    }
  }

  String[] lines = new String[board.size()];
  for (int i = 0; i < board.size(); i++) {
    Entry e = board.get(i);
    lines[i] = e.name + "|" + e.score + "|" + e.accuracy;
  }
  
  saveStrings(sketchPath("leaderboard.txt"), lines);
  
}


void drawBoard(int y) {
  fill(89, 61, 53);
  textSize(26);
  text("TOP 5 TEAMS", 400, y);

  textSize(20);
  
  for (int i = 0; i < board.size(); i++) {
    Entry e = board.get(i);
    String team = names[0] + " + " + names[1];

    if (state == 2 && e.name.equalsIgnoreCase(team)) {
      // diff color for current team
      fill(181, 47, 65);
    }
    else {
      fill(89, 61, 53);
    }

    text((i+1) + ". " + e.name + ": " + e.score + " pts",
         400, y + 35 + i*27);
  }
}
