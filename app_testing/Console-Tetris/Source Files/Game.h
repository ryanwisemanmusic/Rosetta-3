#pragma once
#include "Header.h"

class Game {
private:
	const int Sprites[256][2] = {
		//////////////////////////////////////////
		  0, 64, // Background				// 000
		//////////////////////////////////////////
		 32, 64, // Dark Gray Tile			// 001
		 32, 96, // Light Gray Tile			// 002
		 64, 64, // Red Tile				// 003
		 96, 64, // Cyan Tile				// 004
		128, 64, // Orange Tile				// 005
		160, 64, // Blue Tile				// 006
		192, 64, // Pink Tile				// 007
		224, 64, // Green Tile				// 008
		  0, 96, // Yellow Tile				// 009
		//////////////////////////////////////////
		 64, 96, // #0						// 010
		 96, 96, // #1						// 011
		128, 96, // #2						// 012
		160, 96, // #3						// 013
		192, 96, // #4						// 014
		224, 96, // #5						// 015
		  0,128, // #6						// 016
		 32,128, // #7						// 017
		 64,128, // #8						// 018
		 96,128, // #9						// 019
		//////////////////////////////////////////
		128,128, // A						// 020
		160,128, // B						// 021
		192,128, // C						// 022
		224,128, // D						// 023
		  0,160, // E						// 024
		 32,160, // F						// 025
		 64,160, // G						// 026
		 96,160, // H						// 027
		128,160, // I						// 028
		160,160, // J						// 029
		192,160, // K						// 030
		224,160, // L						// 031
		  0,192, // M						// 032
		 32,192, // N						// 033
		 64,192, // O						// 034
		 96,192, // P						// 035
		128,192, // Q						// 036
		160,192, // R						// 037
		192,192, // S						// 038
		224,192, // T						// 039
		  0,224, // U						// 040
		 32,224, // V						// 041
		 64,224, // W						// 042
		 96,224, // X						// 043
		128,224, // Y						// 044
		160,224, // Z						// 045
		//////////////////////////////////////////
		224,224, // :						// 046
		 32,256, // ?						// 047
		  0,256, // !						// 048
		 98,256, // .						// 049
		 64,256, // -						// 050
		 64,256, // "						// 051
		//////////////////////////////////////////
		128,256, // O Preview				// 052
		160,256, // T Preview				// 053
		192,256, // I Preview				// 054
		224,256, // L Preview				// 055
		  0,288, // J Preview				// 056
		 32,288, // S Preview				// 057
		 64,288, // Z Preview				// 058
		 96,288, // =						// 059
		128,288, // NE						// 060
		160,288, // XT						// 061
		192,288, // Empty					// 062
		192,288, // Backwards R				// 063
		224,288, // Hammer & Sickle			// 064
	};

	int BlockNums[7] = { 0,0,0,0,0,0,0 }; // Number of times each block has fallen

	int Level; // Current Level
	int LinesC; // Lines Cleared
	int X, Y; // Axis coordinates
	int Rot; // Current rotation 
	double _DropTS; // Time stamp for decrementing block
	double WaitTime; // Variable for game speed
	bool SpeedUp; // Flag for increasing speed
	int MenuSel; // Menu selection

	Direction pInput; // User Input
	
	BlockType CurrBlck; // Current falling block
	BlockType NxtBlck; // Next block to fall

