/*
Processing pipeline for the digital thermometer.
Digital thermometer reads off temperature from temperature sensor with I2C interface
and transmits it to PC over UART.

Additionally PC can write data to / or read from temperature sensor by 
sending an instruction over UART to FPGA. All operations on ADT7420 temp
sensor are implemented in terms of reads/writes.

Instruction from PC must come in the form of the data packet:
- Start Byte - all 1's
- Operation Byte: operation to be performed (read 1 byte, read 2 bytes, 
write 1 byte, write 2 bytes)
-(Optional) Data Byte 1: Byte/LSB to be written to temperature register
-(Optional) Data Byte 2: Byte/MSB to be written to temperature register
-Stop Byte: 8-bit signal all bits high to indicate end of instruction.

These bytes correspond to characters typed in sequentially on PC side, with
the characters typed in being processed by a  C++ program, and the
necessary byte sent over UART to FPGA.

Should user delay for 10 seconds in typing in instruction info,then
the instruction will be discarded. Should user, somehow, type in too many instructions
at once, then an LED(may implement a sound ping later) will flash, telling the user
to retype the instruction. Instruction typed in during LED flash will be discarded.
Thus user should retype the instruction as soon as LED turns on(or sound pings)

Once all necessary instruction bytes are received, the data is buffered in a FIFO buffer.
The instruction at the top of FIFO stack is read asynchronously and should the I2C
controller be available for transmission, then it's data is passed onto the
I2C controller and it's spot on the buffer cleared for another instruction.

If there is no instruction waiting for the I2C buffer then by default a 2-byte temperature
read is requested.

The I2C controller, with the instruction data, carries out the relevant operation, 
by communicating with the temp sensor. Once complete, the I2C controller 
passes on the instruction's data and info{data read from temp sensor, 
whether instruction is default mode or from PC, register address to which instruction 
was addressed, operation performed, failure/success on operation} to the next pipeline
stage, where the info and data are buffered if and only if the instruction was sent by PC.

Default mode instructions aren't buffered since user of digital thermometer 
is only interested in current temperature not temperature of some past time.  
Thus default mode instructions immediately request transmission to PC 
and if UART transmitter is unavailable the data is lost.

Once buffered, the instructions are read asynchronously from buffer in 
FIFO manner and if UART transmitter is available then 
the data is passed onto next pipeline stage and buffer entry cleared out.

If buffers become full, a control signal is asserted 
that stops the I2C controller from processing any new instructions 
and by extension, prevents the instruction from being accidentally 
cleared out from the UART to I2C buffers.

On PC side, the transmission packet is analyzed and the 
results and details of the  instructions are displayed on
the console.

*/



