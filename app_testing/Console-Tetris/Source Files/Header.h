#pragma once
#include <iostream>
#include <windows.h>
#include <chrono>
#include <tchar.h>
#include <vector>
#include <random>
using namespace std;
using namespace chrono;

static random_device generator;
static uniform_int_distribution<int> distribution(0, 6);

static bool EXIT_GAME_F = false;
static bool EXIT_PROGRAM_F = false;

/* Debug Options */
static bool ForceSpriteTest = false;

typedef unsigned char byteint; // Integer with range of one byte

const HDC console = GetDC(GetConsoleWindow()); // Handle for device context specifically targeted at the console window.
const HDC hdc = CreateCompatibleDC(NULL); // Handle for device context for bitmap
const HBITMAP bmap = (HBITMAP)LoadImage(NULL, _T("ConsoleTetrisSpriteSheet.bmp"), IMAGE_BITMAP, 0, 0, LR_LOADFROMFILE); // Bitmap image data

enum GameState {BEFORE, DURING, LIMBO, AFTER};
enum Direction {UP, DOWN, LEFT, RIGHT, NONE, RL, RR, ENTER};
enum BlockType {bO = 0, bI = 1, bT = 2, bL = 3, bJ = 4, bS = 5, bZ = 6, bX = 7};

const int BH = 20, BW = 10, WH = 25, WW = 17; // Dimension Variables (Board and Window)
const int GSS = 32; // Global Sprite Size

bool KeyIsDown(char key, bool pressed, bool held); // Returns true if passed key is pressed or held
double GetTime(); // Returns UNIX time
double GetTimeSince(double startTime); // Returns time since given UNIX time
double Wait(double waitTime); // Pauses program for passed value of time
void ShowConsoleCursor(bool showFlag); // Hides or reveals cursor
void SetWindowDimensions(int x, int y); // Sets size of window
