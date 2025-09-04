module i2c_uart_transmitter_tb;
    //Inputs
    logic clk,reset;
	logic data_ready; //new data is available for transmission
	logic tx_done_tick; //UART core has transmitted the data byte to PC.
	logic[15:0] toPC_data; //Data received from I2C temp sensor
	logic[7:0] toPC_mode;
	logic[7:0] toPC_address;
	//Inputs
	
	//Outputs						
	logic tx_start; //Active low Signal to start UART byte transmission
	logic[7:0] data_byte; //Data byte to be transmitted to PC over UART
	logic tx_complete; //Indicates completion of I2C transmission.
	//Outputs
	
	i2c_uart_transmitter bridge(.*);
	
	always begin
	   #5 clk = ~clk;
	end
	
	`timescale 1ns/1ps;
	
	/*Task randomizes the data inputs for 
	transmission.
	*/
	task automatic randomized_inputs;
	   output logic ready;
	   output logic[15:0] data;
	   output logic[7:0] mode;
	   output logic[7:0] address;
	   
	   begin
	       /*Note that mode may be read but
	       data value returned is a non-zero
	       number. Thus we must ensure
	       that if mode is read/write byte we don't load*/
	       
	       ready = $random();
	       data = $random();
	       mode = $random();
	       address = $random();
	      
	   end
	endtask
	
	/*Task randomizes the UART availability.
	Once UART becomes available for new 
	transmission to PC, appropriate databyte
	and transmission start signal are loaded into
	register
	*/
	task automatic randomized_UART;
	   /*Current byte loaded into register for
	   transmission*/
	   input logic[7:0] state_byte;
	   /*Next byte loaded into register when
	   UART becomes available for transmission*/
	   input logic[7:0] next_state_byte;
	   
	   
	   
	   /*If random value is divisible by 7
	   we make UART unavailable*/
	   while(($random() % 7) == 0) begin
	       tx_done_tick = '0;
	       
	       #2;
	       
	       assert(tx_start == '1) begin
	       end else begin 
	       $display("tx_start active when UART isn't ready for transmission");
	       $display($time);
	       end
	       
	       assert(data_byte == state_byte) begin
	       end else begin
	       $display("data_byte not equal to state_byte when UART is transmitting data");
	       $display($time);
	       end
	       
	       #8;
	   end
	   //UART transmitter is available
	   tx_done_tick = '1;
	   
	   #2;
	   
	   assert(tx_start == '0) begin
	   end else begin
	   $display("tx_start not active high when UART available");
	   $display($time);
	   end
	   
	   assert(data_byte == next_state_byte) begin
	   end else begin
	   $display("relevant data byte not prepared for transmission");
	   $display($time);
	   end
	   
	endtask
	
	
	
	initial begin
	   clk = '0;
	   
	   #10;
	   /*Pulse system with inputs for 200 seconds*/
	   /*we don't wait for full clock periods
	   but instead split time intervals up since
	   its as if the sampling of the assert signal
	   and the update of the signal's asynchronous control signal
	   happen at the same time, if no waiting period
	   is introduced*/
	   while($realtime < 2000000000) begin
	       //Reset the system
	       reset = '1;
	       
	       #10;
	       //Randomize availability UART availability
	       reset = '0;
	       tx_done_tick = '0;
	       //Randomize the inputs
	       randomized_inputs(data_ready,toPC_data,toPC_mode,toPC_address);
	       
	       if(data_ready != '1) begin
	           #2;
	           //No signal is made to start transmission
	           assert(tx_start == '1) begin
	           end else begin
	           $display("tx_start active when data isn't ready for transmission,");
	           end
	           
	           #8;
	           
	           /*Module should still be in idle state
	           with empty registers*/
	           assert(bridge.PC_data_reg =='0) begin
	           end else begin
	           $display("data register not reset"); end
	           
	           assert(bridge.PC_mode_reg =='0) begin
	           end else begin $display("mode register not reset"); end
	           
	           assert(bridge.PC_address_reg == '0) begin
	           end else begin $display("address register not reset"); end
	           
	           assert(data_byte == '0) begin
	           end else begin $display("data_byte not reset"); end
	           
	           continue;
	       end
	       
	       #2;
	       //Else data is ready for transmission
	       assert (tx_start == '0);
	       assert (data_byte == '1);
	       
	       #8;
	       
	       //In start state
	       randomized_UART('1,toPC_address);
	       #8;
	       
	       //In address state
	       randomized_UART(toPC_address,toPC_mode);
	       #8;
	       
	       //In operation state
	       //Operation is a read mode operation
	       if(toPC_mode[1:0] < 2) begin
	           randomized_UART(toPC_mode,toPC_data[7:0]);
	           #8;
	           
	           //Move into data 1 state
	           //If operation is a read 2 byte operation
	           if(toPC_mode[1:0] == 2'b01) begin
	               randomized_UART(toPC_data[7:0],toPC_data[15:8]);
	               #8;
	               
	               //Data 2 state
	               randomized_UART(toPC_data[15:8],'1);
	               #8;
	               
	               //Move into stop state
	           end
	           
	           else begin
	               randomized_UART(toPC_data[7:0],'1);
	               #8;
	               //Move into stop state
	           end
	           
	       end 
	       
	       //
	       else begin
	           randomized_UART(toPC_mode,'1);
	           #8;
	           
	           //Move into stop state
	       end
	       
	       //In stop state
	       tx_done_tick = '0;
	       
	       #2;
	       assert(tx_complete == '0);
	       assert(data_byte == '1);
	       
	       #8;
	       tx_done_tick = '1;
	       
	       #2;
	       assert(tx_complete == '1);
	       assert(data_byte == '0);
	       
	       #8;
	       
	   end      
	end						  
endmodule
