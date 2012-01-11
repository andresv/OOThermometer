
configuration LightC {
    provides interface OOSensorRead;
}

implementation {
    components new AdcReadClientC(), LightP;

    LightP.ADCRead -> AdcReadClientC;
    AdcReadClientC.Atm128AdcConfig -> LightP;

    OOSensorRead = LightP;
 
}
