#include <assert.h>
#include <pthread.h>

#include "sail.h"
#include "rts.h"

#include "memory.h"
#include "timing.h"

#define DMA_DURATION 152

enum ram_range
{
	REGULAR,
	ECHO,
	IO,
	OAM,
};

io_read_handler_t g_read_handlers[IO_LENGTH] = {0};
io_write_handler_t g_write_handlers[IO_LENGTH] = {0};

pthread_spinlock_t g_dma_transfer_busy_lock;
bool g_dma_transfer_busy = false;

void register_io_read_handler(uint64_t addr, io_read_handler_t handler)
{
	assert(addr >= IO_BASE && addr < IO_BASE + IO_LENGTH);
	g_read_handlers[addr - IO_BASE] = handler;
}

void register_io_write_handler(uint64_t addr, io_write_handler_t handler)
{
	assert(addr >= IO_BASE && addr < IO_BASE + IO_LENGTH);
	g_write_handlers[addr - IO_BASE] = handler;
}

io_read_handler_t get_io_read_handler(uint64_t addr)
{
	assert(addr >= IO_BASE && addr < IO_BASE + IO_LENGTH);
	return g_read_handlers[addr - IO_BASE];
}

io_write_handler_t get_io_write_handler(uint64_t addr)
{
	assert(addr >= IO_BASE && addr < IO_BASE + IO_LENGTH);
	return g_write_handlers[addr - IO_BASE];
}

inline static enum ram_range get_ram_range(uint64_t addr)
{
	if (addr >= IO_BASE && addr < IO_BASE + IO_LENGTH)
		return IO;

	else if (addr >= ECHO_RAM_BASE && addr < ECHO_RAM_BASE + ECHO_RAM_LENGTH)
		return ECHO;

	else if (addr >= OAM_BASE && addr < OAM_BASE + OAM_LENGTH)
		return OAM;

	return REGULAR;
}

void custom_read_ram(lbits *data,
					 const mpz_t addr_size,
					 const mpz_t data_size_mpz,
					 const lbits hex_ram,
					 const lbits addr_bv)
{
	uint64_t addr = mpz_get_ui(*addr_bv.bits);
	uint64_t data_size = mpz_get_ui(data_size_mpz);
	assert(mpz_get_ui(addr_size) == 32);

	switch (get_ram_range(addr))
	{
	case IO:
		if (get_io_read_handler(addr) != NULL)
		{
			uint64_t val = get_io_read_handler(addr)(addr, data_size);
			mpz_set_ui(*data->bits, val);
			return;
		}
#ifdef DEBUG
		else
		{
			printf("unknown io register: %x\n", addr);
			exit(0);
		}
#endif
		break;
	case ECHO:
		addr -= (ECHO_RAM_BASE - WRAM_BASE);
		break;
	case OAM:
		// During OAM DMA transfer we should return 0xFF
		// todo: actually, all of ram except for "high ram" isn't useable during DMA transfer, I however dont know how the CPU would act if you were to access it, for this reason I just assume programs are nice and dont touch ram at that time, that way I dont have to emulate it.
		pthread_spin_lock(&g_dma_transfer_busy_lock);
		if (g_dma_transfer_busy)
		{
			pthread_spin_unlock(&g_dma_transfer_busy_lock);
			mpz_set_ui(*data->bits, 0xFF); /* Return 0xFF if dma transfer is busy */
			return;
		}
		pthread_spin_unlock(&g_dma_transfer_busy_lock);
		break;
	default:
		break;
	}

	read_ram(data, addr_size, data_size_mpz, hex_ram, addr_bv);
}

bool custom_write_ram(const mpz_t addr_size,	 // unused
					  const mpz_t data_size_mpz, // number of bytes
					  const lbits hex_ram,		 // unused
					  const lbits addr_bv,
					  const lbits data)
{
	uint64_t addr = mpz_get_ui(*addr_bv.bits);
	uint64_t data_size = mpz_get_ui(data_size_mpz);
	assert(mpz_get_ui(addr_size) == 32);

	switch (get_ram_range(addr))
	{
	case IO:
		if (get_io_write_handler(addr) != NULL)
		{
			get_io_write_handler(addr)(addr, data_size, mpz_get_ui(*data.bits));
			return true;
		}
#ifdef DEBUG
		else
		{
			printf("unknown io register write: %x\n", addr);
			exit(0);
		}
#endif
		break;
	case ECHO:
		addr -= (ECHO_RAM_BASE - WRAM_BASE);
		break;
	default:
		break;
	}

	return write_ram(addr_size, data_size_mpz, hex_ram, addr_bv, data);
}

static void *dma_oam_transfer(void *arg)
{
	uint64_t val = (uint64_t)arg;
	uint64_t source = val << 8;
	uint64_t destination = OAM_BASE;

	unsigned long start = micros();

	for (int i = 0; i < OAM_LENGTH; i++)
	{
		uint64_t byte = read_mem(source++);
		write_mem(destination++, byte);
	}

	/* Sleep the rest of the transfer */
	usleep(DMA_DURATION - (micros() - start));

	pthread_spin_lock(&g_dma_transfer_busy_lock);
	g_dma_transfer_busy = false;
	pthread_spin_unlock(&g_dma_transfer_busy_lock);
}

static void io_write_oam_dma_start(uint64_t addr, int byte_count, uint64_t val)
{
	pthread_spin_lock(&g_dma_transfer_busy_lock);
	g_dma_transfer_busy = true;
	pthread_spin_unlock(&g_dma_transfer_busy_lock);

	pthread_t thread;
	pthread_create(&thread, NULL, dma_oam_transfer, (void *)val);
}

void memory_init()
{
	pthread_spin_init(&g_dma_transfer_busy_lock, 0);
	register_io_write_handler(0xFF46, io_write_oam_dma_start);
}