/*UART transmitter module

UART transmission is initiated by pulling the transmission line low(sending
1 low bit), followed by 8 data bits and 1 stop bit.

Baud rate determined by baud rate generator module which
generates a sample tick - 16 of such sample ticks represent
a full UART cycle. Thus every 16 sample ticks a new bit is shifted
out of the transmitter. */

module uart_tx (input logic clk,reset,
				input logic[7:0] data_byte,//Data byte to be transmitted
				input logic sample_tick,
				input logic tx_start,//initiates UART transmission.
				output logic tx_done_tick, //indicates when data transmission is complete
				output logic tx);//output data bit
				
				typedef enum{idle,start,data,stop} state_type;
				
				state_type state, state_next;
				logic[4:0] tick, tick_next; //Counts the number of sample ticks
				logic[7:0] tx_reg, tx_next; //Holds data to be transmitted
				logic[2:0]  bit_count, bit_count_next; //Counts the number of data bits passed
				
				always_ff @(posedge clk)
					if(reset) begin
						tick <= '0;
						/*Since l.s.bit of tx_reg is the data bit to be transmitted
						we must ensure that by default l.s.bit is 1 since a bit of 0
						signals start condition for UART transmission*/
						tx_reg <= '1;
						state <= idle;
						bit_count <= '0;
					end
					
					else begin
						tick <= tick_next;
						tx_reg <= tx_next;
						state <= state_next;
						bit_count <= bit_count_next;
				    end
				
				assign tx = tx_reg[0];
				
				always_comb begin
					state_next = state;
					tick_next = tick;
					tx_next = tx_reg;
					bit_count_next = bit_count;
					tx_done_tick = '0;
					
					case(state)
						idle: begin
						  /*We use an active low transmission start bit*/
							if(!tx_start) begin 
								state_next = start;
								tick_next = '0;
								bit_count_next = '0;
								tx_next = '0; //Start bit is 0. On next clock cycle tx goes low
							end
						end
						
						start: begin
						    /*Start bit has been sent out. We estimate middle of start bit
						    by counting up to 7 - UART in this design uses a 16x oversampling
						    scheme.*/
							if(sample_tick) begin
								if(tick == 15) begin //Approaching end of start bit.
									state_next = data;
									tx_next = data_byte;
									tick_next = '0; //Reset the tick counter
								end
								else begin
									tick_next = tick + 1; //Add up the number of ticks
								end
							end
						end
						
						data:begin
							if(sample_tick) begin
								if(tick == 15) begin //Approaching end of data bit
									tick_next = '0; //Reset sampling tick counter
									if(bit_count == 7) begin //Transmitting the final data bit
										state_next = stop;
										bit_count_next = '0;
										tx_next = '1; //Stop bit is a high signal
									end
									
									else begin
									   //Shift out least significant data bit first
									    tx_next = {1'b0 , tx_reg[7:1]}; 
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
								if(tick == 15) begin //Approaching end of stop bit
									state_next = idle;
									tx_done_tick = 1'b1;//Signal transmission is complete
								end
								
								else begin
									tick_next = tick + 1;
								end
							end
						end
					endcase
				end

endmodule
