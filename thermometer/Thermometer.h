
#ifndef THERMOMETER_H
#define THERMOMETER_H

enum {
	AM_RADIO_MESSAGE 		= 0x80,
	SERIAL_ADDR_NODE		= 0x01,
	SERIAL_ADDR_BASE		= 0x00,

	MSG_THERMOMETER			= 0x01,
	MSG_REQ_THERMOMETER		= 0x10,
};

// MSG_THERMOMETER
typedef nx_struct {
	nx_uint8_t header;
	nx_uint8_t addr; // base or node
	nx_int32_t temp;
	nx_int32_t light;
	nx_uint16_t battery;
} thermometer_msg_t;

// MSG_REQ_THERMOMETER
typedef nx_struct {
	nx_uint8_t header;
} req_thermometer_msg_t;

#endif
