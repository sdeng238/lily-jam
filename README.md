# lily jam rhythm game

### Module 3: Distributed Communication
*lily jam* is an interactive hardware project that uses ESP-NOW communication between two ESP32 boards to play a cooperative rhythm game. During the game, two players attempt to earn the highest combined team score by pressing the buttons on their ESP32s as notes reach the hit line in their respective lanes. Depending on their timing accuracy, players earn 100 points for a Perfect hit, 50 for a Good hit, and 0 for a Miss. The game is inspired by Piano Tiles and various K-pop rhythm games -- the current working version features "What is Love?" by TWICE as the backing track! The visual interface is displayed using Processing.

<< insert screen recording of gameplay >>

### Controls:
- Player 0: left two lanes (lily)
- Player 1: right two lanes (jam)
- Left button (GPIO0): hits notes in the player's left lane
- Right button (GPIO35): hits notes in the player's right lane
- Enter (keyboard): starts game from start menu
- R (keyboard): restarts game from end menu

Requirements
---
**Software:**
- Arduino 2.3.10 (may support lower)
  - [ESP32 boards package by Espressif Systems](https://docs.espressif.com/projects/arduino-esp32/en/latest/installing.html)
- TTGO T-Display USB-to-serial driver [(CHXXX)](https://www.wch-ic.com/downloads/CH34XSER_MAC_ZIP.html)
- Processing 4
  - Sound library
  - Serial library

**Hardware:**
- Two LILYGO ESP32 TTGO T-Display boards
- Two USB cables for power and communication

Setup
---
1) ``git clone`` this repo and open ``lily-jam.ino`` in Arduino.
2) Set ``TEAM_ID`` to the same value on both boards and ``PLAYER_ID`` to ``0`` for the first player. Compile and upload ``lily-jam.ino`` to the first ESP32.
3) Change ``PLAYER_ID`` to ``1`` for the second player, keeping ``TEAM_ID`` unchanged. Compile and upload the modified sketch to the second ESP32.
4) Connect one ESP32 to the computer running Processing via USB. Keep the second ESP32 powered on (e.g., through another computer). The boards communicate wirelessly via ESP-NOW, and the first board forwards button inputs to Processing over Serial.
5) Open ``./lily_jam/lily_jam.pde`` in Processing. This is the primary file for our program, with Note.pde and Entry.pde defining the Note and Entry classes.
6) Check the available serial ports printed by ``Serial.list()`` and update the port index in ``lily_jam.pde`` to match the connected ESP32. Make sure Arduino's Serial Monitor is closed.
7) Run the Processing sketch. The game display should pop up in a separate window. Enter both players' names and press Enter to begin!
8) The leaderboard stores each team's best performance, ranked by accuracy percentage, and persists between games.

Showcase
---
https://github.com/user-attachments/assets/dcd78a3b-cf82-4486-80dc-2bb8227a0540
