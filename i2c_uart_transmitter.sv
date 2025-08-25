/*Transmits data read off I2C temp sensor to UART core.
Must increment read_ptr of FIFO buffer to clear instruction.
Data frame packet transmitted to UART Core in the form:
-Start Byte -- 
-Address Byte -- address of register to which read/write was directed
-Operation Byte -- operation performed
-Stop Byte -- all 1's to terminate transmission
*/

module i2c_uart_transmitter (input logic clk,reset,
							  input logic data_ready, //I2C data ready
							  input logic tx_done_tick, //UART core has transmitted the data to PC.
							  input logic[15:0] received_data, //Data received from I2C temp sensor
							  input logic[7:0] op_data,
							  input logic[7:0] addr_pointer,
							  output logic tx_start,
							  output logic[7:0] data_byte, //UART frame packet
							  output logic transmit_complete); //Indicates completion of I2C transmission.
							  
							  typedef enum{idle,start,address,operation,data1,data2,stop} state_type;
							  
							  state_type state,state_next;
							  
							  always_ff @(posedge clk, posedge reset) 
							  	if(reset) begin
							  		state <= idle;
							  	end
							  	
							  	else begin
							  		state <= state_next;
							  	end
							
							
							always_comb begin
								state_next = state;
								tx_start = 1'b1;
								data_byte = '0;
								
								case(state)
									idle:begin
										if(data_ready) begin
											state_next = start;
											data_byte = '1; //load in the start bit
											tx_start = 1'b0; //Signal to start UART transmission to PC
										end
									end
									
									start: begin
										if(tx_done_tick) begin
											state_next = address;
											data_byte = addr_pointer;
											tx_start = 1'b0; //Initiate another byte transmission to PC
										end
									end
									
									address:begin
										if(tx_done_tick) begin
											state_next = operation;
											data_byte = op_data;
											tx_start = 1'b0;
										end
									end
									
									operation:begin
										if(tx_done_tick) begin
											tx_start = 1'b0;
											case(op_data[2:0]) 
												default: begin
													state_next = stop;
													data_byte = '1;
												end
												
												3'b000,3'b001: begin
													state_next = data1;
													data_byte = received_data[7:0];
												end
											endcase
										end
									end
									
									data1:begin
										if(tx_done_tick) begin
											tx_start = 1'b0;
											state_next = (op_data[0] == 1) ? data2: stop;
											data_byte = (op_data[0] == 1) ? received_data[15:8] : '1;
										end
									end
									
									data2:begin
										if(tx_done_tick) begin
											tx_start = 1'b0;
											state_next = stop;
											data_byte = '1;
										end
									end
									
									stop:begin
										if(tx_done_tick) begin
											tx_start = 1'b0;
											state_next = idle;
											transmit_complete = 1'b1; //We can now clear FIFO buffer of instruction.
										end
									end
								endcase
							end
endmodule
									
									
												
										
							  
							  
