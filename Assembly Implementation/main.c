#include <stdlib.h>
#include <stdbool.h>
#include "address_map_arm.h"

/* GLOBAL VARIABLES */ 
volatile int pixel_buffer_start; // global variable
volatile int pixel_back_buffer_start;
volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
volatile int * back_buffer_address = (int *)0xFF203024;
volatile int * buffer_bit = (int *)0xFF203028;
volatile int * s_flag = (int *)0xFF20302C;	
volatile int * switchAddress = (int *)0xFF200040; 
volatile int * ledAddress = (int *)0xFF200000; 
volatile int * hexAddress = (int *)0xFF200020; 
volatile int * hex5_4Address = (int *)0xFF200030; 
volatile int * timer_address = (int *)0xFFFEC600; 

int board[6][6]; 
bool win, win2; 
int numMoves, time; 
int level = 1; 

typedef struct name{
	short int colour; 
	int x; 
	int y; 		// coordinates of top left corner 
	bool horizontal; 
	bool red;
} rectangle; 

int numBlocks = 9;
rectangle blocks[9]; 

/* FUNCTION PROTOTYPES */ 
void disable_A9_interrupts(void);
void set_A9_IRQ_stack(void);
void config_GIC(void);
void config_KEYs(void);
void enable_A9_interrupts(void);
void plot_pixel(int x, int y, short int line_color); 
void clear_screen(); 
void plot_pixel_back(int x, int y, short int line_color); 
void clear_screen_back(); 
void wait_for_vsync(); 
void pushbutton_ISR(void);
void config_interrupt(int, int);
void plot_rectangle(int x, int y, rectangle block); 
void plot_rectangle_back(int x, int y, rectangle block);
void draw_board(); 
void occupied_spaces();  
void initializeBoard(); 
void writeToHex3_0(int num); 
void writeToHex5_4(int num); 
int getBitCodes(int num); 
void config_timer(); 
void timer_ISR(void); 

/* MAIN EXECUTION OF PROGRAM */ 
int main(void) {
	
	disable_A9_interrupts(); // disable interrupts in the A9 processor
	
	set_A9_IRQ_stack(); // initialize the stack pointer for IRQ mode
	
	config_GIC(); // configure the general interrupt controller
	
	config_KEYs(); // configure pushbutton KEYs to generate interrupts
	
	enable_A9_interrupts(); // enable interrupts in the A9 processor
   	
    pixel_buffer_start = *pixel_ctrl_ptr;
	pixel_back_buffer_start = *back_buffer_address; 


	// DRAW THE BACKGROUND AND BORDER 
	
	int x, y; 
	for (x = 0; x < 319; x++){
		for (y = 0; y < 239; y++){
			
			short int colour; 
			
			if ((y == 23 && x >= 64 && x <= 241) || (y == 201 && x >= 64 && x <= 241) 
				|| (x == 64 && y >= 23 && y <= 201) || (x == 241 && y >= 23 && y <= 201)) 
				colour = 0xFFFF; 
			else 
				colour = 0x0; 
			
			plot_pixel(x, y, colour); 
		}
	}
	
	initializeBoard(); 
	
	while (1) // wait for an interrupt
	{
		
		if (win){
			win2 = 1; 
			*(ledAddress) = 0b1111111111; 
		}
		
		else{
		
			volatile int switchValue = *(switchAddress);
			switchValue &= 0x3FF;
			
			switch (switchValue) {
				case 0:
					switchValue = 0;
					break;
				case 1:
					switchValue = 1;
					break;
				case 2:
					switchValue = 2;
					break;
				case 4:
					switchValue = 3;
					break;
				case 8:
					switchValue = 4;
					break;
				case 16:
					switchValue = 5;
					break;
				case 32:
					switchValue = 6;
					break;
				case 64:
					switchValue = 7;
					break;
				case 128:
					switchValue = 8;
					break;
				default: 
					switchValue = 0; 
			}
			
			
			*(ledAddress) = 0; 

			int i; 
			for (i = 0; i < numBlocks; i++)
			{
				if (i == switchValue)
					blocks[i].colour = 0x000F;
				else
				{
					if (blocks[i].red)
						blocks[i].colour = 0xF000;
					else	
						blocks[i].colour = 0xFFFF;
				}
				plot_rectangle((blocks[i].x) * 30 + 65, (blocks[i].y) * 30 + 25, blocks[i]);
			}

			wait_for_vsync(); // swap front and back buffers on VGA vertical sync
			pixel_buffer_start = *(pixel_ctrl_ptr + 1); // new back buffer
		}
	}
}

