/*Generates the oversampling tick for the UART receiver and transmitter.*/

module baud_rate_generator (input logic clock,reset,
							    input logic[10:0] dvsr,
							    output logic tick);
							    
						logic[10:0] count,count_next;
							    
						always_ff @(posedge clk, posedge reset) 
							if(reset) begin
							    	count_reg <= '0;
							end
							    	
							else begin
							    	count_reg <= count_next;
							end
						
						always_comb begin
							count_next = (count_reg ==  dvsr) ? '0 : count_next + 1'b1;
							sample_tick = (count_reg == 1) ; //We can choose the value at which a sample tick is generated
						end
endmodule
							
							
							
