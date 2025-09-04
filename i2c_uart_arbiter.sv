/*
Buffers output from I2C module and prepares the
data for transmission
*/

module i2c_uart_arbiter(input logic clk,reset,
                         
                         //Data from I2C controller
						 input logic[15:0] i2c_retrieved_data,
						 input logic[7:0] i2c_instr_address, 
						 input logic[7:0] i2c_op_info,
						 input logic[2:0]i2c_valid_instr,
						 input logic[5:0] failure_signal,
						 input logic i2c_data_rdy, //Has data from I2C been made available?
						 //Data from I2C controller
						 
						 //Control signal indicating UART has transmitted all data bytes
						 input logic tx_complete, 
						 
						 //Signal to UART to initiate new transmission
						 output logic data_ready,
						 //Indicates when i2c buffers are full thus pipeline should stall
						 output logic full_i2cbuffer,
						 output logic empty_i2cbuffer,
						 
						 //Data going out to PC
						 output logic[7:0] toPC_address,
						 output logic[7:0] toPC_mode,
						 output logic[15:0] toPC_data);
						   
						 //Data read from buffers 
						 logic[15:0] buffer_data;
						 logic[5:0] buffer_failure_info;
						 logic[7:0] buffer_mode;
						 logic[7:0] buffer_address;
						 
						 logic data_ready_next;
						 
						 //Data sent to PC 
						 logic[15:0] toPC_data_next;
						 logic[7:0] toPC_mode_next;
						 logic[7:0] toPC_address_next;
						 
						 //Full and empty signals for the buffers
						 logic full_databuffer, full_addressbuffer;
						 logic full_signalsbuffer, full_modebuffer;
						 logic empty_databuffer, empty_addressbuffer;
						 logic empty_signalsbuffer, empty_modebuffer;
						 logic read; //Read signal for the buffers
						 
						 assign full_i2cbuffer = full_addressbuffer;
						 assign empty_i2cbuffer = empty_addressbuffer;
						 /*Only instructions from PC get access to the buffer.
						 Data from default temperature reads can be discarded if
						 UART transmitter is occupied since user is only interested
						 in the temperature at the present time*/
						 assign writebuffer = i2c_data_rdy && (i2c_valid_instr == 2'b11);
						 
						 fifo_buffer #(.DW(15)) data_buffer (.*,
				    	    								 .wr_data(i2c_retrieved_data),
				    	    								 .rd_data(buffer_data),
				    	    								 .full(full_databuffer),
				    	    								 .empty(empty_databuffer),
				    	    								 .write(writebuffer));
				    	 
				    	 fifo_buffer #(.DW(7)) address_buffer (.*,
				    	    								    .wr_data(i2c_instr_address),
				    	    								    .rd_data(buffer_address),
				    	    								    .full(full_addressbuffer),
				    	    								    .empty(empty_addressbuffer),
				    	    								    .write(writebuffer));
				    	 
				    	 fifo_buffer #(.DW(7)) mode_buffer (.*,
				    	    								 .wr_data(i2c_op_info),
				    	    								 .rd_data(buffer_mode),
				    	    								 .full(full_modebuffer),
				    	    								 .empty(empty_modebuffer),
				    	    								 .write(writebuffer));
				    	    	   
				    	 fifo_buffer #(.DW(5)) signals_buffer (.*,
				    	    								    .wr_data(failure_signal),
				    	    									.rd_data(buffer_failure_info),
				    	    									.full(full_signalsbuffer),
				    	    									.empty(empty_signalsbuffer),
				    	    									.write(writebuffer));
				    	    	   
				    	 
				    	 
				    	 /*Logic to determine instruction operation
				    	 info to send to PC. We must indicate in a byte
				    	 what operation was performed and whether the
				    	 operation succeeded.*/
				    	 logic[1:0] op_data;
				    	 always_comb begin
				    	   /*Use lower 2 bits to indicate what operation was
				    	   performed and upper 6 bits to indicate instruction
				    	   failure*/
				    	   case(buffer_mode[3:0])
				    	       //Read 1 byte
				    	       4'b0001: begin
				    	           op_data = 2'b00;
				    	       end
				    	       //Read 2 bytes
				    	       4'b0010: begin
				    	           op_data = 2'b01;
				    	       end
				    	       //Write 1 byte
				    	       4'b0100: begin
				    	           op_data = 2'b10;
				    	       end
				    	       4'b1000: begin
				    	           op_data = 2'b11;
				    	       end
				    	       
				    	       default:begin
				    	           op_data = 2'b00;
				    	       end
				    	    endcase				    	         
				    	 end   					
				    	 
				    	 always_comb begin
				    	   /*If UART is ready for another transmission
				    	   and there exists an instruction awaiting 
				    	   transmission(buffer isn't empty)
				    	   we prepare the data for transmission and
				    	   prepare to clear out the corresponding buffer entry*/
				    	   if(!empty_addressbuffer && tx_complete) begin
				    	       toPC_data_next = buffer_data;
				    	       toPC_mode_next = {buffer_failure_info,op_data};
				    	       toPC_address_next = buffer_address;
				    	       data_ready_next = 1'b1;
				    	       read = 1'b1;
				    	   end
				    	   
				    	   /*If there is no instruction data awaiting
				    	   transmission. We don't allow bypassing
				    	   for results of PC instructions so we
				    	   must check and ensure data from I2C controller
				    	   is for default mode*/	   	
				    	   else if(tx_complete && i2c_data_rdy && (i2c_valid_instr == 2'b01)) begin
				    	       toPC_data_next = i2c_retrieved_data;
				    	       toPC_mode_next = {failure_signal,2'b01};
				    	       toPC_address_next = '0;
				    	       data_ready_next = 1'b1;
				    	       read = '0;
				    	   end
				    	   
				    	   /*Next stage registers data it's received for transmission.
				    	   That way we can free up space in the buffer*/	   	
				    	   else begin
				    	       toPC_data_next = '0;
				    	       toPC_mode_next = '0;
				    	       toPC_address_next = '0;
				    	       data_ready_next = '0;
				    	       read = '0;
				    	   end
				    	 end
				    	    	   		
				    	 
				    	 //Output Register. Thus we can make a direct
				    	 //connection between the arbiter and the i2c_uart_bridge   	
				    	 always_ff @(posedge clk)
				    	   if(reset) begin
				    	       toPC_data <= '0;
				    	       toPC_mode <= '0;
				    	       toPC_address <= '0;
				    	       data_ready <= '0;
				    	    end
				    	    		
				    	    else begin
				    	    	toPC_data <= toPC_data_next;
				    	    	toPC_mode <= toPC_mode_next;
				    	    	toPC_address <= toPC_address_next;
				    	    	data_ready <= data_ready_next;
				    	    end
				    	    		
endmodule
				    	    		
				    	    			
				    	    			
				    	    	   		
				    	    	   		
				    	    	   
		
				    	    		








						
