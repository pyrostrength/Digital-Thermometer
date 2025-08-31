module fifovalid_tb;
    logic clk,reset;
    logic write,read;
    logic full,empty;
    logic[7:0] wr_data;
    logic[7:0] rd_data;
    
    fifo_validbuffer modbuffer(.*);
    
    always begin
        #5 clk = ~clk;
    end
    
    `timescale 1ns/1ps;
    
    initial begin
        reset = '1;
        clk = '0;
        read = '0;
        wr_data = '0;
        write = '0;
        
        #10;
        reset = '0;
        //Now that buffer is initialized
        //We fill buffer half-way
        for(int i = 0; i<8; i++) begin
            write = '1;
            wr_data = i*(i+10);
            #10;
        end
        //We fill buffer half-way
        
        //Test clearing an entry
        write = '0;
        read = '1;
        #10;
        
        /*Assert rd_ptr == 1, wr_ptr == 8*/
        
        //Simultaneous write and read
        write = '1;
        wr_data = 50;
        read = '1;
        #10
        
        /*Assert rd_ptr == 2, wr_ptr == 8,
        hold_write == '1, hold_data == 50*/
        write = '0;
        read = '0;
        
        #10;
        /*Assert wr_ptr == 9*/
        
        /*Fifo_valid buffer only differs from
        fifo buffer in that it can schedule writes.
        Thus we need not test for other FIFO buffer
        functionality*/
    end   
endmodule
