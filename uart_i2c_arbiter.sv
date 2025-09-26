/*
Determines which instruction uses the I2C controller. 
Priority is given to queued instruction.
If no instructions is queued then default mode is read the current temperature.
All new instructions are first written into the buffer.

Instruction entry is cleared once data has been moved
onto I2C controller
*/


module uart_i2c_arbiter(input logic clk,reset,
						input logic i2c_ready,//Indicates if I2C is ready for another transaction
						//Control signals to write address,operation and data buffers
						input logic wr_addrbuffer, wr_databuffer1, wr_databuffer2, wr_opbuffer,
				    	input logic[7:0] addr_pointer,//Register address in temp sensor
				    	input logic[15:0] wr_data,//Data to be written to register
				    	input logic[7:0] mode,//Mode of operation
				    	output logic[15:0] i2c_data,//Data to be written to register
				    	output logic[7:0] i2c_address,//Address of register to which operation is directed
				    	output logic[7:0] i2c_mode, //Read/write indication
				    	output logic[1:0] valid_instr, //Indicates whether we actually have an issued instruction.
				    	output logic buffers_full); //Indicates when instruction queue is full
				    	          
				    	logic[7:0] fifo_address, fifo_databyte1, fifo_databyte2; //Output from reads on FIFO
				    	logic[2:0] fifo_mode;        
				    	logic full_addrbuffer, full_opbuffer, full_databuffer1, full_databuffer2;
				    	logic empty_addrbuffer, empty_opbuffer, empty_databuffer1, empty_databuffer2;
				    	    	  
				    	assign buffers_full = full_addrbuffer;
				    	
				    	logic buffer_read;
				    	 	  
				    	fifo_buffer #(.DW(7)) address_buffer(.*,
				    	    								 .wr_data(addr_pointer),
				    	    								 .rd_data(fifo_address),
				    	    								 .full(full_addrbuffer),
				    	    								 .empty(empty_addrbuffer),
				    	    								 .write(wr_addrbuffer),
				    	    								 .read(buffer_read));
				    	    										
					    fifo_buffer #(.DW(7)) operation_buffer(.*,
					    									   .wr_data(mode),
					    									   .rd_data(fifo_mode),
					    									   .full(full_opbuffer),
					    									   .empty(empty_opbuffer),
					    									   .write(wr_opbuffer),
					    									   .read(buffer_read));
					   
					    fifo_buffer #(.DW(7)) data1_buffer(.*, 
					    								   .wr_data(wr_data[7:0]),
					    								   .rd_data(fifo_databyte1),
					    								   .full(full_databuffer1),
					    								   .empty(empty_databuffer1),
					    								   .write(wr_databuffer1),
					    								   .read(buffer_read));
					    
					    fifo_buffer #(.DW(7)) data2_buffer(.*,
					     								   .wr_data(wr_data[15:8]),
					     								   .rd_data(fifo_databyte2),
					     								   .full(full_databuffer2),
					     								   .empty(empty_databuffer2),
					     								   .write(wr_databuffer2),
					     								   .read(buffer_read));
					     	
					    
				    	    					    	    	
				        logic[7:0] i2c_address_next;
				    	logic[15:0] i2c_data_next;
				    	logic[2:0] i2c_mode_next, valid_instr_next;	
				    	
				    	
				    	/*Determine data flowing into I2C controller */
				    	always_comb begin
				        /*Priority given to scheduled instruction.
				        To prevent unfilled entries in buffer from
				        being interpreted as instructions in next cycle
				        we check if buffer is empty. If empty we have
				        no queud instruction. If not empty then entry
				        at top of the stack is an issued instruction.
				        Since all buffers are written in the same cycle when an instruction
				        is issued, we need only pick 1 empty signal to check.*/
				    	   if(i2c_ready && !empty_addrbuffer) begin
				    	       i2c_data_next = {fifo_databyte2,fifo_databyte1};
				    	       i2c_address_next = fifo_address;
				    	       i2c_mode_next = fifo_mode;
				    	       valid_instr_next = {1'b1,!empty_addrbuffer};
				    	       buffer_read = 1'b1;	
				    	   end    		
				    	   
				    	   /*If no queued instruction and I2C controller is ready
				    	   then we initiate a temperature read*/
				    	   else if(i2c_ready && empty_addrbuffer) begin
				    	       i2c_data_next = '0; //No data to write during reads
				    	       i2c_address_next = '0;// Default register for 1st temperature byte
				    	       valid_instr_next = 2'b01; //Indicate that it's a default mode instruction
				    	       i2c_mode_next = {3'b001} ; //Read 2 bytes
				    	       buffer_read = 1'b0;
				    	   end
				    	
				    	   /*I2C controller registers what's needed for its operations
				    	   right before initiating transaction. Thus to avoid tricking
				    	   the I2C controller into redoing an instruction, we zero the outputs
				    	   in case i2c isn't ready*/   		
				    	   else begin
				    	       valid_instr_next = '0;
				    	       i2c_data_next = '0;
				    	       i2c_address_next = '0;
				    	       i2c_mode_next = '0;
				    	       buffer_read = 1'b0;
				    	   end
				    	end
				    	    	
				    	//Register in between uart-i2c buffer and i2c controller that passes data to UART controller
				    	always_ff @(posedge clk) 
				    	   if(reset) begin 
				    	       i2c_data <= '0;
				    	       i2c_mode <= '0; 
				    	       i2c_address <= '0;
				    	       valid_instr <=  '0; 
				    	   end
				    	    		
				    	   else begin
				    	       i2c_data <= i2c_data_next;
				    	       i2c_mode <= i2c_mode_next;
				    	       i2c_address <= i2c_address_next;
				    	       valid_instr <= valid_instr_next;
				    	   end
				    	    									    
				    	    									    
endmodule
				    	          
				    	          
				    	          
				    	          
