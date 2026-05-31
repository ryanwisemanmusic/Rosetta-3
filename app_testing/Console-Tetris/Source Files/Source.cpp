#include "Game.h"

/* Main */

int main() {
	SetConsoleTitle(_T("Tetris"));
	SetWindowDimensions(WW + 1,WH + 2);
	mciSendString("open \"theme.mp3\" type mpegvideo alias mp3", NULL, 0, NULL);
	mciSendString("play mp3 repeat", NULL, 0, NULL);
	bool tM = true, tS = true; // Passed toggles for music and sound
	do {
		Game* Tetris = new Game(tM,tS);
		EXIT_GAME_F = false;
		while (!EXIT_GAME_F) {
			Tetris->Draw();
			Tetris->Input();
			Tetris->Logic();
			while (GetConsoleWindow() != GetForegroundWindow() && Tetris->State == BEFORE) {}
			while (GetConsoleWindow() != GetForegroundWindow() && Tetris->State == DURING || Tetris->Pause) { 
				Tetris->Input();
				if (Tetris->State == DURING)
					Tetris->DrawPause(); 
			}
			EXIT_PROGRAM_F = Tetris->EXIT_P;
			EXIT_GAME_F = Tetris->EXIT_G;
		}
		tM = Tetris->tMusic; tS = Tetris->tSound;
		delete Tetris;
	} while (!EXIT_PROGRAM_F);
	return 0;
}

/* Non Specific Function definitions */
bool KeyIsDown(char key, bool pressed, bool held) {
	int keyState = GetAsyncKeyState(static_cast<int>(key));
	return (pressed && (keyState & 1)) || (held && (keyState & 0xA000));
}

double GetTime() {
	return time_point_cast<nanoseconds>(high_resolution_clock::now()).time_since_epoch().count() / 1e9;
}

double GetTimeSince(double startTime) {
	return time_point_cast<nanoseconds>(high_resolution_clock::now()).time_since_epoch().count() / 1e9 - startTime;
}

double Wait(double waitTime) {
	double startTime = GetTime();

	while (waitTime > GetTimeSince(startTime)) {}

	return GetTimeSince(startTime + waitTime);
}

void SetWindowDimensions(int x, int y) { // Thanks for this, Sam!
	HWND console = GetConsoleWindow();
	HMONITOR monitor = MonitorFromWindow(console, MONITOR_DEFAULTTOPRIMARY);

	MONITORINFOEX miex;
	miex.cbSize = sizeof(miex);
	GetMonitorInfo(monitor, &miex);
	int cxLogical = (miex.rcMonitor.right - miex.rcMonitor.left);
	int cyLogical = (miex.rcMonitor.bottom - miex.rcMonitor.top);

	DEVMODE dm;
	dm.dmSize = sizeof(dm);
	dm.dmDriverExtra = 0;
	EnumDisplaySettings(miex.szDevice, ENUM_CURRENT_SETTINGS, &dm);
	int cxPhysical = dm.dmPelsWidth;
	int cyPhysical = dm.dmPelsHeight;

	double horzScale = ((double)cxPhysical / (double)cxLogical);
	double vertScale = ((double)cyPhysical / (double)cyLogical);
	SetWindowPos(console, HWND_TOP, 0, 0, x * (double)GSS / horzScale - 11, y * (double)GSS / vertScale  - 14, SWP_NOMOVE);
	HANDLE handle = GetStdHandle(STD_OUTPUT_HANDLE);
	CONSOLE_SCREEN_BUFFER_INFO info;
	GetConsoleScreenBufferInfo(handle, &info);
	COORD new_size = {
		info.srWindow.Right - info.srWindow.Left + 1,
		info.srWindow.Bottom - info.srWindow.Top + 1
	};
	SetConsoleScreenBufferSize(handle, new_size);
	ShowConsoleCursor(false);
}

void ShowConsoleCursor(bool showFlag) {
	HANDLE out = GetStdHandle(STD_OUTPUT_HANDLE);

	CONSOLE_CURSOR_INFO     cursorInfo;

	GetConsoleCursorInfo(out, &cursorInfo);
	cursorInfo.bVisible = showFlag;
	SetConsoleCursorInfo(out, &cursorInfo);
}
