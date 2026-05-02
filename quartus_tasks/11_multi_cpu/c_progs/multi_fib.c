typedef unsigned int uint32_t;
typedef unsigned char uint8_t;

#define ADDR_FIFO_DATA  ((uint8_t *)0x10)
#define ADDR_FIFO_FULL  ((uint8_t *)0x14)
#define ADDR_FIFO_EMPTY ((uint8_t *)0x18)
#define ADDR_CORE_ID    ((uint8_t *)0x1c)
#define ADDR_DISP7      ((uint8_t *)0x20)

#define ADDR_SINK       ((uint8_t *)0x24)

#define WRITE(addr, data) do {*((volatile uint32_t *)addr) = data;} while(0)
#define READ(addr) (*((volatile uint32_t *)addr))

void main() {
    uint32_t core_id = READ(ADDR_CORE_ID);

    if (core_id == 0) {
        uint32_t first = 0, second = 1, next, i = 0;
    
        for (i = 0; i != 15; i++) {
            next = first + second;
            while (READ(ADDR_FIFO_FULL)) ;
            WRITE(ADDR_FIFO_DATA, next);
            first = second;
            second = next;
        }
    } else if (core_id == 1) {
        uint32_t val = (uint32_t)0xDEAD;
        WRITE(ADDR_DISP7, val);

        while (1) {
            uint32_t delay = 8000000;
            while(delay--) WRITE(ADDR_SINK, delay);

            while (READ(ADDR_FIFO_EMPTY)) ;
            
            val = READ(ADDR_FIFO_DATA);
            WRITE(ADDR_DISP7, val);
        }
    }
}
