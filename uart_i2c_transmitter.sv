/*Bridge in between UART core and I2C controller that handles instructions
from UART Core. UART data packet comes in form of 
-Start Byte : indicates incoming instruction from PC
-Address Byte : indicates the register of temp sensor to which instruction addresses
-Operation Byte : indicates the operation to be performed
-Optional Data Bytes(1 or 2) : Data bytes to be written to registers in case of writes
-Stop Bytes : terminates the instruction

Start Byte and Stop Byte are all 1's.
*/

module uart_i2c_tramsmitter (input logic clk,reset,
							    input logic rx_done_tick,
							    input logic[7:0] received_byte,
							    input logic buffers_full, //any buffer full signal will do.
							    output logic[15:0] wr_data,
							    output logic[2:0] mode,
							    output logic initiate,
							    output logic waiting, //waiting for your instruction
							    output logic wr_addrbuffer,wr_opbuffer,wr_databuffer1,wr_databuffer2,wr_validbuffer,
							    output logic time_out,
							    output logic[7:0] addr_pointer);
							    
							    typedef enum{idle,address,operation,data1,data2,stop} state_type;
							    
							    state_type state, state_next;
							    logic[32:0] count,count_next; 
							    logic[15:0] data_reg, data_next; //holds data byte to be written to temp sensors registers by I2C controller
							    logic[2:0] mode_reg, mode_next; //holds operation mode info for I2C controller
							    logic[7:0] addr_reg, addr_next; //holds address of register to be written to or read from. */
							    
							    
							    
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
								waiting = '0;
								data_next = data_reg;
							    	mode_next = mode_reg;
							    	addr_next = addr_reg; 
							    	time_out = '0;
							    	count_next = count + 1;
							    	timeout_clear = 1'b0;
							    	{wr_addrbuffer, wr_opbuffer, wr _databuffer1, wr_databuffer2,wr_validbuffer}= '0;
							    	
							    	case(state) 
							    		idle: begin
							    			waiting = 1'b1;
							    			//Check for whether buffer is full is performed during this cycle. So start acts as a query into the status of the temp sensor. If buffers are full we clearly indicate this on an LED
							    			if(rx_done_tick && !buffers_full) begin
							    				state_next = (received_byte == '1) ? address : idle ; //Receiving start byte is necessary to initiate transaction. This also helps in the case where buffer was full and the guy using the
							    				//temp sensor thinks they could do whatever they want. Stay stuck in waiting state boo:);
							    				count_next = '0;
							    			end
							    		end
							    		
							    		address: begin
							    			if(rx_done_tick) begin	
							    				state_next = operation;
							    				addr_next = received_byte; //Byte received is address.
							    				count_next = '0;
							    			end
							    			
							    			else if(count == 999999999) begin //If 10seconds is about to pass with no instruction, nothing to clear but indicate time_out
							    				count_next = '0;
							    				state_next = idle;
							    				time_out = 1'b1;
							    			end
							    			
							    		end
							    		
							    		/*Checks to ensure operation is valid given the destination register are made at the software level on PC*/
							    		operation: begin
							    			if(rx_done_tick) begin //Data byte received by UART is the operation byte
							    				mode_next = received_byte[2:0];
							    				count_next ='0;
							    				case(received_byte[2:0])
							    					3'b010,3'b011: begin
							    						state_next = data1;
							    					end
							    					
							    					default:  begin
							    						state_next = stop;
							    					end
							    				endcase
							    			end
							    			
							    			else if(count == 999999999) begin //If 10seconds is about to pass with no instruction
							    				count_next = '0;
							    				state_next = idle;
							    				time_out = 1'b1;
							    			end
							    			
							    		end
							    		
							    		/*Transmit the first byte of data*/
							    		data1: begin
							    			if(rx_done_tick) begin
							    				data_next[7:0] = received_byte;
							    				state_next = (mode_reg == 3'b011) ? data2 : stop;
							    				count_next = '0;
							    			end
							    			
							    			else if(count == 999999999) begin //If 10seconds is about to pass with no instruction
							    				count_next = '0;
							    				state_next = idle;
							    				time_out = 1'b1;
							    			end
							    			
							    		end
							    		
							    		/*Transmitting the second  byte of data*/
							    		data2:begin
							    			if(rx_done_tick) begin
							    				data_next[15:8] = received_byte;
							    				state_next = stop;
							    				count_next = '0;
							    			
							    			end
							    			
							    			else if(count == 999999999) begin //If 10seconds is about to pass with no instruction
							    				count_next = '0;
							    				state_next = idle;
							    				time_out = 1'b1;
							    			end
							    		end
							    		
							    		/*Receive the stop_byte to signal that we can start the I2C transaction. If no stop byte received
							    		we wait for it. (Might implement a time out feature whereby absence of command in timely manner 
							    		aborts the transaction and resets thermometer to continuous operation mode where it just senses temperature) */
							    		stop: begin
							    			if(rx_done_tick) begin
							    				state_next = (received_byte == '1) ? idle:stop;
							    				initiate = (received_byte == '1);
							    				/*We only write to instruction queue when transmission is completed*/
							    				wr_validbuffer = 1'b1;
							    				wr_addrbuffer = 1'b1;
							    				wr_databuffer2 = 1'b1;
							    				wr_databuffer1 = 1'b1;
							    				wr_opbuffer = 1'b1;
							    				count_next = '0;
							    			end
							    			
							    			else if(count == 999999999) begin //If 10seconds is about to pass with no instruction, we clear all buffers written
							    				count_next = '0;
							    				state_next = idle;
							    				time_out = 1'b1;
							    			end
							    		end
							    	endcase
							end
endmodule
							    		
							    		
							    						
							    		
		
