/*

Prepares data packets for UART transmission to PC.
As agreed UART communication between PC and FPGA is in the following
form:
-Start Byte -- all 1's to initiate transmission
-Address Byte - address of register to which instruction was addressed 
-Operation Byte - operation perfomed and, only in case of FPGA to PC, info on transmission failure
-Stop Byte -- all 1's to terminate transmission

*/
module i2c_uart_transmitter(input logic clk,reset,
							input logic data_ready, //new data is available for transmission
							input logic tx_done_tick, //UART core has transmitted the data byte to PC.
							input logic[15:0] toPC_data, //Data received from I2C temp sensor
							input logic[7:0] toPC_mode,
							input logic[7:0] toPC_address,
							output logic tx_start, //Active low Signal to start UART byte transmission
							output logic[7:0] data_byte, //Data byte to be transmitted to PC over UART
							output logic tx_complete); //Indicates completion of I2C transmission.
							  
							typedef enum{idle,start,address,operation,data1,data2,stop} state_type;
							  
							state_type state,state_next;
							
							logic[15:0] PC_data_reg,PC_data_next;
							logic[7:0] PC_address_reg,PC_address_next;
							logic[7:0] PC_mode_reg,PC_mode_next;
							
							always_ff @(posedge clk, posedge reset) 
						      if(reset) begin
							     state <= idle;
							     PC_data_reg <= '0;
							     PC_address_reg <= '0;
							     PC_mode_reg <= '0;
							  end
							  	
							  else begin
							     state <= state_next;
							     PC_data_reg <= PC_data_next;
							     PC_mode_reg <= PC_mode_next;
							     PC_address_reg <= PC_address_next;
							  end
							
							
							always_comb begin
						      state_next = state;
							  tx_start = 1'b1;
							  data_byte = '0;
							  PC_address_next = PC_address_reg;
							  PC_mode_next = PC_mode_reg;
							  PC_data_next = PC_data_reg;
								
							  case(state)
							     idle:begin
								    if(data_ready) begin
								       PC_address_next = toPC_address;
								       PC_mode_next = toPC_mode;
								       PC_data_next = toPC_data;
									   state_next = start;
									   data_byte = '1; //Send start byte
									   tx_start = 1'b0; //Signal to start UART transmission to PC
									end
								 end
								
								 /*Wait as UART transmits start byte*/	
								 start: begin
								    data_byte = '1;
								    if(tx_done_tick) begin
									   state_next = address;
									   data_byte = PC_address_reg; //Send address byte
									   tx_start = 1'b0; //Initiate another byte transmission to PC
									end
								 end
									
								 address:begin
								    data_byte = PC_address_reg;
								    if(tx_done_tick) begin
									   state_next = operation;
									   data_byte = PC_mode_reg;
									   tx_start = 1'b0;
									end
								 end
									
								 operation:begin
								    data_byte = PC_mode_reg;
								    if(tx_done_tick) begin
									   tx_start = 1'b0;
									   case(PC_mode_reg[1:0]) 
									       default: begin
										      state_next = stop;
											  data_byte = '1;
										   end
												
										   2'b00,2'b01: begin
										      state_next = data1;
											  data_byte = PC_data_reg[7:0];
										   end
									   endcase
									end
								 end
									
								 data1:begin
								    data_byte = PC_data_reg[7:0];
								    if(tx_done_tick) begin
									   tx_start = 1'b0;
									   //If we're instruction involved a 2 byte read, otherwise
									   //move to stop transmission
									   state_next = (PC_mode_reg[0] == 1) ? data2: stop;
									   data_byte = (PC_mode_reg[0] == 1) ? PC_data_reg[15:8] : '1;
									end
								 end
									
								 data2:begin
								    data_byte = PC_data_reg[15:8];
								    if(tx_done_tick) begin
									   tx_start = 1'b0;
									   state_next = stop;
									   data_byte = '1;
									end
								 end
									
								 stop:begin
								    data_byte = '1;
								    if(tx_done_tick) begin
									   tx_start = 1'b0;
									   state_next = idle;
									   data_byte = '0;
									   tx_complete = 1'b1; //We signal to arbiter stage that we can take up a new instruction.
									end
								 end
							  endcase
						    end
endmodule
									
									
												
										
							  
							  
