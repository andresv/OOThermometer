#include "Thermometer.h"


#define CHECK_PERIOD 	30*1024UL 		// checks if it should send new temp if time difference is big
#define SEND_PERIOD 	5*60*1024UL 	// this time it is always sent
#define POWER_ON_DELAY 	128
#define BLINK_ON_TIME 	256

module ThermometerC {
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

        interface Timer<TMilli> as CheckTimer;
        interface Timer<TMilli> as SendTimer;
        interface Timer<TMilli> as PowerDelayTimer;
        interface Timer<TMilli> as Led2BlinkTimer;
        interface Timer<TMilli> as Led0BlinkTimer;
	}
}
implementation {

	message_t packet;
	bool busy = FALSE;

	bool temp_done = FALSE;
	int32_t temp = 0;
	bool light_done = FALSE;
	int32_t light = 0;

	bool force_reading = FALSE;

	void measure();
	task void measureDone();

    //----------------------------------------------------------------------------
    // Blink
    //----------------------------------------------------------------------------
	void led2Blink(uint16_t onPeriod) {
        call Leds.led2On();
        call Led2BlinkTimer.startOneShot(onPeriod);
    }
    event void Led2BlinkTimer.fired() { call Leds.led2Off(); }

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
		req_thermometer_msg_t* req = (req_thermometer_msg_t*)msg->data;

		if (((uint8_t*)req)[0] == MSG_REQ_THERMOMETER) {
			force_reading = TRUE;
			measure();
		}
		return msg;
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
			thermometer_msg_t* msg = NULL;
			call SensorPower.clr();
			temp_done = FALSE;
			light_done = FALSE;
			
			msg = (thermometer_msg_t*)call Packet.getPayload(&packet, sizeof(thermometer_msg_t));
			if (msg != NULL) {
				msg->header = MSG_THERMOMETER;
				msg->addr = SERIAL_ADDR_NODE;
				msg->temp = temp;
				msg->light = light;

				call LowPowerListening.setRemoteWakeupInterval(&packet, LPL_DEF_REMOTE_WAKEUP);
				if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(thermometer_msg_t)) == SUCCESS) {
					busy = TRUE;
	      		}
			}
		}
		else {
			post measureDone();
		}
	}

    event void Temperature.readDone(int32_t value, int32_t exponent, uint8_t errorCode) {
		// send packet only if there is diff with last measurement
		//led2Blink(BLINK_ON_TIME);
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
