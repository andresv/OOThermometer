#include "math.h"

module LightP @safe() {
    provides interface Atm128AdcConfig;
    provides interface OOSensorRead;

    uses interface Read<uint16_t> as ADCRead;
}
implementation {

    command error_t OOSensorRead.read() {
        return call ADCRead.read();
    }

    event void ADCRead.readDone(error_t result, uint16_t data) {
        uint32_t adc;
        uint32_t light;
        double t = 4. / (2800. - 560.);
        // Reference ARef +3300mV? == 1023
        adc = (3300L * (uint32_t)data) / 1024;
        // linear from 560mV=10lux to 2800mV= 100000lux
        // L = (446.38392857142854*adc -249875) / 10
        // light = (446384L * adc - 249875000L) / 10000;
        light = pow(10., (adc * t));
    
        signal OOSensorRead.readDone(light, 0, 0);
    }

    //----------------------------------------------------------------------------
    // ADC config
    //----------------------------------------------------------------------------
    async command uint8_t Atm128AdcConfig.getChannel() {
        return ATM128_ADC_SNGL_ADC3;
    }

    async command uint8_t Atm128AdcConfig.getRefVoltage() {
        return ATM128_ADC_VREF_OFF;
    }

    async command uint8_t Atm128AdcConfig.getPrescaler() {
        return ATM128_ADC_PRESCALE;
    }
}