void writeToHex3_0(int num){
	
	int hundreds = num / 60; 
	hundreds = getBitCodes(hundreds); 
	
	int tens = (num % 60) / 10; 
	tens = getBitCodes(tens); 
	
	int ones = (num % 60) % 10; 
	ones = getBitCodes(ones); 
	
	int thousands = 10; 
	thousands = getBitCodes(thousands); 
	
	*(hexAddress) = ones | tens << 8 | hundreds << 16 | thousands << 24; 
	
}

void writeToHex5_4(int num){
	
	int ones = num % 10; 
	ones = getBitCodes(ones); 
	
	int tens = (num/10) % 10; 
	tens = getBitCodes(tens); 
	
	*(hex5_4Address) = ones | tens << 8; 

}


int getBitCodes(int num){
	
	if (num == 0) 
		return 0b00111111; 
	if (num == 1) 
		return 0b00000110; 
	if (num == 2)
		return 0b01011011; 
	if (num == 3) 
		return 0b01001111; 
	if (num == 4)
		return 0b01100110; 
	if (num == 5) 
		return 0b01101101; 
	if (num == 6) 
		return 0b01111101; 
	if (num == 7) 
		return 0b00000111; 
	if (num == 8) 
		return 0b01111111; 
	if (num == 9) 
		return 0b01100111; 
	else 
		return 0b0; 
	
}

void initializeBoard(){
	
	// DRAW THE INITIAL PUZZLE
	if (level == 1){
		blocks[0].x = 0; 
		blocks[0].y = 2; 
		blocks[0].horizontal = 1; 
		blocks[0].red = 1;
		
		blocks[1].x = 1; 
		blocks[1].y = 0; 
		blocks[1].horizontal = 0; 
		blocks[1].red = 0;
		
		blocks[2].x = 2; 
		blocks[2].y = 0; 
		blocks[2].horizontal = 1; 
		blocks[2].red = 0;
		
		blocks[3].x = 4; 
		blocks[3].y = 0; 
		blocks[3].horizontal = 0; 
		blocks[3].red = 0;

		blocks[4].x = 2; 
		blocks[4].y = 1; 
		blocks[4].horizontal = 0; 
		blocks[4].red = 0;

		blocks[5].x = 5; 
		blocks[5].y = 2; 
		blocks[5].horizontal = 0; 
		blocks[5].red = 0;

		blocks[6].x = 0; 
		blocks[6].y = 4; 
		blocks[6].horizontal = 0; 
		blocks[6].red = 0;

		blocks[7].x = 4; 
		blocks[7].y = 4; 
		blocks[7].horizontal = 1; 
		blocks[7].red = 0;

		blocks[8].x = 2; 
		blocks[8].y = 5; 
		blocks[8].horizontal = 1; 
		blocks[8].red = 0;
	}

	
	else if (level == 2){
		blocks[0].x = 2; 
		blocks[0].y = 2; 
		blocks[0].horizontal = 1; 
		blocks[0].red = 1;
		
		blocks[1].x = 3; 
		blocks[1].y = 0; 
		blocks[1].horizontal = 0; 
		blocks[1].red = 0;
		
		blocks[2].x = 4; 
		blocks[2].y = 0; 
		blocks[2].horizontal = 1; 
		blocks[2].red = 0;
		
		blocks[3].x = 4; 
		blocks[3].y = 1; 
		blocks[3].horizontal = 0; 
		blocks[3].red = 0;

		blocks[4].x = 1; 
		blocks[4].y = 3; 
		blocks[4].horizontal = 1; 
		blocks[4].red = 0;

		blocks[5].x = 3; 
		blocks[5].y = 3; 
		blocks[5].horizontal = 0; 
		blocks[5].red = 0;

		blocks[6].x = 4; 
		blocks[6].y = 3; 
		blocks[6].horizontal = 1; 
		blocks[6].red = 0;

		blocks[7].x = 2; 
		blocks[7].y = 4; 
		blocks[7].horizontal = 0; 
		blocks[7].red = 0;

		blocks[8].x = 3; 
		blocks[8].y = 5; 
		blocks[8].horizontal = 1; 
		blocks[8].red = 0;
	}
	
	else{
		blocks[0].x = 1; 
		blocks[0].y = 2; 
		blocks[0].horizontal = 1; 
		blocks[0].red = 1;
		
		blocks[1].x = 4; 
		blocks[1].y = 0; 
		blocks[1].horizontal = 1; 
		blocks[1].red = 0;
		
		blocks[2].x = 2; 
		blocks[2].y = 1; 
		blocks[2].horizontal = 1; 
		blocks[2].red = 0;
		
		blocks[3].x = 4; 
		blocks[3].y = 1; 
		blocks[3].horizontal = 0; 
		blocks[3].red = 0;

		blocks[4].x = 3; 
		blocks[4].y = 2; 
		blocks[4].horizontal = 0; 
		blocks[4].red = 0;

		blocks[5].x = 4; 
		blocks[5].y = 3; 
		blocks[5].horizontal = 1; 
		blocks[5].red = 0;

		blocks[6].x = 2; 
		blocks[6].y = 4; 
		blocks[6].horizontal = 1; 
		blocks[6].red = 0;

		blocks[7].x = 5; 
		blocks[7].y = 4; 
		blocks[7].horizontal = 0; 
		blocks[7].red = 0;

		blocks[8].x = 3; 
		blocks[8].y = 5; 
		blocks[8].horizontal = 1; 
		blocks[8].red = 0;
	}

	win = 0; 
	win2 = 0;  
	numMoves = 0; 
	time = 0; 
	writeToHex5_4(numMoves);

	config_timer(); //configure timer to generate interrupts
	occupied_spaces(); 
	draw_board(); 
	
}

