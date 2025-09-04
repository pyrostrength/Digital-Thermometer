/*I2C_UART ARBITER VERIFIED*/
module i2c_uart_arbiter_tb;
    logic clk,reset;
                         
    //Data from I2C controller
	logic[15:0] i2c_retrieved_data;
	logic[7:0] i2c_instr_address; 
	logic[7:0] i2c_op_info;
	logic[2:0]i2c_valid_instr;
	logic[5:0] failure_signal;
	logic i2c_data_rdy; //Has data from I2C been made available?
						 //Data from I2C controller
						 
	//Control signal indicating UART has transmitted all data bytes
	logic tx_complete; 
						 
	//Signal to UART to initiate new transmission
	logic data_ready;
	//Indicates when i2c buffers are full thus pipeline should stall
	logic full_i2cbuffer;
	logic empty_i2cbuffer;
						 
	//Data going out to PC
	logic[7:0] toPC_address;
	logic[7:0] toPC_mode;
	logic[15:0] toPC_data;
	
	int k,val;
	int j,sel;
						 
	always begin
        #5 clk = ~clk;
    end
    
    `timescale 1ns/1ps;
    
    i2c_uart_arbiter arbiter(.*);
    
    initial begin
        //Initialize system
        reset = '1;
        clk = '0;
        
        #10;
        
        
        /*Observe output choice of an empty buffer
        and ensure proper encoding for mode*/
        for(int i = 0; i<4; i++) begin
            i2c_data_rdy = '1;
            /*Result of continous read operation
            so no writing to the buffer*/
            i2c_valid_instr = 2'b01;
            //Change retrieved data and instruction address on each iteration
            i2c_retrieved_data = 45 + i*2 - i*i;
            i2c_instr_address = 20 + i*i;
            /*Left shift a base vector up to 3 times to cover all modes.
            Mode shouldn't change at all since instruction is
            default mode continous read*/
            i2c_op_info = 8'b00000001 << i; 
            failure_signal = '0; //No operation failures
            reset = '0;
            tx_complete = '1; //UART is ready for another transmission
            #10;
            assert(toPC_data == i2c_retrieved_data);
            assert(toPC_address == '0);
            assert(toPC_mode == 8'b0000_0001);
            assert(full_i2cbuffer == '0);
            assert(toPC_mode[1:0] == 2'b01);
        end
        
        /*Fill up buffer*/
        for(int i = 0; i<16; i++) begin
            i2c_data_rdy = '1;
            /*Result of instruction issued by PC
            so writing to the buffer*/
            i2c_valid_instr = 2'b11;
            //Change retrieved data and instruction address on each iteration
            i2c_retrieved_data = 45 + i*2 - i*i;
            i2c_instr_address = 20 + i*i;
            /*Left shift a base vector by factor i%4 to cover all modes.
            Modulo 4 factor chosen as only 4 modes are possible
            Mode shouldn't change at all since instruction is
            default mode continous read*/
            i2c_op_info = 8'b00000001 << (i%4); 
            failure_signal = '0; //No operation failures
            reset = '0;
            tx_complete = '0; //UART isn't ready for another transmission
            #10;
            /*Since UART isn't available for transmission outputs are zeroed*/
            assert(toPC_data == '0);
            assert(toPC_mode == '0);
            assert(toPC_address == '0);
            if(i < 15) begin
                assert(full_i2cbuffer == '0);
            end
            else begin
                assert(full_i2cbuffer == '1);
            end
            assert(toPC_mode[1:0] == '0);
         end
           
        
        /*We now randomize UART availability to test 
        for whether correct data is allocated for transmission.
        To distinguish between default mode instruction and
        PC requested instruction we observe the register address.
        All PC instructions will be designed to have non-zero
        register addresses.*/
        while(!empty_i2cbuffer) begin
            i2c_data_rdy = '0;
            tx_complete = '0;
            val = $random(k);
            /*If random number is even UART opens up for transmission*/
            if (val%2 == 0) begin
                tx_complete = '1;
                /*Use a random function to determine if write
                occurs*/
                sel = $random(j);
                if(sel%2 == 0) begin
                    /*We initiate instruction write using fixed data
                    and info*/
                    i2c_data_rdy = '1;
                    i2c_valid_instr = 2'b11;
                    i2c_retrieved_data = 67;
                    i2c_op_info = 8'b00001000;
                    i2c_instr_address = 67;
                    failure_signal = '1;
                end
                
                #10;
                /*Ensure no bypass mechanism for instructions
                - instructions must first pass through buffer*/
                assert(toPC_mode != 8'b11111100);
                assert(data_ready == '1);
                assert(toPC_address != '0); //Not a default mode instruction
           end
           
           /*UART doesn't open up for transmission*/
           else begin
                /*Empty buffer closes the loop meaning
                we must atleast have some entry available.
                We indicate default mode instruction availabe
                but we don't expect to observe it on output*/
                
                i2c_data_rdy = '1;
                i2c_valid_instr = 2'b01;
                i2c_op_info = 8'b00000001;
                i2c_retrieved_data = 83;
                failure_signal = '0;
                i2c_instr_address = '0;
                
                #10;
                assert(toPC_data == '0);
                assert(toPC_mode == '0);
                assert(toPC_address == '0);
                assert(data_ready == '0);
           end                  
        end
        
        assert(empty_i2cbuffer == '1);
     end
                				    	          
endmodule
