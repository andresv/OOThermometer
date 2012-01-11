
configuration TempC {
	provides interface OOSensorRead;
}

implementation {
    components new AdcReadClientC(), TempP;

    TempP.ADCRead -> AdcReadClientC;
    AdcReadClientC.Atm128AdcConfig -> TempP;

    OOSensorRead = TempP;
 
}
