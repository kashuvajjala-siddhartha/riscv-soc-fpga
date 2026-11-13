// =============================================================================
// File        : main.c
// Project     : WaveGuard SoC Firmware — Honours Project 1602-23-735-045
// Description : Mentor's test program with SoC peripheral integration driver.
// =============================================================================

// Base Addresses from SoC Memory Map
#define RAM_BASE        0x00000000
#define DMA_BASE        0x80000000
#define CRC_BASE        0x80001000
#define TIMER_BASE      0x80002000
#define SEVENSEG_BASE   0x80003000

// DMA Register Offsets
#define DMA_CTRL        (*(volatile unsigned int *)(DMA_BASE + 0x00))
#define DMA_STATUS      (*(volatile unsigned int *)(DMA_BASE + 0x04))
#define DMA_DST_LO      (*(volatile unsigned int *)(DMA_BASE + 0x08))
#define DMA_DST_HI      (*(volatile unsigned int *)(DMA_BASE + 0x0C))
#define DMA_LENGTH      (*(volatile unsigned int *)(DMA_BASE + 0x10))
#define DMA_COUNT       (*(volatile unsigned int *)(DMA_BASE + 0x14))

// CRC Register Offsets
#define CRC_CTRL        (*(volatile unsigned int *)(CRC_BASE + 0x00))
#define CRC_STATUS      (*(volatile unsigned int *)(CRC_BASE + 0x04))
#define CRC_SRC_LO      (*(volatile unsigned int *)(CRC_BASE + 0x08))
#define CRC_SRC_HI      (*(volatile unsigned int *)(CRC_BASE + 0x0C))
#define CRC_LENGTH      (*(volatile unsigned int *)(CRC_BASE + 0x10))
#define CRC_EXPECTED    (*(volatile unsigned int *)(CRC_BASE + 0x14))
#define CRC_COMPUTED    (*(volatile unsigned int *)(CRC_BASE + 0x18))

// Timer Register Offsets
#define TIMER_CTRL      (*(volatile unsigned int *)(TIMER_BASE + 0x00))
#define TIMER_STATUS    (*(volatile unsigned int *)(TIMER_BASE + 0x04))
#define TIMER_PRESCALE  (*(volatile unsigned int *)(TIMER_BASE + 0x08))
#define TIMER_COUNTER   (*(volatile unsigned int *)(TIMER_BASE + 0x0C))
#define TIMER_MATCH     (*(volatile unsigned int *)(TIMER_BASE + 0x10))

// 7-Segment Register Offsets
#define SEVENSEG_STATUS (*volatile unsigned int *)(SEVENSEG_BASE + 0x00))

// =============================================================================
// Mentor's required function
// =============================================================================
int add(int a, int b)
{
    return a + b;
}

int main()
{
    int x = 10;
    int y = 20;
    int sum = add(x, y); // sum = 30 (0x1E)

    // Store result in memory location 0x00000100 for verification
    volatile int *result_mem = (volatile int *)0x00000100;
    *result_mem = sum;

    return sum;
}
