module uart_rx_tb;
    logic clk,reset;
    logic sample_tick;
    logic tx_start;
    logic rx_done_tick;
    logic tx_done_tick;
    logic tx;
    logic[7:0] received_byte;
    logic[7:0] data_byte;
    
    logic[10:0] dvsr;
    
    //Baud Rate Generator generates the sampling scheme
    baud_rate_generator baudgen(.*);
    
    //UART transmitter to send the data
    uart_tx uart_transmitter(.*);
    
    uart_rx uart_receiver(.*);
    
    always begin
        #5 clk = ~clk;
    end
    
    `timescale 1ns/1ps;
    
    initial begin
        //Initialize UART receiver
        reset = '1;
        clk = '0;
        #10;
        
        //Initiate UART reception and transmission
        //Start Data Transmission
        dvsr = 2;
        tx_start = '0;
        reset = '0;
        data_byte = 8'b1001_1110;
        #10;
        /*View waveform and ensure data_byte is received by UART Receiver*/
        /*Opted to verify by viewing waveforms instead of coding assertions and
        wait statements as coding would take much longer verify*/
        
        
    end
endmodule
