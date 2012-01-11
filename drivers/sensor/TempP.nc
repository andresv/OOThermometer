
module TempP @safe() {
    provides interface Atm128AdcConfig;
    provides interface OOSensorRead;

    uses interface Read<uint16_t> as ADCRead;
}

implementation {

    command error_t OOSensorRead.read() {
        return call ADCRead.read();
    }

    event void ADCRead.readDone(error_t result, uint16_t data) {
        int32_t adc;
        int32_t temp;
        // Reference ARef +3300mV? == 1023
        // adc = (3300L * (int32_t)data) / 1024;
        adc = (3300L * (int32_t)data) / 1024;
        // 20 C=2365 mV, -16,3mV/C
        // T = (-163*adc + 385695) / 10
        temp = (-6135L * adc + 16509202L) / 10000;
        
        signal OOSensorRead.readDone(temp, -1, 0);
    }

    //----------------------------------------------------------------------------
    // ADC config
    //----------------------------------------------------------------------------
    async command uint8_t Atm128AdcConfig.getChannel() {
        return ATM128_ADC_SNGL_ADC1;
    }

    async command uint8_t Atm128AdcConfig.getRefVoltage() {
        return ATM128_ADC_VREF_OFF;
    }

    async command uint8_t Atm128AdcConfig.getPrescaler() {
        return ATM128_ADC_PRESCALE;
    }
}
