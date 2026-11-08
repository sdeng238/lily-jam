
#include <WiFi.h>
#include <esp_now.h>

#define TEAM_ID 1
#define PLAYER_ID 0       // Change to 1 on the second ESP32
#define BUTTON_A 0
#define BUTTON_B 35

uint8_t broadcastAddress[] = {255, 255, 255, 255, 255, 255};

typedef struct {
  uint8_t teamId;
  uint8_t playerId;
  uint8_t buttonId;
} Message;

QueueHandle_t receivedEvents;

void onReceive(const esp_now_recv_info_t *info,
               const uint8_t *data, int len) {
  if (len != sizeof(Message)) return;

  Message msg;
  memcpy(&msg, data, sizeof(msg));

  if (msg.teamId != TEAM_ID || msg.playerId == PLAYER_ID) return;

  // Save incoming events for loop() to process
  xQueueSend(receivedEvents, &msg, 0);
}

void sendButton(int button) {
  Message msg = {TEAM_ID, PLAYER_ID, (uint8_t)button};

  // Report our own press to Processing
  Serial.printf("%d,%d\n", PLAYER_ID, button);

  // Broadcast to the other ESP32
  esp_now_send(broadcastAddress, (uint8_t *)&msg, sizeof(msg));
}

bool lastA = HIGH, lastB = HIGH;
unsigned long lastAAt = 0, lastBAt = 0;

void checkButton(int pin, int button, bool &last,
                 unsigned long &lastAt) {
  bool now = digitalRead(pin);

  if (last == HIGH && now == LOW && millis() - lastAt > 25) {
    lastAt = millis();
    sendButton(button);
  }

  last = now;
}

void setup() {
  Serial.begin(115200);

  pinMode(BUTTON_A, INPUT_PULLUP);
  pinMode(BUTTON_B, INPUT);  // External pull-up on this T-Display

  lastA = digitalRead(BUTTON_A);
  lastB = digitalRead(BUTTON_B);

  receivedEvents = xQueueCreate(20, sizeof(Message));

  WiFi.mode(WIFI_STA);
  if (esp_now_init() != ESP_OK) {
    Serial.println("ESP-NOW failed");
    while (true) delay(1000);
  }

  esp_now_register_recv_cb(onReceive);

  esp_now_peer_info_t peer = {};
  memcpy(peer.peer_addr, broadcastAddress, 6);
  peer.channel = 0;
  peer.encrypt = false;
  esp_now_add_peer(&peer);
}

void loop() {
  checkButton(BUTTON_A, 0, lastA, lastAAt);
  checkButton(BUTTON_B, 1, lastB, lastBAt);

  // Forward remote button presses to Processing
  Message msg;
  while (xQueueReceive(receivedEvents, &msg, 0) == pdTRUE) {
    Serial.printf("%d,%d\n", msg.playerId, msg.buttonId);
  }
}
