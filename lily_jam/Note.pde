class Note {
  int player;
  int button;
  int points = -1;
  int hitAt = 0;
  float time;
  
  // class for each playable note
  Note(int p, int b, float t) {
    
    player = p;
    button = b;
    time = t;
    
  }
}
