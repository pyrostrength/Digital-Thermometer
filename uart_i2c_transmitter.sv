/*
Examines data bytes coming in from UART core 
and if data packet matches that of an instruction
initiates buffering of instruction's data.

For a complete instruction from PC, UART data packet is in form:
-Start Byte : indicates incoming instruction from PC
-Address Byte : indicates the register of temp sensor to which instruction addresses
-Operation Byte : indicates the operation to be performed
-Optional Data Bytes(1 or 2) : Data bytes to be written to registers in case of writes
-Stop Bytes : terminates the instruction

Start Byte and Stop Byte are all 1's.

A timeout feature has been added in case too long of a delay(specified
by user of the module through PERIOD and SYS_CLK_FREQ parameters)
in between sending instruction info occurs. User will have to retype entire
instruction and will be instructed to do so on software side by PC.

If buffers are full and LED will flash for a certain time period, 
during which user is required to not send in any new instruction. 
Ample time should be chosen to allow instruction queue to open up 
and to give user ample time to see LED and respond to it.
//Might add a sound ping. -- i think i'll add a sound ping to the FPGA
so I'd need a signal generator.
*/

module uart_i2c_tramsmitter(input logic clk,reset,
							input logic rx_done_tick, //Transmission of byte was complete
							input logic[7:0] received_byte, //Byte received from PC.
							input logic buffers_full, //if buffers are full we cannot queue the instruction. User must wait then repeat the instruction on PC end
							output logic[15:0] wr_data, //Data to be written to I2C temperature sensor's registers.
							output logic[7:0] mode, // Read 1 byte/2 bytes or write 1 byte or 2 bytes
							output logic stop_send, //Instructs user to not send an instruction
							output logic wr_addrbuffer,wr_opbuffer,wr_databuffer1,wr_databuffer2,wr_validbuffer, //Queue instruction information in their respective buffers
							output logic time_out, //Repeat the entire instruction if user delays more than 10 seconds in completely specifying their wants.
							output logic[7:0] addr_pointer); //Register on I2C temperature sensor to which operation is addressed.
							
							parameter SYS_FREQ = 100000000;
                            parameter PERIOD = 20;
                       
                            localparam int MAX = SYS_FREQ * PERIOD;
                            logic[31:0] max_count;
                            
							typedef enum{idle,address,operation,data1,data2,stop} state_type;
							    
							state_type state, state_next;
							logic[32:0] count,count_next;  //Time-out timer counter
							logic[15:0] data_reg, data_next; //Holds data byte to be written to temp sensors registers by I2C controller
							logic[7:0] mode_reg, mode_next; //Holds operation to be performed by I2C controller
							logic[7:0] addr_reg, addr_next; //Holds address of register to be written to or read from. */
    
							//Timeout counter - if 10 seconds elapses without any input from PC then instruction is deleted
							always_ff @(posedge clk,posedge reset) begin
							     if(reset) begin
							         count <= '0;
							     end
							    	
							     else begin
							         count <= count_next;
							     end
							end
							    
							always_ff @(posedge clk,posedge reset)
							     if(reset) begin
							         state <= idle;
							    	 data_reg <= '0;
							    	 mode_reg <= '0;
							    	 addr_reg <= '0;
							     end
							    	
							     else begin
							         state <= state_next;
							    	 data_reg <= data_next;
							    	 mode_reg <= mode_next;
							    	 addr_reg <= addr_next;
							     end
							
							
							assign mode = mode_reg;
							assign addrpointer = addr_reg;
							assign wr_data = data_reg;
							
							always_comb begin
								state_next = state;
								stop_send = '0;
								data_next = data_reg;
							    mode_next = mode_reg;
							    addr_next = addr_reg; 
							    time_out = '0;
							    count_next = count + 1;
							    {wr_addrbuffer, wr_opbuffer, wr_databuffer1, wr_databuffer2,wr_validbuffer}= '0;
							    	
							    case(state) 
							    /*Await for new instructions from PC. Before transmitting the 
							    instructions we check if to see if instruction queue is full. 
							    If full we signal that the user should repeat the transaction 
							    */
							         idle: begin
							    	    stop_send = (buffers_full); //Signal to user to stop sending instructions
							    		if(rx_done_tick && !buffers_full) begin
							    		   state_next = (received_byte == '1) ? address : idle ; //Receiving start byte is necessary to initiate transaction. 
							    		   count_next = '0; //Reset timeout counter.
							    		end
							    	 end
							    		
							    	 address: begin
							    	    if(rx_done_tick) begin	
							    		   state_next = operation;
							    		   addr_next = received_byte; //Byte received is address byte
							    		   count_next = '0;
							    		end
							    			
							    		else if(count == max_count - 1) begin 
							    		   count_next = '0;
							    		   state_next = idle;
							    		   time_out = 1'b1;
							    		end
							    			
							    	 end
							    		
							    	operation: begin
							    	    if(rx_done_tick) begin //Data byte received by UART is the operation byte
							    		   mode_next = received_byte;
							    		   count_next ='0;
							    		   case(received_byte[3:0])
							    		       4'b0100,4'b1000: begin
							    			      state_next = data1; //Need to await for the data bytes to write to the registers of the temperature sensors
							    			   end
							    	
							    			   default:  begin
							    			      state_next = stop;
							    			   end
							    		   endcase
							    		end
							    			
							    		else if(count == max_count - 1) begin 
							    		   count_next = '0;
							    		   state_next = idle;
							    		   time_out = 1'b1;
							    		end
							    			
							    	end
							    		
							    	/*Receiving first byte of data to be written*/
							    	data1: begin
							    	    if(rx_done_tick) begin
							    		   data_next[7:0] = received_byte;
							    		   state_next = (mode_reg == 3'b011) ? data2 : stop;
							    		   count_next = '0;
							    		end
							    			
							    		else if(count == max_count - 1) begin 
							    		   count_next = '0;
							    		   state_next = idle;
							    		   time_out = 1'b1;
							    		end	
							    	end
							    		
							    	/*Receiving the  second  byte of data to be written*/
							    	data2:begin
							    	    if(rx_done_tick) begin
							    		   data_next[15:8] = received_byte;
							    		   state_next = stop;
							    		   count_next = '0;
							    		end
							    			
							    		else if(count == max_count - 1) begin 
							    		   count_next = '0;
							    		   state_next = idle;
							    		   time_out = 1'b1;
							    		end
							    	end
							    		
							    	/*Receive the stop_byte to indicate all necessary data received from UART*/
							    	stop: begin
							    	    if(rx_done_tick) begin
							    		   state_next = (received_byte == '1) ? idle:stop;
							    		   if(received_byte == '1) begin
							    		       /*We only write to instruction queue 
							    		       when transmission is completed. And */
							    		       wr_validbuffer = 1'b1;
							    		       wr_addrbuffer = 1'b1;
							    		       wr_databuffer2 = 1'b1;
							    		       wr_databuffer1 = 1'b1;
							    		       wr_opbuffer = 1'b1;
							    		   end
							    		   count_next = '0;
							    		 end
							    			
							    		 else if(count == max_count - 1) begin 
							    		   count_next = '0;
							    		   state_next = idle;
							    		   time_out = 1'b1;
							    		 end
							    	end
							    endcase
							end 
endmodule
							    		
							    		
							    						
							    		
		
