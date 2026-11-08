
import processing.serial.*;
import processing.sound.*;
import java.util.*;

Serial port;
SoundFile song;

final float BPM = 170;
final float BEAT = 60.0 / BPM;
final float OFFSET = 2.0;  // Adjust to match the first charted beat
final float DURATION = 60.0;

final float PERFECT = 0.08;
final float GOOD = 0.15;
final float HIT_Y = 480;
final float SPEED = 180;  // Pixels per second

ArrayList<Note> notes = new ArrayList<Note>();
ArrayList<Entry> leaderboard = new ArrayList<Entry>();

String teamName = "";
String feedback = "";
int[] scores = new int[2];
int[] totals = new int[2];

int state = 0;  // 0 = start, 1 = playing, 2 = results

class Note {
  int player, button;
  float time;
  int points = -1; // -1 pending, 0 miss, 50 good, 100 perfect

  Note(int p, int b, float t) {
    player = p;
    button = b;
    time = t;
  }
}

class Entry {
  String name;
  float score;

  Entry(String n, float s) {
    name = n;
    score = s;
  }
}

void setup() {
  size(800, 600);
  textAlign(CENTER, CENTER);

  println(Serial.list());
  port = new Serial(this, Serial.list()[4], 115200);
  // Change [0] to the index of your ESP32's USB port.

  song = new SoundFile(this, "what_is_love.wav");

  loadLeaderboard();
  makeChart();
}

// Simple quarter-note chart, with equal notes per player.
// Replace these patterns to match the song.
void makeChart() {
  notes.clear();

  for (int beat = 0; beat < 164; beat++) {
    int player = beat % 2;
    int button = (beat / 2) % 2;
    float time = OFFSET + beat * BEAT;

    if (time < DURATION) {
      notes.add(new Note(player, button, time));
    }
  }
}

void draw() {
  background(20, 20, 35);

  if (state == 0) {
    fill(255);
    textSize(44);
    text("SYNCOPALS", width/2, 100);

    textSize(20);
    text("Enter your team name:", width/2, 210);
    text(teamName + "_", width/2, 260);
    text("Press ENTER to start", width/2, 330);

    drawLeaderboard(400);
  }

  if (state == 1) {
    readButtons();

    float t = song.position();

    // Mark notes that were not pressed
    for (Note n : notes) {
      if (n.points == -1 && t > n.time + GOOD) {
        n.points = 0;
      }
    }

    drawGame(t);

    if (t >= DURATION + GOOD) {
      finishGame();
    }
  }

  if (state == 2) {
    fill(255);
    textSize(36);
    text("SONG COMPLETE!", width/2, 75);

    textSize(24);
    text("Team: " + teamName, width/2, 145);
    text("Team accuracy: " + nf(teamAccuracy(), 0, 1) + "%",
         width/2, 190);

    textSize(18);
    for (int p = 0; p < 2; p++) {
      float acc = totals[p] == 0 ? 0 :
                  100.0 * scores[p] / (100 * totals[p]);
      text("Player " + (p+1) + ": " + nf(acc, 0, 1) + "%",
           width/2, 235 + p*30);
    }

    drawLeaderboard(325);
    text("Press R to play again", width/2, 565);
  }
}

void drawGame(float t) {
  fill(255);
  textSize(20);
  text("Team: " + teamName, width/2, 28);
  text("Accuracy: " + nf(teamAccuracy(), 0, 1) + "%",
       width/2, 55);

  // Two players, two columns per player
  for (int p = 0; p < 2; p++) {
    for (int b = 0; b < 2; b++) {
      int x = laneX(p, b);

      fill(p == 0 ? color(75, 45, 80) : color(35, 65, 90));
      rect(x - 45, 100, 90, 420, 8);

      fill(255);
      textSize(16);
      text("P" + (p+1) + (b == 0 ? " A" : " B"), x, 535);
    }
  }

  // Hit line
  stroke(255);
  strokeWeight(3);
  line(100, HIT_Y, 700, HIT_Y);
  noStroke();

  // Falling notes
  for (Note n : notes) {
    if (n.points != -1) continue;

    float y = HIT_Y - (n.time - t) * SPEED;

    if (y < 90 || y > 520) continue;

    fill(n.player == 0 ? color(255, 120, 180)
                       : color(100, 190, 255));
    rect(laneX(n.player, n.button)-35, y-13, 70, 26, 6);
  }

  fill(255);
  textSize(24);
  text(feedback, width/2, 570);
}

