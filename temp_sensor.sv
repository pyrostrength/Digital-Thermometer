/*Contract : if buffer_full led is on don't try and pass in any new instruction*/



module temp_sensor (input logic clk,reset,
				   	    input logic tx, //Data bit from PC UART transmitter
				    	    input logic sample_tick,
				   	    input logic[7:0] pc_data//Sample tick from PC UART transmitter
					    output logic op_complete,  //Indicates if the overall instruction was completed
				    	    output logic[7:0] data_byte,
				    	    output logic[15:0] led_on); //UART start byte/ reg address / op info / register data bytes
				    
				    	    logic time_out,buffers_full ;//Since you want to dilly dally look at those LED's glow.
				    	    logic wr_addrbuffer,wr_opbuffer,wr_databuffer1,wr_databuffer2;
				    	    logic full_addrbuffer, full_opbuffer, full_databuffer1, full_databuffer2, full_validbuffer;
				    	    logic empty_addrbuffer, empty_opbuffer, empty_databuffer1, empty_databuffer2, empty_validbuffer;
				    	    logic[7:0] fifo_address, fifo_databyte1, fifo_databyte2; //Output from reads on FIFO
				    	    logic[2:0] fifo_mode,fifo_valid;
				    	    
				    	    logic rx_done_tick;
				    	    logic[7:0] received_byte;
				    	   
				    	   assign buffers_full = full_validbuffer;
				    	    
				    	    uart_rx uart_receiver(.*,
				    	    						.rx_done_tick(rx_done_tick)
				    	    						.received_byte(received_byte));
				    	    
				    	    logic initiate, valid;
				    	    logic rx_done;
				    	    
				    	    //TIME_OUT AND TEMP SENSOR BUSY LED REGISTER
				    	    always_ff @(posedge clk, posedge reset) 
				    	    	if(reset) begin
				    	    		led_on <= '0;
				    	    	end
				    	    	
				    	    	else begin
				    	    		led_on[0] <= waiting;
				    	    		led_on[7:1] <= (time_out) ? '1:'0;
				    	    		led_on[15:8] <= (buffers_full) ? '1:'0;
				    	    	end
				    	    	
				    	    //UART - UART-I2C BRIDGE INTERFACE REGISTER
				    	    always_ff @(posedge clk, posedge reset)
				    	    	if(reset) begin
				    	    		rx_done <= '0;
				    	    	end
				    	    	
				    	    	else begin
				    	    		rx_done <= rx_done_tick;
				    	    	end
				    	
				    	     logic i2c_ready; //Indicates availability of I2C controller
				    	     logic[2:0] mode;
				    	     logic[7:0] addr_pointer;
				    	     logic[15:0] wr_data;
				    	     logic waiting;
				    	     //All 3 signals above are commands and data sent to i2c core.
				    	     uart_i2c_tramsmitter uart_i2c_bridge(.*,
				    	     										.time_out(time_out),
				    	     										.buffers_full(full_validbuffer),
				    	     										.waiting(waiting),
				    	    										.initiate(initiate),
				    	    										.received_byte(received_byte),
				    	    										.rx_done_tick(rx_done),
				    	    										.i2c_ready(i2c_ready),
				    	    										.mode(mode),
				    	    										.addr_pointer(addr_pointer),
				    	    										.wr_data(wr_data));
				    	    										
				    	        
				    	     fifo_buffer address_buffer #(.DW(7))(.*,
				    	    										.wr_data(addr_pointer),
				    	    										.rd_data(fifo_address)
				    	    										.full(full_addrbuffer),
				    	    										.empty(empty_addrbuffer),
				    	    										.write(wr_addrbuffer),
				    	    										.transmit_complete());
					    
					     fifo_buffer operation_buffer #(.DW(2))(.*,
					    											.wr_data(mode),
					    											.rd_data(fifo_mode),
					    											.full(full_opbuffer),
					    											.empty(empty_addrbuffer),
					    											.write(wr_opbuffer),
					    											.transmit_complete());
					   
					      fifo_buffer data1_buffer #(.DW(7))(.*, 
					    										.wr_data(wr_data[7:0]),
					    										.rd_data(fifo_databyte1)
					    										.full(full_databuffer1),
					    										.empty(empty_databuffer1),
					    										.write(wr_databuffer1),
					    										.transmit_complete());
					    
					       fifo_buffer data2_buffer #(.DW(7))(.*,
					     										.wr_data(wr_data[15:8]),
					     										.rd_data(fifo_databyte2),
					     										.full(full_databuffer2),
					     										.empty(empty_databuffer2),
					     										.write(wr_databuffer2),
					     										.transmit_complete());
					     	
					       fifo_buffer valid_buffer #(.DW(1))(.*,
				    	    									    .wr_data({initiate,1'b1}),
				    	    									    .rd_data(fifo_valid),
				    	    									    .full(full_validbuffer),
				    	    									    .empty(empty_validbuffer),
				    	    									    .write(initiate),
				    	    									    .transmit_complete());
				    	    									    
				    	    	
					    
					     										
					    
				    
