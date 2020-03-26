#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

#define SCREEN_WIDTH   128
#define SCREEN_HEIGHT   32

#define MAXFIELDS        5
#define MAXFIELDLEN     20
#define BLINK_INTERVAL 250


#define OLED_RESET -1

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

const bool serialEcho = true;
void(* reset) (void) = 0; // Force reboot of arduino

void setup() {
  Serial.begin(115200);
  // put your setup code here, to run once:
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C))
  {
    Serial.println("SSD1306 allocation failed, rebooting...");
    delay(500);
    reset();
  }
  display.display();
  delay(1000);
  Serial.println("Ready: Send initialization.\n");
}

#define STATE_INIT 0
#define STATE_MODE 1
#define STATE_ROW0 2
#define STATE_ROW1 3
#define STATE_ROW2 4
#define STATE_ROW3 5
#define STATE_ROW4 6
#define STATE_CMPL 7
#define STATE_IGNR 8

uint8_t field_map[][6] =
{
  {1,  5,  0,  0,  0,  0},  // Mode 0, 1 row of large text
  {4, 19, 19, 19, 19,  0},  // Mode 1, 4 rows of small text
  {5,  2, 13, 13, 13, 13},  // Mode 2, 1 field of large text, 4 rows of small text
};
#define MAXMODE 2

/*
extern "C"
{
  typedef uint8_t text_field[MAXFIELDLEN+1];
  typedef void (*display_function)(const text_field *);
*/

  char buffer[256];
  
  void displayText(uint8_t x, uint8_t y, uint8_t textSize, bool inverted, const char *text)
  {
    // Display Text in specified font with lower left corner at (x,y)
    memset(buffer, 0, sizeof(buffer));
    snprintf(buffer, sizeof(buffer), "Will display at (%d,%d) size %d %s string: \"%s\"\r\n", x, y, textSize, inverted ? "INVERTED" : "normal", text);
    Serial.print(buffer);
    display.setTextSize(textSize);
    display.setTextColor(inverted ? SSD1306_BLACK, SSD1306_WHITE : SSD1306_WHITE, SSD1306_BLACK);
    display.setCursor(x, y);
    display.print(text);
  }

  void display1 (const char text[MAXFIELDS][MAXFIELDLEN+1])
  {
    // Large 5-character display
    display.clearDisplay();
    displayText( 0,0, 4, 0, text[0]);
    display.display();
  }

  void display2 (const char text[MAXFIELDS][MAXFIELDLEN+1])
  {
    // Small Text, 6x8 font, 4 lines 21 characters per line
    display.clearDisplay();
    displayText( 0, 0, 1, 0, text[0]);
    displayText( 0, 8, 1, 0, text[1]);
    displayText( 0,16, 1, 0, text[2]);
    displayText( 0,24, 1, 0, text[3]);
    display.display();
  }

  void display3 (const char text[MAXFIELDS][MAXFIELDLEN+1])
  {
    // Hybrid 2 Large 24x32 characters, remaining 80x32 is 4 lines 13 characters per line
    display.clearDisplay();
    displayText( 0, 0, 4, 0, text[0]);
    displayText(48, 0, 1, 0, text[1]);
    displayText(48, 8, 1, 0, text[2]);
    displayText(48,16, 1, 0, text[3]);
    displayText(48,24, 1, 0, text[4]);
    display.display();
    delay(5000);
  }

  void (*dispatch[])(const char text[MAXFIELDS][MAXFIELDLEN+1]) = {
    display1, // Mode 0
    display2, // Mode 1
    display3, // Mode 2
    NULL,
  };
/*
}
*/

void loop() {
  char text_buffer[MAXFIELDS][MAXFIELDLEN+1];
  static char dmode = 0;
  static uint8_t state = STATE_INIT;
  int16_t c;
  static uint8_t row = 0;
  static uint8_t column = 0;
  static bool blink_mode;
  static bool inverted;
  static uint32_t last_blink;
  if (blink_mode)
  {
    if (millis() > (last_blink + BLINK_INTERVAL))
    {
      inverted = inverted ? false : true;
      display.invertDisplay(inverted);
      last_blink = millis();
    }
  }
  switch(state)
  {
    case STATE_CMPL:
      (void) dispatch[dmode](text_buffer);
      state = STATE_INIT;
      dmode = 0;
      row = 0;
      Serial.println("Ready: Send initialization.\n");
      break;
    case STATE_ROW4:
    case STATE_ROW3:
    case STATE_ROW2:
    case STATE_ROW1:
    case STATE_ROW0:
      c=Serial.read();
      if (c == -1) break;
      if (c == 0x01)
      {
        row++;
        column = 0;
        Serial.print("\r\n");
        if (row >= field_map[dmode][0]) // That's everything for this mode, show it to the user
        {
          state = STATE_CMPL;
        }
        break;
      }
      if (serialEcho) Serial.write(c);
      if (column < field_map[dmode][row+1])
      {
        text_buffer[row][column++] = c;
        Serial.print("");
      }
      else
      {
        Serial.print("\r\nERROR: Field too long\r\n");
      }
      break;
    case STATE_MODE:
      c=Serial.read();
      if (c == -1) break;
      if (serialEcho)
      {
        Serial.print("\r\nMode: ");
        Serial.print(char(c));
        Serial.print("\r\n");
      }
      if (c == 'b' || c == 'B') // Special Blink mode specification
      {
        blink_mode = true;
        last_blink = millis();
        inverted = true;
        display.invertDisplay(true);
        state = STATE_INIT;
        break;
      }
      if (c > 0x30 && c < 0x3a && (c - 0x31) <= MAXMODE) // Range 1-9 inclusive
      {
        dmode = c - 0x31; // Convert to mode number
        blink_mode = false;   // Reset blink mode
        inverted = false;
        display.invertDisplay(false);
        state++;          // Collect first field data
      }
      else
      {
        Serial.print("\r\nMode of range -- Ignoring until next INIT\r\n");
        state = STATE_IGNR;
      }
      Serial.print("Rows: ");
      Serial.print(field_map[dmode][0]);
      Serial.print(" {");
      Serial.print(field_map[dmode][1]);
      Serial.print(",");
      Serial.print(field_map[dmode][2]);
      Serial.print(",");
      Serial.print(field_map[dmode][3]);
      Serial.print(",");
      Serial.print(field_map[dmode][4]);
      Serial.print(",");
      Serial.print(field_map[dmode][5]);
      Serial.print("}\r\n");
     break;
    case STATE_IGNR:
      c = Serial.peek(); // Look in buffer without pulling
      if (c == -1) break;
      if (c != 0x03)  // If next caharacter in buffer is INIT, we're done ignoring stuff
      {
        c = Serial.read();
        break;
      }
      else
      {
        state = STATE_INIT; // Next character in buffer will cause init
      }
      // No break here -- We set STATE_INIT and want to process accordingly.
    case STATE_INIT:
      c=Serial.read();
      if (c == -1) break;
      if (c == 0x03) // Clear Screen and Initialize buffers command
      {
        memset(text_buffer, 0, sizeof(text_buffer));
        state++; // Wait for a character to tell us which mode to use
        if(serialEcho)
        {
          Serial.print("\r\nBegin... Send Mode (1-");
          Serial.print(char(MAXMODE+0x31));
          Serial.print(" or b)\r\n");
        }
        break;
      }
      else
      {
        Serial.print(".");
      }
  }
}
