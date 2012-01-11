interface OOSensorRead {

    command error_t read();

    event void readDone(int32_t value, int32_t exponent, uint8_t errorCode);

}
