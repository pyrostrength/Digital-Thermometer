module baudgen_tb;
    
    //Signals for baud rate generator
    logic clk,reset;
    logic[10:0] dvsr;
    logic sample_tick;
    
    
    baud_rate_generator baudgen(.*);
    
    `timescale 1ns/1ps;
    
    always begin
        #5 clk = ~clk;
    end
    
    initial begin
        reset = '1;
        clk = '0;
        
        #10; //Wait 1 period; observe internal counter register to ensure value is at 0;
        
        dvsr = 4; //Counter counts up to 4 and then resets
        reset = '0; //Clear reset signal
        
        //Observe tick after 4 cycles
        #40
        assert(sample_tick == 1'b1); //Assertion passed via waveform viewing
        
        //Sample tick must go low in new cycle
        #10
        assert(sample_tick == '0); //Assertion passed via waveform viewing
        
        /*If dvsr changes simulation then time point at which
        sample tick goes high changes. Thus for an increase in
        dvsr value..*/
        #10
        dvsr = 8;
        
        #20
        assert(sample_tick == '0); //Assertion passed via waveform viewing
    end
    
    
endmodule