void draw_board(){
	
	clear_screen(); 
	
	if (blocks[0].x == 4){
		
		int x, y; 
		
		for (x = 65; x < 240; x++){
			for (y = 25; y < 200; y++){
				plot_pixel(x, y, 0xFFFF); 
			}
		}
		
		win = 1; 
		level = level + 1; 
		
		return; 
	}
	
	int i; 
	for (i = 0; i < numBlocks; i++)
	{
		if (blocks[i].red)
			blocks[i].colour = 0xF000;
		else
			blocks[i].colour = 0xFFFF; 
		plot_rectangle_back((blocks[i].x) * 30 + 65, (blocks[i].y) * 30 + 25, blocks[i]); 
	}
	
}


// Function to draw rectangle on the screen 
void plot_rectangle(int x, int y, rectangle block){
	
	int x_pos, y_pos; 
	
	if (block.horizontal){
		
		for (x_pos = x; x_pos < x+55; x_pos++){
			for(y_pos = y; y_pos < y+25; y_pos++){
				plot_pixel(x_pos, y_pos, block.colour); 
			}
		}
		
	}
	
	else{

		for (x_pos = x; x_pos < x+25; x_pos++){
			for(y_pos = y; y_pos < y+55; y_pos++){
				plot_pixel(x_pos, y_pos, block.colour); 
			}
		}
		
	}
	
}

void plot_rectangle_back(int x, int y, rectangle block){
	
	int x_pos, y_pos; 
	
	if (block.horizontal){
		
		for (x_pos = x; x_pos < x+55; x_pos++){
			for(y_pos = y; y_pos < y+25; y_pos++){
				plot_pixel_back(x_pos, y_pos, block.colour); 
			}
		}
	}
	
	else{

		for (x_pos = x; x_pos < x+25; x_pos++){
			for(y_pos = y; y_pos < y+55; y_pos++){
				plot_pixel_back(x_pos, y_pos, block.colour); 
			}
		}
		
	}
	
}

// Function to draw a pixel on the screen 
void plot_pixel(int x, int y, short int line_color){
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}

void plot_pixel_back (int x, int y, short int line_color){
    *(short int *)(pixel_back_buffer_start + (y << 10) + (x << 1)) = line_color;
}



// Function to clear the screen 
void clear_screen(){
	
	int x, y; 
	for (x = 65; x < 240; x++){
		for (y = 25; y < 200; y++){
			plot_pixel(x, y, 0x0); 
		}
	}
	
}

