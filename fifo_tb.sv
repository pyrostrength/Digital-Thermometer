module fifo_tb;
    
    //Signal declaration
    logic clk,reset;
    logic write,read;
    logic full,empty;
    logic[7:0] wr_data;
    logic [7:0] rd_data;
    
    fifo_buffer buffer(.*);
    
    always begin
        #5 clk = ~clk;
    end
    
    `timescale 1ns/1ps;
    
    initial begin
        reset = '1;
        clk = '0;
        read = '0;
        write = '0;
        wr_data = '0;
        
        #10;
        assert(full == '0);
        assert(empty == '0);
        //assert(rd_ptr == '0) and assert(wr_ptr == '0);
        
        /*2 writes followed by 1 read then write*/
        reset = '0; 
        wr_data = 75;
        write = '1;
        #10; 
        //Assert(wr_ptr == 1),(rd_ptr == 0),(full == 0) (empty == 0)
        
        //Initiate next write after write 1 completes
        wr_data  = 32;
        write = '1;
        #10;
        //Assert(wr_ptr == 2),(rd_ptr == 0),(full == 0),(empty == 0)
        
        //Initiate read
        write = '0;
        wr_data = 14;
        read = '1;
        /*Assert (rd_data == 75)*/
        #10;
        /*Assert(wr_ptr == 2), (rd_ptr == 1), (full == 0), (empty == 0)
        Assert (rd_data == 32)*/
        
        
        //Initiate write with no read
        write = '1;
        read = '0;
        #10;
        /*Assert(wr_ptr == 3), (rd_ptr == 1), (full == 0), (empty == 0)
        Assert (rd_data == 32)*/
        
        //2 reads to clear buffer
        //First read
        write = '0;
        read = '1;
        /*Assert(rd_data == 32)*/
        #10;
        /*Assert(wr_ptr == 3), (rd_ptr == 2), (full == 0), (empty == 0)
        Assert (rd_data == 14)*/
        
        //Last Read
        
        #10;
        /*Assert(wr_ptr == 3) , (rd_ptr == 3) , (empty == 1) , (full == 0),
        (rd_data == xx)*/
        
        //Filling Buffer - ensure write looping works
        write = '1;
        read = '0;
        for(int i = 1; i<18 ; i++) begin
            wr_data = i*(i+2);
            #10;
        end 
        
        /*Buffer is full, now try writing some more*/
        wr_data = 38;
        write = '1;
        /*Assert (full == '1)  and (wr_ptr == 3(loopback))*/
        #10;
        
        //If we read we should transition out of full state
        read = '1; 
        /*Assert (full == '0) */     
              
    end
endmodule