int laneX(int player, int button) {
  return 200 + player*300 + button*100;
}

void readButtons() {
  while (port.available() > 0) {
    String line = port.readStringUntil('\n');
    if (line == null) break;

    String[] parts = split(trim(line), ',');
    if (parts.length != 2) continue;

    int player = parseInt(parts[0]);
    int button = parseInt(parts[1]);

    if (player >= 0 && player < 2 && button >= 0 && button < 2) {
      judge(player, button, song.position());
    }
  }
}

void judge(int player, int button, float time) {
  Note closest = null;
  float best = GOOD + 0.001;

  for (Note n : notes) {
    if (n.points != -1 || n.player != player || n.button != button)
      continue;

    float diff = abs(n.time - time);
    if (diff <= GOOD && diff < best) {
      closest = n;
      best = diff;
    }
  }

  if (closest == null) return;

  if (best <= PERFECT) {
    closest.points = 100;
    feedback = "PERFECT!";
  } else {
    closest.points = 50;
    feedback = "GOOD!";
  }

  scores[player] += closest.points;
}

float teamAccuracy() {
  int total = totals[0] + totals[1];
  if (total == 0) return 0;
  return 100.0 * (scores[0] + scores[1]) / (100 * total);
}

void startGame() {
  scores = new int[2];
  totals = new int[2];
  feedback = "";

  makeChart();

  for (Note n : notes) {
    totals[n.player]++;
  }

  port.clear();
  song.stop();
  state = 1;
  song.play();
}

void finishGame() {
  // Ensure all remaining notes are counted as misses
  for (Note n : notes) {
    if (n.points == -1) n.points = 0;
  }

  song.stop();
  saveScore();
  state = 2;
}

void keyPressed() {
  if (state == 0) {
    if (key == ENTER || key == RETURN) {
      if (teamName.trim().length() > 0) startGame();
    } else if (key == BACKSPACE) {
      if (teamName.length() > 0)
        teamName = teamName.substring(0, teamName.length()-1);
    } else if (key >= 32 && key <= 126 && teamName.length() < 20) {
      if (key != '|') teamName += key;
    }
  } else if (state == 2 && (key == 'r' || key == 'R')) {
    state = 0;
    teamName = "";
  }
}

// LEADERBOARD

void loadLeaderboard() {
  String[] lines = loadStrings(sketchPath("leaderboard.txt"));
  if (lines == null) return;

  for (String line : lines) {
    String[] parts = split(line, '|');
    if (parts.length == 2) {
      leaderboard.add(new Entry(parts[0], float(parts[1])));
    }
  }
  sortLeaderboard();
}

void sortLeaderboard() {
  Collections.sort(leaderboard, (a, b) ->
    Float.compare(b.score, a.score));

  while (leaderboard.size() > 5) {
    leaderboard.remove(leaderboard.size()-1);
  }
}

void saveScore() {
  float accuracy = teamAccuracy();

  // Keep only the best attempt for each team
  boolean found = false;

  for (Entry e : leaderboard) {
    if (e.name.equalsIgnoreCase(teamName)) {
      e.score = max(e.score, accuracy);
      found = true;
      break;
    }
  }

  if (!found) leaderboard.add(new Entry(teamName, accuracy));

  sortLeaderboard();

  String[] lines = new String[leaderboard.size()];
  for (int i = 0; i < leaderboard.size(); i++) {
    Entry e = leaderboard.get(i);
    lines[i] = e.name + "|" + e.score;
  }

  saveStrings(sketchPath("leaderboard.txt"), lines);
}

void drawLeaderboard(int y) {
  fill(255);
  textSize(22);
  text("TOP 5 TEAMS", width/2, y);

  textSize(16);
  for (int i = 0; i < leaderboard.size(); i++) {
    Entry e = leaderboard.get(i);
    text((i+1) + ". " + e.name + "  —  " +
         nf(e.score, 0, 1) + "%",
         width/2, y + 35 + i*27);
  }
}
