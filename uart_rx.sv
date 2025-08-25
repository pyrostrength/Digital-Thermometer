/*UART receiver module
No parity bits for data received, 1 byte data,
1 start bit and 1 stop bit, oversampling scheme is 16x the baud rate*/

module uart_rx (input logic clk,reset,
				input logic tx,
				input logic sample_tick,
				output logic rx_done_tick,
				output logic[7:0] received_byte);
				
				typedef enum{idle,start,data,stop} state_type;
				
				state_type state, state_next;
				logic[4:0] tick, tick_next; //Counts the number of sample ticks
				logic[7:0] rx_reg, rx_next;
				logic[2:0]  bit_count, bit_count_next; //Count the number of bits passed
				
				always_ff @(posedge clk, posedge reset)
					if(reset) begin
						tick <= '0;
						rx_reg <= '0;
						state <= idle;
					end
					
					else begin
						tick <= tick_next;
						rx_reg <= rx_next;
						state <= state_next;
					end
				
				assign received_byte = rx_reg;
				
				always_comb begin
					state_next = state;
					tick_next = tick;
					rx_next = rx_reg;
					bit_count_next = bit_count;
					rx_done_tick = '0;
					
					case(state)
						idle: begin
							if(!tx) begin //If data line has been pulled low
								state_next = start;
								tick_next = '0;
								bit_count_next = '0;
								rx_next = '0;
							end
						end
						
						start: begin
							if(sample_tick) begin
								if(tick == 7) begin //Middle of start bit
									state_next = data;
									tick_next = '0; //Reset the tick counter
								end
								else begin
									tick_next = tick + 1; //Add up the number of ticks
								end
							end
						end
						
						data:begin
							if(sample_tick) begin
								if(tick == 15) begin //Middle of data bit
									rx_next = {tx ,rx_reg[7:1]};
									tick_next = '0; //Reset sampling tick counter
									if(bit_count == 7) begin //Sampling the final data bit
										state_next = stop;
									end
									
									else begin
										bit_count_next = bit_count + 1;
									end
								end
								
								else begin
									tick_next = tick + 1;
								end
							end
						end
						
						stop: begin
							if(sample_tick) begin
								if(tick == 15) begin
									state_next = idle;
									rx_done_tick = 1'b1;
								end
								
								else begin
									tick_next = tick + 1;
								end
							end
						end
					endcase
				end

endmodule
									
									
									
							
									
						
								
					
						
				
				
				
				
				
