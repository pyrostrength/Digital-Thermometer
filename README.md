Digital Thermometer Project involves using a PC, FPGA and ADT7420 temperature sensor to
make a thermometer. ADT7420 temperature sensor measures the ambient temperature and
sends the data over I2C to FPGA where a processing pipeline sends the data to PC over\
UART. PC can send write/read requests to the registers in the temperature sensor over UART.

On PC end, to make a read/write request, user types the instruction info sequentially using keyboard
characters. The keyboard characters typed in are then converted into bytes and sent to FPGA over UART.

A complete instruction requires:
- A start byte - A byte with all bits high. Signals start of transmission.
                 Corresponds to typing in letter 'S' on PC
- Register Address Byte - Address of register to which operation is addressed
                          Corresponds to typing in specific characters corresponding to specific
                          registers in the temperature sensor.
- Operation Byte - Operation to be performed. All relevant functions of the ADT7420 temperature
                   sensor are implemented in terms of reads/writes. Thus possible operations
                   are read 1 byte, read 2 bytes, write 1 byte and write 2 bytes.
                   Corresponds to typing in specific characters on PC side
- Optional Data Byte 1 - Data byte/ Least Significant Byte to write to temp sensor registers
                        if operation is a write operation. Corresponds to typing in a number
                        on PC end.
- Optional Data Byte 2 - Data byte/ Least Significant Byte to write to temp sensor registers
                        if operation is a write operation. Corresponds to typing in a number
                        on PC end.
- Stop Byte - A byte with all bits high to signal end of transmission.
              Corresponds to typing in the letter E on PC end

If instruction isn't typed in as required then instruction is discarded. If user delays for too
long then instruction is discarded - wait time can be specified through the PERIOD parameter
of the UART to I2C transmitter module. If user can, somehow, send too many instruction for pipeline
to handle, such that instruction queue fills up, then an LED will flash and user is required
to retype all instructions written during the flashing period.

Note: the timeout feature will be implemented on the FPGA side and on PC side. That way, a user
will always notice the timeout especially when the LEDs on the FPGA are tiny. However, user will
have to observe FPGA led's to make sure they aren't sending in too many instructions at once.

Once relevant operation has been carried out by I2C controller in the processing pipeline



  
