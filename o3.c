#include "o3.h"
#include "gpio.h"
#include "systick.h"

/**************************************************************************/ /**
                                                                              * @brief Konverterer nummer til string
                                                                              * Konverterer et nummer mellom 0 og 99 til string
                                                                              *****************************************************************************/
void int_to_string(char *timestamp, unsigned int offset, int i)
{
    if (i > 99)
    {
        timestamp[offset] = '9';
        timestamp[offset + 1] = '9';
        return;
    }

    while (i > 0)
    {
        if (i >= 10)
        {
            i -= 10;
            timestamp[offset]++;
        }
        else
        {
            timestamp[offset + 1] = '0' + i;
            i = 0;
        }
    }
}

/**************************************************************************/ /**
                                                                              * @brief Konverterer 3 tall til en timestamp-string
                                                                              * timestamp-argumentet må være et array med plass til (minst) 7 elementer.
                                                                              * Det kan deklareres i funksjonen som kaller som "char timestamp[7];"
                                                                              * Kallet blir dermed:
                                                                              * char timestamp[7];
                                                                              * time_to_string(timestamp, h, m, s);
                                                                              *****************************************************************************/
void time_to_string(char *timestamp, int h, int m, int s)
{
    timestamp[0] = '0';
    timestamp[1] = '0';
    timestamp[2] = '0';
    timestamp[3] = '0';
    timestamp[4] = '0';
    timestamp[5] = '0';
    timestamp[6] = '\0';

    int_to_string(timestamp, 0, h);
    int_to_string(timestamp, 2, m);
    int_to_string(timestamp, 4, s);
}

// Typedefs from kompendie

typedef struct
{
    volatile word CTRL;
    volatile word MODEL;
    volatile word MODEH;
    volatile word DOUT;
    volatile word DOUTSET;
    volatile word DOUTCLR;
    volatile word DOUTTGL;
    volatile word DIN;
    volatile word PINLOCKN;

} gpio_port_map_t;

typedef struct
{
    volatile gpio_port_map_t ports[6];
    volatile word unused_space[10];
    volatile word EXTIPSELL;
    volatile word EXTIPSELH;
    volatile word EXTIRISE;
    volatile word EXTIFALL;
    volatile word IEN;
    volatile word IF;
    volatile word IFS;
    volatile word IFC;
    volatile word ROUTE;
    volatile word INSENSE;
    volatile word LOCK;
    volatile word CTRL;
    volatile word CMD;
    volatile word EM4WUEN;
    volatile word EM4WUPOL;
    volatile word EM4WUCAUSE;
} gpio_map_t;

typedef struct
{
    volatile word CTRL;
    volatile word LOAD;
    volatile word VAL;
    volatile word CALIB;
} systick_t;

int seconds = 0;
int minutes = 0;
int hours = 0;
int countdown_state = 0;

// Setup a pointer to GPIO_BASE
volatile gpio_map_t *gpio = (gpio_map_t *)GPIO_BASE;

int main(void)
{
    init();

    // Starts the clock
    volatile systick_t *sys_tick;
    sys_tick = (systick_t *)SYSTICK_BASE;
    sys_tick->CTRL = 0b0111;
    sys_tick->LOAD = FREQUENCY;

    // Setup of LED0
    gpio->ports[GPIO_PORT_E].DOUT = 0;
    gpio->ports[GPIO_PORT_E].MODEL = ((~(0b1111 << 8)) & gpio->ports[GPIO_PORT_E].MODEL) | (GPIO_MODE_OUTPUT << 8);

    gpio->ports[GPIO_PORT_B].DOUT = 0;

    // Setup of PB0
    gpio->ports[GPIO_PORT_B].MODEH = ((~(0b1111 << 4)) & gpio->ports[GPIO_PORT_B].MODEH) | (GPIO_MODE_INPUT << 4);
    gpio->EXTIPSELH = ((~(0b1111 << 4)) & gpio->EXTIPSELH) | (0b0001 << 4);
    gpio->EXTIFALL = gpio->EXTIFALL | (1 << 9);
    gpio->IEN = gpio->IEN | (1 << 9);

    // Setup of PB1
    gpio->ports[GPIO_PORT_B].MODEH = ((~(0b1111 << 8)) & gpio->ports[GPIO_PORT_B].MODEH) | (GPIO_MODE_INPUT << 8);
    gpio->EXTIPSELH = ((~(0b1111 << 8)) & gpio->EXTIPSELH) | (0b0001 << 8);
    gpio->EXTIFALL = gpio->EXTIFALL | (1 << 10);
    gpio->IEN = gpio->IEN | (1 << 10);

    // Loop to keep program alive
    while (1)
    {
        char str[7];
        time_to_string(str, hours, minutes, seconds);
        lcd_write(str);
    }
    return 0;
}

void toggle_led(int number)
{
    if (number == 1)
        gpio->ports[GPIO_PORT_E].DOUTSET = 1 << 2;
    else
        gpio->ports[GPIO_PORT_E].DOUTCLR = 1 << 2;
}

// Handler for button 0
void GPIO_ODD_IRQHandler(void)
{
    if (countdown_state == 0)
    {
        seconds++;
    }
    if (countdown_state == 1)
    {
        minutes++;
    }
    if (countdown_state == 2)
    {
        hours++;
    }
    gpio->IFC = 1 << 9;
}

// Handler for when PB1 is pressed.
void GPIO_EVEN_IRQHandler(void)
{
    int any = 0;

    if (countdown_state == 4)
    {
        any = 1;
        countdown_state = 0;
        toggle_led(0);
    }

    if (countdown_state == 2)
    {
        any = 1;
        if (hours + minutes + seconds == 0)
        {
            countdown_state = 4;
            toggle_led(1);
        }
        else
        {
            countdown_state++;
        }
    }
    if (any == 0)
    {
        countdown_state++;
    }
    gpio->IFC = 1 << 10;
}

void SysTick_Handler(void)
{
    if (countdown_state == 3)
    {
        seconds--;
        if (seconds == -1)
        {
            minutes--;
            seconds = 59;
            if (minutes == -1)
            {
                hours--;
                minutes = 59;
            }
        }
        if (hours == 0 && minutes == 0 && seconds == 0)
        {
            countdown_state = 4;
            toggle_led(1);
        }
    }
}
