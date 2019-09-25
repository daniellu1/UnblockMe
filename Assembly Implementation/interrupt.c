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

////////////////////CONFIG WHATEVER OTHER INTERRUPTS YOU WANT 

// Define the IRQ exception handler
void __attribute__((interrupt)) __cs3_isr_irq(void) {
	
	// Read the ICCIAR from the CPU Interface in the GIC
	int interrupt_ID = *((int *)0xFFFEC10C);
	
	if (interrupt_ID == 73) // check if interrupt is from the KEYs
		pushbutton_ISR();
		
	if (interrupt_ID == 29)
		timer_ISR(); 
	
	//////////////////// TYPE ANY OTHER INTERRUPT STUFF HERE 
	
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
	//////////////////// INSERT INTERRUPT ID HERE 
	
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

void pushbutton_ISR(void) {
	
	/* KEY base address */
	volatile int * KEY_ptr = (int *) 0xFF200050;
	
	int press;
	press = *(KEY_ptr + 3); // read the pushbutton interrupt register
	*(KEY_ptr + 3) = press; // Clear the interrupt
	
	// KEY0
	if (press & 0x1){ 
		////////////////////code
	}
	
	// KEY1
	else if (press & 0x2){ 
		////////////////////code
	}
	
	// KEY2
	else if (press & 0x4){
		////////////////////code
	}
	
	// KEY3
	else{
		////////////////////code
	}
	
	return;
}


void timer_ISR(void) {
	
	////////////////////stuff you wanna do with the timer 
	
	*(timer_address + 3) = 1;
	
}