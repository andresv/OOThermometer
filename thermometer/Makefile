COMPONENT=ThermometerAppC

CFLAGS += -I../drivers/sensor

CFLAGS += -DPLATFORM_BAUDRATE=115200L

CFLAGS += -DLOW_POWER_LISTENING
CFLAGS += -DLPL_DEF_REMOTE_WAKEUP=5000
CFLAGS += -DLPL_DEF_LOCAL_WAKEUP=5000

CFLAGS += -DRF230_DEF_CHANNEL=12
CFLAGS += -DRF230_DEF_RFPOWER=0


include $(MAKERULES)
