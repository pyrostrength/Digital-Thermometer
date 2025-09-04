module uart_i2c_transmitter_tb;
    /*Inputs*/
    logic clk,reset;
	logic rx_done_tick; //Transmission of byte was complete
	logic[7:0] received_byte; //Byte received from PC.
	logic buffers_full; //if buffers are full we cannot queue the instruction. User must wait then repeat the instruction on PC end
	/*Inputs*/
	
	/*Outputs*/
	//Data to be written to I2C temperature sensor's registers.
	logic[15:0] wr_data; 
	// Read 1 byte/2 bytes or write 1 byte or 2 bytes
	logic[7:0] mode; 
	//Queue instruction information in their respective buffers
	logic wr_addrbuffer,wr_opbuffer,wr_databuffer1,wr_databuffer2;
	//System time-out if user delays too long in completely specifying their wants.
	logic time_out; 
	//Register on I2C temperature sensor to which operation is addressed.
	logic[7:0] addr_pointer;
	/*Outputs*/ 
	
	int i;//while loop counter
	int k;//loop repeat variable
	int o;//random integer
	
	
	/*Change wait time period to a .1 microsecond/100 nanoseconds
	for simulation purposes*/
	uart_i2c_tramsmitter #(.PERIOD(0.0000001))
	   bridge(.*);
	
	always begin
	   #5 clk = ~clk;
	end
	
	typedef enum{idle,address,operation,data1,data2,stop} state_type;
	
	`timescale 1ns/1ps;
	
	/*Task randomizes the system timeout.
	Operation, register address and data bytes
	already received are provided as inputs and
	the task verifies that these bytes were stored.
	
	output acts as a signal to 
	repeat the current loop iteration.*/
	task automatic randomize_timeout;
	   input logic[7:0] register_address;
	   input logic[7:0] operation;
	   input logic[15:0] data;
	   output int j; //time_out signal to repeat loop
	   output int val;
	   
	   begin
	       //random number
	       /*If random function returns even
	       integer we time out the system*/
	       val = $random();
	       if ((val % 7) == 0) begin
	           rx_done_tick = '0;
	           #90;
	           /*At time max_delay - sys_clk period
	           we expect time_out signal to be high*/
	           assert(time_out == '1);
	       
	           #10;
	           /*Time out signal should only be active
	           for 1 clock cycle in stop state*/
	           assert(time_out == '0);
	           /*State machine in idle state,retaining
	           bytes already registered*/
	           assert(wr_data == data);
	           assert(addr_pointer == register_address);
	           assert(mode == operation);
	           assert({wr_addrbuffer,wr_opbuffer,wr_databuffer1,wr_databuffer2} == '0);

	           j = 1; //Assert j = 1 to redo PC-UART communication
	       end
	       
	       /*If no time_out assert byte availability signal
	       and proceed with comm*/
	       else begin
	           rx_done_tick = 1'b1;
	           j = 0;
	       end
	   end
	endtask
	   
	
	initial begin
	   //Initialize the system
	   reset = '1;
	   clk = '0;
	   #10;
	   
	   /*If start byte doesn't meet standards
	   no communication is acknowledged*/
	   received_byte = 8'b10010001;
	   rx_done_tick = '1;
	   buffers_full = '0;
	   reset = '0;
	   #10;
	   
	   
	   /*If buffer is full no new
	   communication is acknowledged*/
	   buffers_full = '1;
	   received_byte = '1;
	   #10;
	   
	   
	   /*If appropriate start byte is received,must ensure 
	   all the necessary data bytes are registered as UART
	   receiver receives the bytes*/
	   
	   /*We can use a while loop to code for the various operations
	   possible as each operation has it's own specific path through
	   FSM. Also use a random function to randomize the time_out
	   feature.*/
	   
	   i = 0;
	   
	   while (i<5000) begin
	       /*Before writing in next byte, we
	       randomize event of system timeout due
	       to user delays.*/
	       
	       /*Since data written to internal register
	       is maintained in state transition from stop
	       to idle, for testbench to work, we need to
	       clear the buffer first*/
	       reset = '1;
	       
	       #10;
	       
	       /*Receive data packet starting with start byte*/
	       reset = '0;
	       buffers_full = '0;
	       received_byte = '1;
	       rx_done_tick = '1;
	       
	   
	       #10;
	       assert(wr_data == '0);
	       assert(addr_pointer == '0);
	       assert(mode == '0);
	       assert({wr_addrbuffer,wr_opbuffer,wr_databuffer1,wr_databuffer2} == '0);
	       assert(time_out == '0);
	       
	       
	       //IN ADDRESS STATE
	       received_byte = 4;
	       
	       randomize_timeout('0,'0,'0,k,o);
	       /*Data packet not received, then
	       restart communication*/
	       if(k == 1) begin
	           continue;
	       end
	   
	       #10;
	       assert(wr_data == '0);
	       assert(addr_pointer == 4);
	       assert(mode == '0);
	       assert({wr_addrbuffer,wr_opbuffer,wr_databuffer1,wr_databuffer2} == '0);
	       assert(time_out == '0);
	       
	       
	       //IN OPERATION STATE
	       received_byte = 8'b00000001 << (i%4);
	       
	       randomize_timeout(4,'0,'0,k,o);
	       /*Data packet not received, then
	       restart communication*/
	       if(k == 1) begin
	           continue;
	       end
	       #10;
	       
	       assert(wr_data == '0);
	       assert(addr_pointer == 4);
	       assert(mode == (8'b00000001<<(i%4)));
	       assert({wr_addrbuffer,wr_opbuffer,wr_databuffer1,wr_databuffer2} == '0);
	       assert(time_out == '0);
	       
	       //If operation constituted a write then
	       if((i%4) > 1) begin
	           received_byte = 48;
	           
	           randomize_timeout(4,(8'd1<<(i%4)),'0,k,o);
	           /*Data packet not received, then
	           restart communication*/
	           if(k == 1) begin
	               continue;
	           end
	           
	           #10;
	           
	           assert(wr_data[7:0] == 48);
	           assert(addr_pointer == 4);
	           assert(mode == (8'b00000001<<(i%4)));
	           assert({wr_addrbuffer,wr_opbuffer,wr_databuffer1,wr_databuffer2} == '0);
	           assert(time_out == '0);
	           
	           /*Writing 2 bytes*/
	           if((i%4) == 3) begin
	               received_byte = 22;
	               
	               randomize_timeout(4,(8'd1<<(i%4)),{8'b0,8'd48},k,o);
	               /*Data packet not received, then
	               restart communication*/
	               if(k == 1) begin
	                   continue;
	               end
	               
	               #10;
	               
	               assert(wr_data[15:8] == 22);
	               assert(addr_pointer == 4);
	               assert(mode == (8'b00000001<<(i%4)));
	               assert({wr_addrbuffer,wr_opbuffer,wr_databuffer1,wr_databuffer2} == '0);
	               assert(time_out == '0);
	                   
	               received_byte = '1;
	               
	               randomize_timeout(4,(8'd1<<(i%4)),{8'd22,8'd48},k,o);
	               /*Data packet not received, then
	               restart communication*/
	               if(k == 1) begin
	                   continue;
	               end
	               
	               #2;
	               assert({wr_addrbuffer,wr_opbuffer,wr_databuffer1,wr_databuffer2} == '1);
	               
	               #8;
	           end
	           
	           //If writing 1 bytes
	           else begin
	               received_byte = '1;
	               
	               randomize_timeout(4,(8'd1<<(i%4)),{8'b0,8'd48},k,o);
	               /*Data packet not received, then
	               restart communication*/
	               if(k == 1) begin
	                   continue;
	               end
	               
	               #2;
	               assert({wr_addrbuffer,wr_opbuffer,wr_databuffer1,wr_databuffer2} == '1);
	               
	               #8;
	           end        
	       end
	       
	       
	       //Operation is a read
	       else begin
	            assert(wr_data == '0);
	            assert(addr_pointer == 4);
	            assert(mode == (8'b00000001<<(i%4)));
	            assert({wr_addrbuffer,wr_opbuffer,wr_databuffer1,wr_databuffer2} == '0);
	            assert(time_out == '0);
	              
	            received_byte = '1;
	            
	            randomize_timeout(4,(8'd1<<(i%4)),'0,k,o);
	            /*Data packet not received, then
	            restart communication*/
	            if(k == 1) begin
	               continue;
	            end
	            
	            /*Somehow this assert statement fails
	            without the wait time. Maybe simulator
	            does take into account non-zero time
	            for combinational logic to produce output*/
	            #2;
	            assert({wr_addrbuffer,wr_opbuffer,wr_databuffer1,wr_databuffer2} == '1);
	               
	            #8;
	       end
	       
	       i = i + 1;//Increment i for while loop counter
	    end 	    
	 end							
endmodule