module temp_sensor(input logic clk,reset,
				   input logic tx, //Data bit from PC over UART
				   output logic rx, //Data bit transmitted to PC over UART.
				  
				   /*If UART to I2C controller instruction queue is full
				   signal to user to stop sending instructions*/
				   output logic[3:0] stop_typing,
				   
				   /*If user delays for 10 seconds in typing out instruction
				   signal to user to retype instruction in its entirety*/
				   output logic[3:0] time_out,
				   
				   output wire scl, 
				   inout wire sda);
				  
				   logic sample_tick; 	   
				   baud_rate_generator #(.SYS_FREQ(100000000),.BAUD_RATE(38400))
				                                baudgen(.*);
				   
				   logic rx_done_tick_next,rx_done_tick;
				   logic received_byte_next, received_byte;	    
				   uart_rx uart_receiver(.*,
				    	    			  .rx_done_tick(rx_done_tick_next),
				    	    			  .received_byte(received_byte_next));
				    	    
				   //UART - UART-I2C BRIDGE INTERFACE REGISTER
				   always_ff @(posedge clk)
				        if(reset) begin
				    	   rx_done_tick <= '0;
				    	   received_byte <= '0;
				    	end
				    	    	
				    	else begin
				    	   rx_done_tick <= rx_done_tick_next;
				    	   received_byte <= received_byte_next;
				    	end
				    	
				   logic buffers_full,buffers_full_reg; 
				   logic[15:0] wr_data,wr_data_reg; 
				   logic[7:0] mode,mode_reg; 
				   logic wr_addrbuffer,wr_opbuffer,wr_databuffer1;
				   logic wr_databuffer2;
				   logic wr_addrbuffer_reg,wr_opbuffer_reg,wr_databuffer1_reg;
				   logic wr_databuffer2_reg;  
				   logic[7:0] addr_pointer,addr_pointer_reg;

                   logic times_up,times_up_next;
                   
                   /*Register between time-out detection
                   and time_out alert system*/
                   always_ff @(posedge clk) begin
                        if(reset) begin
                            times_up <= '0;
                        end
                        
                        else begin
                            times_up <= times_up_next;
                        end
                   end
				   
				   uart_i2c_tramsmitter #(.SYS_FREQ(100000000),.PERIOD(10)) 
				                        uart_i2c_bridge(.*,
				                                        .time_out(times_up_next));
				   
				   
				   /*Led flasher when instruction queue is full*/
				   led_flasher #(.SYS_FREQ(100000000),.PERIOD(20))
				                   interrupt_mod1(.*,
				                                  .control(buffers_full),
				                                  .led_on(stop_typing));
				   
				    	    	
				   
				   /*Led flasher when system times out*/
				   led_flasher #(.SYS_FREQ(100000000),.PERIOD(20))
				                   interrupt_mod2(.*,
				                                  .control(times_up),
				                                  .led_on(time_out));
				   	    	
				   //UART-I2C TRANSMITTER TO ARBITER INTERFACE REGISTER
				   always_ff @(posedge clk)
				        if(reset) begin
				    	   wr_addrbuffer_reg <= '0;
				    	   wr_databuffer1_reg <= '0;
				    	   wr_databuffer2_reg <= '0;
				    	   wr_opbuffer_reg <= '0;
				    	   addr_pointer_reg <= '0;
				    	   mode_reg <= '0;
				    	   wr_data_reg <= '0;
				    	   
				    	   /*Synchrononize the signal indicating
				    	   full uart-i2c buffers*/
				    	   buffers_full <= '0;
				    	end
				    	                
				    	else begin
				    	   wr_addrbuffer_reg <= wr_addrbuffer;
				    	   wr_databuffer1_reg <= wr_databuffer1;
				    	   wr_databuffer2_reg <= wr_databuffer2;
				    	   wr_opbuffer_reg <= wr_opbuffer;
				    	   addr_pointer_reg <= addr_pointer;
				    	   wr_data_reg <= wr_data;
				    	   mode_reg <= mode;
				    	   
				    	   /*We pass buffers_full signal through
				    	   a register with input from arbiter stage
				    	   and register output on uart to i2c stage*/
				    	   buffers_full <= buffers_full_reg;
				    	end
				    	
				    	
				   logic master_free,master_free_reg; //Indicates controller is ready to initiate communication
				   logic[15:0] i2c_data;
				   logic[7:0] i2c_address,i2c_mode;
				   logic[1:0] valid_instr; 
				   	
				   uart_i2c_arbiter(.*,
				                    .buffers_full(buffers_full_reg),
				                    .i2c_ready(master_free),
				                    .wr_data(wr_data_reg),
				                    .wr_addrbuffer(wr_addrbuffer_reg),
				                    .wr_databuffer1(wr_databuffer1_reg),
				                    .wr_databuffer2(wr_databuffer2_reg),
				                    .wr_opbuffer(wr_opbuffer_reg),
				                    .addr_pointer(addr_pointer_reg),
				                    .mode(mode_reg));
				    	                
				   logic[3:0] fail_signals_next, fail_signals_reg;
				   logic i2c_ready_reg, i2c_ready_next;
				   logic full_i2cbuffer, full_i2cbuffer_reg;
				   
				   
				   logic[6:0] failure_signal, failure_signal_reg;//Indicates read/write failure
				 
				   /*Info for completed instruction to be passed onto next pipeline
				   stage*/
				   logic i2c_data_rdy, i2c_data_rdy_reg;
				   logic[1:0] i2c_valid_instr, i2c_valid_instr_reg;
				   logic[15:0] i2c_retrieved_data, i2c_retrieved_data_reg;
				   logic[7:0] i2c_op_info, i2c_op_info_reg;
				   logic[7:0] i2c_instr_address, i2c_instr_address_reg;
				   
				   /*model of pullup resistor on sda
				   and scl line.
				   required for proper simulation*/
	               assign (pull1,strong0) sda = 1'b1;
	               
	               assign(pull1,strong0) scl = 1'b1;
	               
	               //Control Register In Between I2C controller and UART-I2C stage
	               always_ff @(posedge clk) begin
	                   if(reset) begin
	                       master_free <= '0;
	                   end
	                   
	                   else begin
	                       master_free <= master_free_reg;
	                   end
	               end
				  
				   i2cmaster #(.SYS_CLK_FREQ(100000000),.SCL_FREQ(200000))
				             i2ccontroller(.*,
				                           .master_free(master_free_reg),
				                           .sda(sda),
				                           .scl(scl),
				    	    			   .full_i2cbuffer(full_i2cbuffer_reg),
				    	    			   .wr_data(i2c_data),
				    	    			   .mode(i2c_mode),
				    	    			   .reg_address(i2c_address));
	    	
				   //Register in between I2C controller and I2C - UART ARBITER STAGE
				   always_ff @(posedge clk) 
				        if(reset) begin
				    	   i2c_retrieved_data_reg <= '0;
				    	   failure_signal_reg <= '0;
				    	   i2c_instr_address_reg <= '0;
				    	   i2c_op_info_reg <= '0;
				    	   i2c_valid_instr_reg <= '0;
				    	   i2c_data_rdy_reg <= '0;
				    	   
				    	   /*Control signal passed from
				    	   arbiter stage to I2C controller to indicate
				    	   that buffers aren't full*/
				    	   full_i2cbuffer_reg <= '0;
				    	end
				    	    		
				    	else begin
				    	   i2c_retrieved_data_reg <= i2c_retrieved_data;
				    	   failure_signal_reg <= failure_signal;
				    	   i2c_data_rdy_reg <= i2c_data_rdy;
				    	   i2c_valid_instr_reg <= i2c_valid_instr;
				    	   i2c_instr_address_reg <= i2c_instr_address;
				    	   i2c_op_info_reg <= i2c_op_info;
				    	   
				    	   full_i2cbuffer_reg <= full_i2cbuffer;
				    	end
				    	    		
				   //I2C-uart arbitrer. Determine whether UART transmission can take place depending on data info. Results asked for take priority.
				   logic[15:0] toPC_data;
				   logic[7:0] toPC_address;
				   logic[7:0] toPC_mode;
				   logic data_ready;
				   logic tx_complete, tx_complete_next;
				   logic empty_i2cbuffer;
				   
				   /*Control register that indicates UART transmission
				   completion.*/
				   always_ff @(posedge clk) begin
				        if(reset) begin
				            tx_complete <= '0;
				        end
				        
				        else begin
				            tx_complete <= tx_complete_next;
				        end
				   end
				   
				   
				   i2c_uart_arbiter i2c_to_uart (.*, 
				     							 .i2c_retrieved_data(i2c_retrieved_data_reg),
				     							 .i2c_instr_address(i2c_instr_address_reg),
				     							 .i2c_op_info(i2c_op_info_reg),
				     							 .i2c_valid_instr(i2c_valid_instr_reg),
				     							 .failure_signal(failure_signal_reg),
				     							 .i2c_data_rdy(i2c_data_rdy_reg));
				   //i2c to uart arbiter has register for passing data to i2c-uart bridge built in. Thus we need only make direct connections
				   
				   
				   
				     	
				    	
				  logic[7:0] tx_byte, tx_byte_next;
				  logic tx_start, tx_start_next; //Get UART to start transmission 
				  logic tx_done_tick, tx_done_tick_next; //UART indication that it finished sending the byte
				    	
				  //For your own sake have internal registers that store the necessary data bytes.
				  i2c_uart_transmitter i2c_uart_bridge (.*,
				                                        .tx_complete(tx_complete_next),
				    	    							.tx_start(tx_start_next),
				    	    							.data_byte(tx_byte_next));
				    	    									  
				    	
				  //Intermediary register
				  always_ff @(posedge clk)
				        if(reset) begin
				            tx_byte <= '0;
				    	    tx_start <= '0;
				    		tx_done_tick <= '0;
				    	end
				    		
				    	else begin
				    	   tx_byte <= tx_byte_next;
				    	   tx_start <= tx_start_next;
				    	   tx_done_tick <= tx_done_tick_next;
				    	end
				    		
				    	
				  uart_tx uart_transmitter(.*,
				                           .tx(rx),
				    					   .data_byte(tx_byte),
				    					   .tx_start(tx_start),
				    					   .tx_done_tick(tx_done_tick_next));
				    							 
				    	
endmodule  