	int Board[WH][WW] = {
		02,02,02,02,02,02,02,02,02,02,02,02,02,02,02,02,02,
		02,00,00,00,00,00,00,00,00,00,00,02,60,61,46,02,02,
		02,00,00,00,00,00,00,00,00,00,00,02,00,00,00,02,02,
		02,00,00,00,00,00,00,00,00,00,00,02,00,00,00,02,02,
		02,00,00,00,00,00,00,00,00,00,00,02,02,02,02,02,02,
		02,00,00,00,00,00,00,00,00,00,00,02,02,02,02,02,02,
		02,00,00,00,00,00,00,00,00,00,00,02,02,02,02,02,02,
		02,00,00,00,00,00,00,00,00,00,00,02,52,02,10,10,02,
		02,00,00,00,00,00,00,00,00,00,00,02,02,02,02,02,02,
		02,00,00,00,00,00,00,00,00,00,00,02,53,02,10,10,02,
		02,00,00,00,00,00,00,00,00,00,00,02,02,02,02,02,02,
		02,00,00,00,00,00,00,00,00,00,00,02,54,02,10,10,02,
		02,00,00,00,00,00,00,00,00,00,00,02,02,02,02,02,02,
		02,00,00,00,00,00,00,00,00,00,00,02,55,02,10,10,02,
		02,00,00,00,00,00,00,00,00,00,00,02,02,02,02,02,02,
		02,00,00,00,00,00,00,00,00,00,00,02,56,02,10,10,02,
		02,00,00,00,00,00,00,00,00,00,00,02,02,02,02,02,02,
		02,00,00,00,00,00,00,00,00,00,00,02,57,02,10,10,02,
		02,00,00,00,00,00,00,00,00,00,00,02,02,02,02,02,02,
		02,00,00,00,00,00,00,00,00,00,00,02,58,02,10,10,02,
		02,00,00,00,00,00,00,00,00,00,00,02,02,02,02,02,02,
		02,02,02,02,02,02,02,02,02,02,02,02,02,02,02,02,02,
		02,31,24,41,24,31,46,02,10,10,10,02,02,02,02,02,02,
		02,31,28,33,24,38,46,02,10,10,10,02,02,02,02,02,02,
		02,02,02,02,02,02,02,02,02,02,02,02,02,02,02,02,02,
	};
	int BoardCopy[WH][WW]; // Copy of Board[][] used for comparison when detecting collision
	/* Block Data -- Temporary, may combine */
	const struct B1 {
	public:
		int Limbs[12][2] = {
		/*  X,Y   */
		//////////// - Rotation 1
			1,0,
			1,1,
			0,1,
		//////////// - Rotation 2
			1,0,
			1,1,
			0,1,
		//////////// - Rotation 3
			1,0,
			1,1,
			0,1,
		//////////// - Rotation 4
			1,0,
			1,1,
			0,1,
		};
	}; B1 O; // O Block Data
	const struct B2{
		public:
		int Limbs[12][2] = {
		/*  X,Y   */
		//////////// - Rotation 1
			0,-1,
			0,1,
			0,2,
		//////////// - Rotation 2
			-1,0,
			1,0,
			2,0,
		//////////// - Rotation 3
			0,-1,
			0,1,
			0,2,
		//////////// - Rotation 4
			-1,0,
			1,0,
			2,0,
		};
	}; B2 I; // I Block Data
	const struct B3 {
		public:
		int Limbs[12][2] = {
		/*  X,Y   */
		//////////// - Rotation 1
			-1,0,
			1,0,
			0,1,
		//////////// - Rotation 2
			-1,0,
			0,-1,
			0,1,
		//////////// - Rotation 3
			-1,0,
			1,0,
			0,-1,
		//////////// - Rotation 4
			1,0,
			0,-1,
			0,1,
		};
	}; B3 T; // T Block Data
	const struct B4 {
	public:
		int Limbs[12][2] = {
		/*  X,Y   */
		//////////// - Rotation 1
			0,-1,
			0,1,
			1,1,
		//////////// - Rotation 2
			-1,0,
			1,0,
			-1,1,
		//////////// - Rotation 3
			0,-1,
			0,1,
			-1,-1,
		//////////// - Rotation 4
			-1,0,
			1,0,
			1,-1,
		};
	}; B4 L; // L Block Data
	const struct B5 {
		public:
		int Limbs[12][2] = {
		/*  X,Y   */
		//////////// - Rotation 1
			0,-1,
			0,1,
			1,-1,
		//////////// - Rotation 2
			-1,0,
			1,0,
			1,1,
		//////////// - Rotation 3
			0,-1,
			0,1,
			-1,1,
		//////////// - Rotation 4
			-1,0,
			1,0,
			-1,-1,
		};
	}; B5 J; // J Block Data
	const struct B6 {
		public:
		int Limbs[12][2] = {
		/*  X,Y   */
		//////////// - Rotation 1
			0,1,
			1,0,
			-1,1,
		//////////// - Rotation 2
			-1,0,
			-1,-1,
			0,1,
		//////////// - Rotation 3
			-1,0,
			0,-1,
			1,-1,
		//////////// - Rotation 4
			0,-1,
			1,0,
			1,1,
		};
	}; B6 S; // S Block Data
	const struct B7 {
		public:
		int Limbs[12][2] = {
		/*  X,Y   */
		//////////// - Rotation 1
			-1,0,
			0,1,
			1,1,
		//////////// - Rotation 2
			0,-1,
			-1,0,
			-1,1,
		//////////// - Rotation 3
			0,-1,
			-1,-1,
			1,0,
		//////////// - Rotation 4
			1,0,
			1,-1,
			0,1,
		};
	}; B7 Z; // Z Block Data

public:
	bool EXIT_G, EXIT_P; // Exit conditions before being transfered
	GameState State; // State of the game
	bool Pause; // Pause flag
	bool tSound; // Sound Toggle
	bool tMusic; // Music Toggle

	void DrawSprite(int spriteID, int x, int y) const; // Uses the index of sprites and active bitmap to output a sprite of the current global sprite size
	void DrawBoard() const; // Outputs Board[][] using DrawSprite
	void SetAxis(int x, int y); // Sets the given coordinate to the current axis
	void CopyBoard(); // Copies data of Board to BoardCopy
	bool IsBlockData(const int data) const; // Returns true if given data is associated with block sprites
	void DrawBlock(bool SolidFlag); // Draws CurrBlck at axis
	void ClearBoardCopy(); // Clears inside of the board copy
	void ClearBoard(); // Clears inside of the board
	void SetTile(int x, int y, int ID); // Sets a Board[][] index to given ID
	void BlockTest(); // Tests block drawing
	void DrawNextBlock(); // Draws icon for upcoming block
	void ApplyInput(); // Applies input specifically in logic
	BlockType GetRandomBlock() const; // Returns random BlockType
	bool DecrementBlock(); // Y++
	void DrawPause(); // Draws "Pause" string
	bool IsSolid(Direction Dir); // Collision Check
	void ResetBlock(); // Resets block position to top
	void DrawInteger(int x, int y, int size, int value); // Draw integer of two or three digits at a position
	void LineClear(); // Returns true and clears a line if it can be
	void DrawMenu(); // Draws details for menu
	void SetTileS(int x, int y, const char str[10]); // Sets a string of text as tiles
	void GameOver(); // Begins game over sequence if game has been lost
	void NewOption(int x, int y, int listnum); // Draws an option on the main menu

	/* Logic functions for main loop*/
	void Draw();
	void Input();
	void Logic();

	/* Definitions of constructors and destructors may be changed later */
	Game(bool M, bool S):tMusic(M),tSound(S) { 
		MenuSel = 1;
		State = BEFORE; 
		pInput = NONE;
		X = 5, Y = 2;
		CurrBlck = bX;
		NxtBlck = bX;
		Rot = 0; 
		Level = 1;
		Pause = false;
		LinesC = 0;
		_DropTS = GetTime();
		WaitTime = 1.5;
		SpeedUp = false;
		EXIT_G = false;
		EXIT_P = false;
	};
	~Game() { };
};
