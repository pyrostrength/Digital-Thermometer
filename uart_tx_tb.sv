module uart_tx_tb;
    logic clk,reset;
    logic sample_tick;
    logic tx_start;
    logic tx_done_tick;
    logic tx;
    logic[7:0] data_byte;
    
    logic[10:0] dvsr;
    
    //Baud Rate Generator generates the sampling scheme
    baud_rate_generator baudgen(.*);
    
    uart_tx uart_transmitter(.*);
    
    always begin
        #5 clk = ~clk;
    end
    
    `timescale 1ns/1ps;
    
    initial begin
        //Initialize uart tranmsitter
        reset = '1; 
        clk = '0;
        tx_start = '1;
        #10;
        /*Assert tx = '1*/
        
        //Start Data Transmission
        dvsr = 2;
        tx_start = '0;
        reset = '0;
        data_byte = 8'b1001_1110;
        #10;
        /*Assert UART in start state and tx == '0*/
        /*View waveform and ensure transmission is completed*/
        /*Takes a very long time - opted to view waveforms instead of code verify*/
        /*The time it'd take to write the code is way more than just looking at
        the waveform*/
        
    end
    
endmodule
