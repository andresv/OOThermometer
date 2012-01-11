
interface SerialCom {
    /**
    * 	"timeout"    specifies how many ms to wait after last byte if specified number of bytes are still not there
    *	"bytes"	     specifies how many bytes are waited for or timeout.
    */
    command error_t setup(uint16_t timeout, uint8_t bytes);

    /**
    *	"data"	buffer from data is sent out to UART1
    *	"len"	tx data length
    */
    async command error_t send(uint8_t* data, uint8_t len);

    /**
    *  "error"   SUCCESS if byte was sent FAIL otherwise
    */
    async event void sendDone(uint8_t* buf, error_t error);

    /**
    *	"data"	received data
    *	"len"	received data length
    */
    async event void receive(uint8_t* data, uint8_t len);
    
}