void clear_screen_back(){
	
	int x, y; 
	for (x = 65; x < 240; x++){
		for (y = 25; y < 200; y++){
			plot_pixel(x, y, 0x0); 
		}
	}
	
}




// Function that waits for the buffer to swap 
void wait_for_vsync(){
	
	*(pixel_ctrl_ptr) = 1; 
	while((*(s_flag) & 0x1) != 0b0) {} ; 
	return; 
	
}


/* This file:
* 1. defines exception vectors for the A9 processor
* 2. provides code that sets the IRQ mode stack, and that dis/enables
* interrupts
* 3. provides code that initializes the generic interrupt controller
*/

/* setup the KEY interrupts in the FPGA */
void config_KEYs() {
	
	volatile int * KEY_ptr = (int *) 0xFF200050; // pushbutton KEY base addres
	
	*(KEY_ptr + 2) = 0xF; // enable interrupts for the two KEYs
	
}


void config_timer() {
	
	*(timer_address) = 200000000;  
	*(timer_address + 2) = 0xF; 
	
}

// Define the IRQ exception handler
void __attribute__((interrupt)) __cs3_isr_irq(void) {
	
	// Read the ICCIAR from the CPU Interface in the GIC
	int interrupt_ID = *((int *)0xFFFEC10C);
	
	if (interrupt_ID == 73) // check if interrupt is from the KEYs
		pushbutton_ISR();
		
	if (interrupt_ID == 29)
		timer_ISR(); 
	
	// Write to the End of Interrupt Register (ICCEOIR)
	*((int *)0xFFFEC110) = interrupt_ID;
	
}



/* 
* Turn off interrupts in the ARM processor
*/
void disable_A9_interrupts(void) {
	int status = 0b11010011;
	asm("msr cpsr, %[ps]" : : [ps] "r"(status));
}



/*
* Initialize the banked stack pointer register for IRQ mode
*/
void set_A9_IRQ_stack(void) {
	
	int stack, mode;
	stack = 0xFFFFFFFF - 7; // top of A9 onchip memory, aligned to 8 bytes
	
	/* change processor to IRQ mode with interrupts disabled */
	mode = 0b11010010;
	asm("msr cpsr, %[ps]" : : [ps] "r"(mode));
	
	/* set banked stack pointer */
	asm("mov sp, %[ps]" : : [ps] "r"(stack));
	
	/* go back to SVC mode before executing subroutine return! */
	mode = 0b11010011;
	asm("msr cpsr, %[ps]" : : [ps] "r"(mode));
	
}



/*
* Turn on interrupts in the ARM processor
*/
void enable_A9_interrupts(void) {
	int status = 0b01010011;
	asm("msr cpsr, %[ps]" : : [ps] "r"(status));
}



/*
* Configure the Generic Interrupt Controller (GIC)
*/
void config_GIC(void) {
	
	config_interrupt (73, 1); // configure the FPGA KEYs interrupt (73)
	config_interrupt (29, 1); // configure the FPGA timer interrupt (73)
	
	// Set Interrupt Priority Mask Register (ICCPMR). Enable interrupts of all
	// priorities
	*((int *) 0xFFFEC104) = 0xFFFF;
	
	// Set CPU Interface Control Register (ICCICR). Enable signaling of
	// interrupts
	*((int *) 0xFFFEC100) = 1;
	
	// Configure the Distributor Control Register (ICDDCR) to send pending
	// interrupts to CPUs
	*((int *) 0xFFFED000) = 1;
	
}



/*
* Configure Set Enable Registers (ICDISERn) and Interrupt Processor Target
* Registers (ICDIPTRn). The default (reset) values are used for other registers
* in the GIC.
*/
void config_interrupt(int N, int CPU_target) {
	
	int reg_offset, index, value, address;
	
	/* Configure the Interrupt Set-Enable Registers (ICDISERn).
	* reg_offset = (integer_div(N / 32) * 4
	* value = 1 << (N mod 32) */
	reg_offset = (N >> 3) & 0xFFFFFFFC;
	index = N & 0x1F;
	value = 0x1 << index;
	address = 0xFFFED100 + reg_offset;
	
	/* Now that we know the register address and value, set the appropriate bit */
	*(int *)address |= value;
	
	/* Configure the Interrupt Processor Targets Register (ICDIPTRn)
	* reg_offset = integer_div(N / 4) * 4
	* index = N mod 4 */
	reg_offset = (N & 0xFFFFFFFC);
	index = N & 0x3;
	address = 0xFFFED800 + reg_offset + index;
	
	/* Now that we know the register address and value, write to (only) the
	* appropriate byte */
	*(char *)address = (char)CPU_target;
	
}

