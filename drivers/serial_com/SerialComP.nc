#include <Atm128Uart.h>

#define RX_BUF_SIZE 100

module SerialComP {
    provides {
    	interface SerialCom;
    	interface StdControl;
    }

    uses {
    	interface StdControl    as HplUartTxControl;
    	interface StdControl    as HplUartRxControl;
    	interface HplAtm128Uart as HplUart;

        interface Timer<TMilli> as Timeout;
        interface Atm128Calibrate;
    }
    
}
implementation {
    
    uint16_t m_timeout;
    uint8_t m_bytes_to_receive;
    uint8_t m_bytes_to_send;

    uint8_t m_rxbuf1[RX_BUF_SIZE];
    uint8_t m_rxbuf2[RX_BUF_SIZE];
    uint8_t* m_rxbuf_p = NULL;
    
    uint8_t* m_tx_buffer = NULL;

    uint8_t bytes_received = 0;
    uint8_t bytes_sended = 0;

    task void startTimeoutTimer();
    void buffer_swap(uint8_t* current);


	command error_t StdControl.start() {
        call HplUart.disableTxIntr();
        call HplUart.disableRxIntr();

        call HplUartTxControl.start();
        call HplUartRxControl.start();

        call HplUart.enableRxIntr();
        call HplUart.enableTxIntr();
           
        return SUCCESS;
    }
    
    command error_t StdControl.stop(){
        call HplUart.disableTxIntr();
        call HplUart.disableRxIntr();

        call HplUartTxControl.stop();
        call HplUartRxControl.stop();

        return SUCCESS;
    }

	command error_t SerialCom.setup(uint16_t timeout, uint8_t bytes) {
        m_timeout = timeout;
        atomic { 
            m_bytes_to_receive = bytes;
            m_rxbuf_p = m_rxbuf1;
        }
 
		return SUCCESS;
	}

	async command error_t SerialCom.send(uint8_t* data, uint8_t len) {
        atomic {
            m_tx_buffer = data;
            m_bytes_to_send = len;
            bytes_sended = 0;
    	   call HplUart.tx(m_tx_buffer[0]);
        }
    	return SUCCESS;
    }

    async event void HplUart.txDone() {
        atomic {
            bytes_sended++;
            if (bytes_sended == m_bytes_to_send) {
                signal SerialCom.sendDone(m_tx_buffer, SUCCESS);
            }
            else {
                call HplUart.tx(m_tx_buffer[bytes_sended]);
            }
        }
    }

	async event void HplUart.rxDone(uint8_t data) {
		post startTimeoutTimer();
        atomic {
            m_rxbuf_p[bytes_received] = data;
            
            bytes_received++;
            if (bytes_received == m_bytes_to_receive) {
                signal SerialCom.receive(m_rxbuf_p, bytes_received);
                buffer_swap(m_rxbuf_p);
                bytes_received = 0;
            }
        }
	}

    void buffer_swap(uint8_t* current) {
        if (current == m_rxbuf1)
            m_rxbuf_p = m_rxbuf2;
        else
            m_rxbuf_p = m_rxbuf1;
    }

    task void startTimeoutTimer() {
        call Timeout.startOneShot(m_timeout);
    }

    event void Timeout.fired() {
        atomic {
            signal SerialCom.receive(m_rxbuf_p, bytes_received);
            buffer_swap(m_rxbuf_p);
            bytes_received = 0;
        }
    }
}
