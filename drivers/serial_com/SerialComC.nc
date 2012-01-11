
configuration SerialComC {
    provides interface SerialCom;
    provides interface StdControl;
}

implementation {
    components SerialComP;
    SerialCom = SerialComP;
    StdControl = SerialComP;
    
    components HplAtm128UartC, PlatformC;
    SerialComP.HplUartTxControl -> HplAtm128UartC.Uart0TxControl;
    SerialComP.HplUartRxControl -> HplAtm128UartC.Uart0RxControl;
    SerialComP.HplUart          -> HplAtm128UartC.HplUart0;
    SerialComP.Atm128Calibrate  -> PlatformC;

    components new TimerMilliC() as Timeout;
    SerialComP.Timeout -> Timeout;
}
