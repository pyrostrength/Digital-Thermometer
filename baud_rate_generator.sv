/*Generates the oversampling tick for the UART receiver and transmitter.

Baud rate generator is implemented as a counter. For a sampling scheme of 16x the baud rate
we use a counter that counts from 0 up to 
[(System Clock Freq) / (16* Baud Rate)] - 1  then resets.

The maximum count is the dvsr input to the system.
*/

module baud_rate_generator(input logic clk,reset,
						   input logic[10:0] dvsr,//Determines the baud rate
						   output logic sample_tick);
						   
						   logic[10:0] count,count_next;
						   
						   always_ff @(posedge clk, posedge reset) 
						      if(reset) begin
							     count <= '0;
							  end
							    	
							  else begin
							     count <= count_next;
							  end
						
						   always_comb begin
						      count_next = (count ===  dvsr) ? '0 : count + 1;
							  sample_tick = (count === dvsr)  ; //Sample tick is generated every full cycle
						   end
endmodule
							
							
							
