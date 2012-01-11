#include "Thermometer.h"
#include "ThermometerBase.h"

configuration ThermometerBaseAppC { }
implementation  {

 	components ThermometerBaseC as App, LedsC, MainC;
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
    components new TimerMilliC() as Led1BlinkTimer;
    App.Led1BlinkTimer -> Led1BlinkTimer;
    components new TimerMilliC() as Led2BlinkTimer;
    App.Led2BlinkTimer -> Led2BlinkTimer;

    components new TimerMilliC() as SyncTimer;
    App.SyncTimer -> SyncTimer;

    components HplAtm128GeneralIOC as GeneralIOC;
    App.SensorPower -> GeneralIOC.PortC2;
    components TempC;
    App.Temperature -> TempC;
    components LightC;
    App.Light -> LightC;

    components SerialComC;
    App.SerialCom -> SerialComC;
    App.SerialControl -> SerialComC;

    components new PoolC(buffer_entry_t, 2) as OutPoolC;
    App.OutPool -> OutPoolC;
    components new QueueC(buffer_entry_t*, 2) as OutQueueC;
    App.OutQueue -> OutQueueC;

}
