.thumb
.syntax unified

.include "gpio_constants.s"     // Register-adresser og konstanter for GPIO
.include "sys-tick_constants.s" // Register-adresser og konstanter for SysTick

.text
	.global Start



// Øker tiendelene med 1 og sjekker at den ikke går over.
f_tenths:
	LDR R1, =tenths //Setter R1 til tenths variabelen
	LDR R0, [R1] //Laster verdien fra R1 inn i R0
	CMP R0, #9 //Sammenlikner tenths verdien og 9. Hvis vi er under 9 tiendeler settes flagg til 01, hvis vi er på 9 settes det til 10.
	BNE t_reset //Hvis condition er 10 går vi til reset for å nullstille
	LDR R2, [R1] //Kopierer R1 inn i R2
	PUSH {LR} // Henter link-registeret inn i stakken
	BL f_seconds //Brancher til seconds og lagerer returadressen i link-registeret
	POP {LR} //Legger link-registeret i registerlisten
	B t_end //Brancher for å avlutte funksjonen

	t_reset:
	LDR R2, =#1 //Laster 1 inn i R2
	ADD R0, R0, R2	//Adderer tenths og 1 inn i R0
	STR R0, [R1] // Lagrer resultatet i R1 og nulstiller tiendeler

	t_end:
	MOV PC, LR // Legger verdien til link-registeret inn i programtelleren og returnerer


// Funksjon for å inkrementere sekunder med 1, sjekke for overflyt og kalle led funksjonen
f_seconds:
	LDR R1, =seconds //Setter R1 til sekund variabelen
	LDR R0, [R1] //Laster R1 inn i R0
	CMP R0, #59 //Sammenlikner nåverende sekunder med 59 på samme måte som i tenths
	BNE s_reset // Hvis vi er på 59 sek (condition flagg 10) går vi til reset for å nullstille
	LDR R2, =#0 //Laster inn 0 i R2
	STR R2, [R1] // Legger verdien i R1 i R2
	PUSH {LR} //Henter link-registeret inn i stakken
	BL f_minutes //Hopper til minutes og lagrer returadressen i link-registeret
	POP {LR} //Legger link-registeret i registerlisten
	B s_end

	s_reset:
	LDR R2, =#1 //Laster 1 inn i R2
	ADD R0, R0, R2 // Adderer R0 og R2 og lagrer i Rl0
	STR R0, [R1] // Lagrer innholdet i R0 i R1 og nulstiller sekunder

	s_end:
	PUSH {LR} // Henter link-registeret inn i stakken
	BL toggle_led
	POP {LR} // Popper link-registeret fra stakken
	MOV PC, LR // Legger verdien til link-registeret inn i programtelleren og returnerer


// Funksjon for å telle minutter
f_minutes:
	LDR R1, =minutes // Setter R1 til minutt variabelen
	LDR R0, [R1] //Laster R1 inn i R0
	LDR R2, =#1 //Laster inn i 1 i R2
	ADD R0, R0, R2 // Summerer R0 og R2 og lagrer i R0
	STR R0, [R1] // Lagrer R0 i R1
	MOV PC, LR // Flytter link-registeret inn i programtelleren


toggle_led:
	STR R0, [R5] //Kopierer R0 inn i R5
	LDR R0, =LED_PORT //
	LDR R1, =PORT_SIZE
	MUL R0, R0, R1
	LDR R1, =GPIO_BASE
	ADD R0, R0, R1
	LDR R1, =#1
	LSL R1, R1, #LED_PIN
	LDR R2, =seconds
	LDR R2, [R2]
	AND R2, R2, #1
	CMP R2, #0
	BNE led_on
	LDR R2, =GPIO_PORT_DOUTCLR
	STR R1, [R0, R2]
	B led_end

	led_on:
	MOV R2, #1
	LDR R2, =GPIO_PORT_DOUTSET
	STR R1, [R0, R2]

	led_end:
	MOV PC, LR

.global SysTick_Handler
.thumb_func
	SysTick_Handler:
	PUSH {LR}
	BL f_tenths
	POP {LR}
	BX LR // Returner fra interrupt

.global GPIO_ODD_IRQHandler
.thumb_func
	GPIO_ODD_IRQHandler:
	LDR R0, =SYSTICK_BASE
	LDR R2, [R0]
	AND R2, #1
	CMP R2, #1
	BEQ STOP_CLOCK
	LDR R2, =#0b111
	STR R2, [R0]
	B CLOCK_SET_END
STOP_CLOCK:
	LDR R2, =#0b110
	STR R2, [R0]
CLOCK_SET_END:
	LDR R0, =GPIO_BASE
	LDR R2, =GPIO_IFC
	LDR R0, [R1, R2]
	LDR R3, =#1
	LSL R3, #9
	STR R3, [R1, R2]
	BX LR // Returner fra interrupt

Start:
	//Systick setup
	LDR R0, =SYSTICK_BASE
	LDR R2, =#0b110
	STR R2, [R0]
	LDR R1, =SYSTICK_LOAD
	LDR R2, =FREQUENCY/10
	STR R2, [R0, R1]
	//Set clock to 0
	LDR R0, =#0
	LDR R1, =tenths
	STR R0, [R1]
	//Button interrupt setup
	//Set select port B pin 9
	LDR R0, =GPIO_BASE
	LDR R1, =GPIO_EXTIPSELH
	ADD R0, R0, R1
	LDR R1, =#0b1111
	LSL R1, R1, #4
	MVN R1, R1
	LDR R0, [R0]
	AND R0, R0, R1
	LDR R1, =#0b0001
	LSL R1, #4
	ORR R0, R0, R1
	LDR R1, =GPIO_BASE
	LDR R2, =GPIO_EXTIPSELH
	STR R0, [R1, R2]
	//Set falling edge trigger pin 9
	LDR R2, =GPIO_EXTIFALL
	LDR R0, [R1, R2]
	LDR R3, =#1
	LSL R3, #9
	ORR R0, R0, R3
	STR R0, [R1, R2]
	//Set 	interrupt enable pin 9
	LDR R2, =GPIO_IEN
	LDR R0, [R1, R2]
	ORR R0, R0, R3
	STR R0, [R1, R2]
	//Set IF to 0 for safety
	LDR R0, =GPIO_BASE
	LDR R2, =GPIO_IFC
	LDR R0, [R1, R2]
	LDR R3, =#1
	LSL R3, #9
	STR R3, [R1, R2]
Loop:
	B Loop




NOP // Behold denne på bunnen av fila