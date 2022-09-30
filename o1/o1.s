.thumb
.syntax unified

.include "gpio_constants.s"     // Register-adresser og konstanter for GPIO

.text
	.global Start
	
Start:

// Lagrer adressen for LED0 inn i R0
LDR R0, =PORT_E
LDR R1, =PORT_SIZE
MUL R0, R0, R1
LDR R1, =GPIO_BASE
ADD R0, R0, R1

// Lagrer adressen for PB0 inn i R1
LDR R1, =PORT_B
LDR R2, =PORT_SIZE
MUL R1, R1, R2
LDR R2, =GPIO_BASE
ADD R1, R1, R2
LDR R2, =GPIO_PORT_DIN
ADD R1, R1, R2

// Lager en loop som kontinuerlig sjekker om knappen er 1 eller 0. 
loop:
LDR R2, [R1]
AND R2, R2, 0b1000000000
CMP R2, 0b0000000000
BEQ on

// Kode for og skru av lyset
MOV R2, #1
LSL R2, R2, #LED_PIN
LDR R3, =GPIO_PORT_DOUTCLR
STR R2, [R0, R3]
B loop


// Lager en branch for å skru på lyset
on:
MOV R2, #1
LSL R2, R2, #LED_PIN
LDR R3, =GPIO_PORT_DOUTSET
STR R2, [R0, R3]
B loop


NOP // Behold denne på bunnen av fila
