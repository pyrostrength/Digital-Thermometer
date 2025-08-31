module uart_i2c_arbiter_tb;
    logic clk,reset;
	logic i2c_ready;
	logic wr_addrbuffer, wr_databuffer1, wr_databuffer2, wr_opbuffer;
	logic initiate;
	logic[7:0] addr_pointer;
	logic[15:0] wr_data;
	logic[2:0] mode;
	
	logic[15:0] i2c_data;
	logic[7:0] i2c_address;
	logic[2:0] i2c_mode;
	logic[1:0] valid_instr;
	logic buffers_full;
	
	always begin
        #5 clk = ~clk;
    end
    
    `timescale 1ns/1ps;
    
    uart_i2c_arbiter arbiter(.*);
    
    initial begin
        //Initialize system
        reset = '1;
        clk = '0;
        i2c_ready = '0;
        
        #10
        //Fill the buffers - all instructions are 2 byte writes
        reset = '0;
        for(int i = 0; i<16; i++) begin
            wr_addrbuffer = '1;
            wr_opbuffer = '1;
            wr_databuffer1 = '1;
            wr_databuffer2 = '1;
            initiate = '1;
            addr_pointer = 11 + 2*i;
            wr_data = 67 + i;
            mode = 3'b011; 
            #10;
        end
        
        assert(buffers_full == '1);
        /*Assert buffers_full == 1*/
        
        //Let's clear buffer by signalling that the I2C is ready
        for(int i = 0; i<16; i++) begin
            wr_addrbuffer = '0;
            wr_opbuffer = '0;
            wr_databuffer1 = '0;
            wr_databuffer2 = '0;
            initiate = '0;
            i2c_ready = '1;
            #10;
        end
        
        /*Assert buffers_empty == 1, observe address output data*/
        
        #10;
        /*Ensure output data is for continous read operation*/
        //VERIFIED.
    end
        
				    	          
endmodule
