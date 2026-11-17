# lily jam rhythm game

### Module 3: Distributed Communication
This is an interactive hardware project that uses ESP-NOW communication between two ESP32 boards to play a cooperative rhythm game. In lily jam, two players attempt to score as many cumulative points as possible by pressing the GPIO buttons on their ESP32s at the correct time in their respective lanes. The game is inspired by Piano Tiles and various K-pop rhythm games -- the current working version features "What is Love" by Twice as the backing track! The visual interface is displayed using Processing.

<< insert screen recording of gameplay >>

### Controls:
- Left button (GPIO0): plays note in left lane
- Right button (GPIO35): plays note in right lane
- Enter (keyboard): starts game from start menu
- R (keyboard): restarts game from end menu

Requirements
---
**Software:**
- Arduino 2.3.10 (may support lower)
  - TFT_eSPI library by Bodmer
  - [ESP 32 library](https://docs.espressif.com/projects/arduino-esp32/en/latest/installing.html)
- TTGO T-Display driver [(CHXXX)](https://www.wch-ic.com/downloads/CH34XSER_MAC_ZIP.html)
- Processing 4

**Hardware:**
- Two LILYGO ESP32 TTGO T-Display boards

Setup
---
1) ``git clone`` this repo and open ``lily-jam.ino`` in Arduino
2) Compile and upload ``lily-jam.ino`` to the first ESP32. This will configure the ESP-NOW communication protocol with the other board, as well as the serial input data for Processing.
3) For the second player, ensure that the ``TEAM_ID`` defined on Line 5 of ``lily-jam.ino`` is the same as the number on the first board. Then, change the ``PLAYER_ID`` on Line 6 to ``1``, so the ID differs from that of the first player.
4) Compile and upload this modified ``lily-jam.ino`` to the second ESP32 board.
5) Open and run ``./lily_jam/lily_jam.pde`` in Processing. This is the primary file for our program, with ``Note.pde`` and ``Entry.pde``as class files for the Note and Entry objects. The game display should pop up in a separate window. You are ready to begin the game!

Live Demo w/ Hardware
---

<< insert video from class showcase >>


