/*Generates the oversampling tick for the UART receiver and transmitter.

Desired baud rate and system clock frequency is specified in terms of parameters.
The default oversampling scheme is 16x, default baud rate is 38400.

Baud rate generator is implemented as a counter. For a sampling scheme of 16x the baud rate
we use a counter that counts from 0 up to 
[(System Clock Freq) / (16* Baud Rate)] - 1  then resets. This value is calculated
via a localparam.

*/

module baud_rate_generator(input logic clk,reset,
						   output logic sample_tick);
						   
						   /*Designer is in charge of specifying the baud rate and sys clock*/
						   parameter SYS_FREQ = 100000000;
						   parameter BAUD_RATE = 38400;
						   localparam int DVSR = (SYS_FREQ/(BAUD_RATE*16))-1;
						   localparam SIZE = $clog2(DVSR);
						   
						   
						   logic[SIZE:0] count,count_next;
						   logic[SIZE:0] dvsr = DVSR;
						   
						   always_ff @(posedge clk, posedge reset) 
						      if(reset) begin
							     count <= '0;
							  end
							    	
							  else begin
							     count <= count_next;
							  end
						
						   always_comb begin
						      count_next = (count === dvsr) ? '0 : count + 1;
							  sample_tick = (count === dvsr)  ; //Sample tick is generated every full cycle
						   end
endmodule
							
							
							