// Function that keeps track of which spaces on the baord have been occupied 
void occupied_spaces(){

	int i, j; 
	
	// set all spaces to unoccupied
	for (i = 0; i < 6; i++){
		for (j = 0; j < 6; j++){
			board[i][j] = 0; 
		}
	}
	
	// set occupied spaces
	for (i = 0; i < numBlocks; i++){
		
		
		if (blocks[i].horizontal){
			board[ (blocks[i].x) ][ (blocks[i].y) ] = 1; 
			board[ (blocks[i].x) + 1 ][ (blocks[i].y) ] = 1; 
		}
		else{
			board[ (blocks[i].x) ][ (blocks[i].y) ] = 1; 
			board[ (blocks[i].x) ][ (blocks[i].y) + 1 ] = 1; 
		}
		
	}

}


/********************************************************************
* Pushbutton - Interrupt Service Routine
*
* This routine checks which KEY has been pressed.
*******************************************************************/
void pushbutton_ISR(void) {
	
	/* KEY base address */
	volatile int * KEY_ptr = (int *) 0xFF200050;
	
	int press;
	press = *(KEY_ptr + 3); // read the pushbutton interrupt register
	*(KEY_ptr + 3) = press; // Clear the interrupt
	
	volatile int switchValue = *(switchAddress);
		switchValue &= 0x3FF;
		
		switch (switchValue) {
			case 0:
				switchValue = 0;
				break;
			case 1:
				switchValue = 1;
				break;
			case 2:
				switchValue = 2;
				break;
			case 4:
				switchValue = 3;
				break;
			case 8:
				switchValue = 4;
				break;
			case 16:
				switchValue = 5;
				break;
			case 32:
				switchValue = 6;
				break;
			case 64:
				switchValue = 7;
				break;
			case 128:
				switchValue = 8;
				break;
			default: 
				switchValue = 0; 
		} 
	
	// KEY0
	if (press & 0x1){ 
		if (blocks[switchValue].horizontal){
			if ( blocks[switchValue].x < 4 && board[ blocks[switchValue].x + 2 ][ blocks[switchValue].y ] == 0){
				blocks[switchValue].x+=1;
				numMoves = numMoves + 1; 
				writeToHex5_4(numMoves);
				occupied_spaces(); 
				draw_board();
			}
		}
	}
	
	// KEY1
	else if (press & 0x2){ 
		if (blocks[switchValue].horizontal){
			if (blocks[switchValue].x > 0 && board[ blocks[switchValue].x - 1 ][ blocks[switchValue].y ] == 0){
				blocks[switchValue].x-=1;
				numMoves = numMoves + 1; 
				writeToHex5_4(numMoves);
				occupied_spaces();
				draw_board();
			}
		}
	}
	
	// KEY2
	else if (press & 0x4){
		if (!blocks[switchValue].horizontal){
			if (blocks[switchValue].y < 4 &&  board[ blocks[switchValue].x ][ blocks[switchValue].y + 2 ] == 0){
				blocks[switchValue].y+=1;
				numMoves = numMoves + 1; 
				writeToHex5_4(numMoves);
				occupied_spaces();
				draw_board(); 
			}
		}
	}
	
	// press & 0x8, which is KEY3
	else{
		if (!blocks[switchValue].horizontal){
			if (blocks[switchValue].y > 0 && board[ blocks[switchValue].x ][ blocks[switchValue].y - 1 ] == 0){
				blocks[switchValue].y-=1;
				numMoves = numMoves + 1; 
				writeToHex5_4(numMoves);
				occupied_spaces();
				draw_board(); 
			}
		}
	}
	
	if (win2){
		initializeBoard();
	}
	
	return;
}


void timer_ISR(void) {
	
	if (win2){
		initializeBoard();
		return;
	}
	
	if (time == 600) 
		time = 0; 
	else 
		time = time + 1; 
	
	writeToHex3_0(time); 
	
	*(timer_address + 3) = 1;
	
}