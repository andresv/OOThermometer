#include "Thermometer.h"

configuration ThermometerAppC { }
implementation  {

 	components ThermometerC as App, LedsC, MainC;
    App.Boot -> MainC.Boot;
    App.Leds -> LedsC;

    components ActiveMessageC;
    components new AMSenderC(AM_RADIO_MESSAGE);
    components new AMReceiverC(AM_RADIO_MESSAGE);
    App.AMSend -> AMSenderC;
    App.Packet -> AMSenderC;
    App.Receive -> AMReceiverC;
    App.AMControl -> ActiveMessageC;

    components ActiveMessageC as LplRadio;
    App.LowPowerListening -> LplRadio;

    components new TimerMilliC() as CheckTimer;
    App.CheckTimer -> CheckTimer;
	components new TimerMilliC() as SendTimer;
    App.SendTimer -> SendTimer;

    components new TimerMilliC() as PowerDelayTimer;
    App.PowerDelayTimer -> PowerDelayTimer;
	components new TimerMilliC() as Led0BlinkTimer;
    App.Led0BlinkTimer -> Led0BlinkTimer;
    components new TimerMilliC() as Led2BlinkTimer;
    App.Led2BlinkTimer -> Led2BlinkTimer;

    components HplAtm128GeneralIOC as GeneralIOC;
    App.SensorPower -> GeneralIOC.PortC2;
    components TempC;
    App.Temperature -> TempC;
    components LightC;
    App.Light -> LightC;
}
