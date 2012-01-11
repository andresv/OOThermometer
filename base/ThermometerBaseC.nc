
#include "Thermometer.h"
#include "ThermometerBase.h"

#define CHECK_PERIOD 	5*1024UL 		// checks if it should send new temp if time difference is big
#define SEND_PERIOD 	30*1024UL 	// this time it is always sent
#define POWER_ON_DELAY 	128
#define BLINK_ON_TIME 	256

#define SERIAL_SYNC_TIME 128

#define RX_TIMEOUT 10
#define RX_BYTES 50

module ThermometerBaseC {
	uses {
        interface Boot;
		interface Leds;
		interface Receive;
    	interface AMSend;
    	interface Packet;
    	interface LowPowerListening;

    	interface SplitControl as AMControl;
        interface OOSensorRead as Temperature;
        interface OOSensorRead as Light;
        interface GeneralIO as SensorPower;

        interface SerialCom;
        interface StdControl as SerialControl;

        interface Pool<buffer_entry_t> as OutPool;
        interface Queue<buffer_entry_t*> as OutQueue;

        interface Timer<TMilli> as CheckTimer;
        interface Timer<TMilli> as SendTimer;
        interface Timer<TMilli> as PowerDelayTimer;
        interface Timer<TMilli> as Led2BlinkTimer;
        interface Timer<TMilli> as Led1BlinkTimer;
        interface Timer<TMilli> as Led0BlinkTimer;

        interface Timer<TMilli> as SyncTimer;
	}
}
implementation {

	message_t packet;
	bool busy = FALSE;
	bool serialbusy = FALSE;

	bool temp_done = FALSE;
	int32_t temp = 0;
	bool light_done = FALSE;
	int32_t light = 0;

	bool force_reading = FALSE;

	void measure();
	task void measureDone();
	task void SendToSerial();
	task void received();

    //----------------------------------------------------------------------------
    // Blink
    //----------------------------------------------------------------------------
	void led2Blink(uint16_t onPeriod) {
        call Leds.led2On();
        call Led2BlinkTimer.startOneShot(onPeriod);
    }
    event void Led2BlinkTimer.fired() { call Leds.led2Off(); }
    
    void led1Blink(uint16_t onPeriod) {
        call Leds.led1On();
        call Led1BlinkTimer.startOneShot(onPeriod);
    }
    event void Led1BlinkTimer.fired() { call Leds.led1Off(); }

    void led0Blink(uint16_t onPeriod) {
        call Leds.led0On();
        call Led0BlinkTimer.startOneShot(onPeriod);
    }
    event void Led0BlinkTimer.fired() { call Leds.led0Off(); }


    //----------------------------------------------------------------------------
    // Boot
    //----------------------------------------------------------------------------
	event void Boot.booted() {
		call AMControl.start();

		call SerialCom.setup(RX_TIMEOUT, RX_BYTES);
		call SerialControl.start();
	}

	event void AMControl.startDone(error_t error) {
		if (error == SUCCESS) {
			call LowPowerListening.setLocalWakeupInterval(LPL_DEF_LOCAL_WAKEUP);
			call SendTimer.startPeriodic(SEND_PERIOD);
			call CheckTimer.startPeriodic(CHECK_PERIOD);
		}
	}
	event void AMControl.stopDone(error_t error) {}


	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
		buffer_entry_t* entry = NULL;
		led1Blink(BLINK_ON_TIME);

		switch (((uint8_t*)payload)[0]) {
			//case MSG_REQ_THERMOMETER:
			//	force_reading = TRUE;
			//	measure();
			//	break;
			
			case MSG_THERMOMETER:
				entry = call OutPool.get();
				if (entry != NULL) {
					memcpy(entry->data, payload, len);
					entry->len = len;

					call OutQueue.enqueue(entry);
					post SendToSerial();
				}
				break;
		}
		return msg;
	}
	
	uint8_t* rx_data;
	uint8_t rx_len;
	async event void SerialCom.receive(uint8_t* data, uint8_t len) {
		atomic {
			rx_data = data;
			rx_len = len;
		}
		post received();
	}

	task void received() {
		uint8_t* data;
		uint8_t len;
		req_thermometer_msg_t* msg = NULL;
		atomic {
			data = rx_data;
			len = rx_len;
		}

		if (((uint8_t*)data)[0] == MSG_REQ_THERMOMETER) {
			force_reading = TRUE;
			measure();

			// request also from node
			msg = (req_thermometer_msg_t*)call Packet.getPayload(&packet, sizeof(req_thermometer_msg_t));
			msg->header = MSG_REQ_THERMOMETER;

			call LowPowerListening.setRemoteWakeupInterval(&packet, LPL_DEF_REMOTE_WAKEUP);
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(thermometer_msg_t)) == SUCCESS) {
				busy = TRUE;
	      	}
		}
	}
	
	event void AMSend.sendDone(message_t* msg, error_t error) {
		led0Blink(BLINK_ON_TIME);
		busy = FALSE;
	}

    //----------------------------------------------------------------------------
    // Measure
    //----------------------------------------------------------------------------
    event void SendTimer.fired() {
    	force_reading = TRUE;
		measure();
	}

    event void CheckTimer.fired() {
		measure();
	}

	void measure() {
		call SensorPower.makeOutput();
		call SensorPower.set();
		call PowerDelayTimer.startOneShot(POWER_ON_DELAY);

	}
	event void PowerDelayTimer.fired() {
		call Temperature.read();
		#warning light is not read
		//call Light.read();
	}

	task void measureDone() {
		if (temp_done) {
			buffer_entry_t* entry = call OutPool.get();

			call SensorPower.clr();
			temp_done = FALSE;
			light_done = FALSE;
			
			if (entry != NULL) {
				thermometer_msg_t* msg = (thermometer_msg_t*)(entry->data);
				entry->len = sizeof(thermometer_msg_t);
				msg->header = MSG_THERMOMETER;
				msg->addr = SERIAL_ADDR_BASE;
				msg->temp = temp;
				msg->light = light;

				call OutQueue.enqueue(entry);
				post SendToSerial();
			}
		}
		else {
			post measureDone();
		}
	}
	
	task void SendToSerial() {
		if (call OutQueue.empty()) {
			return;
		}
		else {
			if (!busy) {
				buffer_entry_t* entry = call OutQueue.dequeue();

				if (call SerialCom.send((uint8_t*)entry->data, entry->len) == SUCCESS) {
					serialbusy = TRUE;
				}
			}
			else {
				post SendToSerial();
			}
		}
	}

	async event void SerialCom.sendDone(uint8_t* buf, error_t error) {
		led0Blink(BLINK_ON_TIME);
		call OutPool.put((buffer_entry_t*)(buf-offsetof(buffer_entry_t, data)));
		call SyncTimer.startOneShot(SERIAL_SYNC_TIME); // mbed could sync packets if there is long delays between them
		serialbusy = FALSE;
	}

	event void SyncTimer.fired() {
		post SendToSerial();
	}

    event void Temperature.readDone(int32_t value, int32_t exponent, uint8_t errorCode) {
		// send packet only if there is diff with last measurement
		led2Blink(BLINK_ON_TIME);
		if (temp - value >= 6 || temp - value <= -6) {
			temp_done = TRUE;
			post measureDone();
		}
		else if (force_reading) {
			temp_done = TRUE;
			force_reading = FALSE;
			post measureDone();
		}
		temp = value;
	}

	event void Light.readDone(int32_t value, int32_t exponent, uint8_t errorCode) {
		light_done = TRUE;
		light = value;
		post measureDone();
	}
	
	//event void Battery.readDone(error_t result, uint16_t val) {
		
	//}
}
