Using a PC, FPGA and ADT7420 temperature sensor, I've made a digital thermometer. The
ADT7420 temperature sensor is connected to FPGA over PMOD port and measures the ambient temperature.
It sends the data to the FPGA over I2C after which pipeline on the FPGA sends the data to the
PC over UART interface.

Data flow over PC-FPGA UART interface is bidirectional as PC can send write/read requests 
to the temperature sensor - the PC sends the instruction info to FPA over UART then FPGA sends the instruction
to the temperature sensor. 

A valid instruction (FPGA side) requires:
- A start byte - A byte with all bits high to signal start of transmission.
- Register Address Byte - Address of ADT7420 temp sensor register to which operation is addressed. 
- Operation Byte - Operation to be performed. All functions of the ADT7420 temperature
                   sensor are implemented in terms of reads/writes. Thus possible operations
                   are read 1 byte, read 2 bytes, write 1 byte and write 2 bytes.
- Optional Data Byte 1 - Data byte/M.S.Byte for write operation
- Optional Data Byte 2 - Data byte/L.S.Byte to write to temp sensor registers for write operation.
- Stop Byte - A byte with all bits high to signal end of transmission.

A C++ program on PC side ensures that instructions are sent out to FPGA in appropriate format.
Note that for the ADT7420 temp sensor all 9 temperature value registers are read only - the two registers
relevant for project are the temperature value M.S.B register(0x00) and temperature value L.S.B register
(0x01), each of which can be read independently.

Only the configuration register and the software reset register can be written to, with software reset
register being write only. The configuration register sets the various configuration mode for the
I2C temperature sensor including normal mode(in which ADT7420 is continously converting temperature 
and storing in the temperature value registers. More config modes are detailed in ADT7420 temp sensor datasheet,
as well as more info on the available ADT7420's temperature registers.

Thus our C++ program implements read temperature function(1 or 2 bytes), reset(sets temp sensor
into normal mode), sps((sets temp sensor into one-shot mode) and shutdown mode. If user
can somehow send instructions faster than they can be processed then buffer fills and an LED lights
up indicating full buffers. User should repeat their entire instruction sequence for 
good results.

Once relevant operation has been carried out by instruction info such as 
address of temp senosr register which instruction addressed, 
operation performed and retrieved data is sent to back to PC. 
The communication packet for sending an instruction from PC is identical to that of sending it results back to PC and it
includes:
- A start byte
- Register Address Byte
- Operation Byte
- Optional Data Byte 1(in case of reads)
- Optional Data Byte 2(in case of reads)
- Stop Byte

Only minor difference is that the operation byte has flag bits indicating
whether read/write operations were actually carried out.
To be specific, with the transmission of every byte over I2C, an ack bit/
nack bit must be sent by the receiver. If no ack/nack bit is sent by receiver after it
recieves a data byte, we indicate so in the flag bits.

A C++ program analyzes the data sent back over UART and writes the results to a file.


  
