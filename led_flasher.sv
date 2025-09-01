/*
Flashes 4 LEDs for a defined time period when a control
signal goes high.

To provide an accurate estimation of desierd time period,
system clock frequency and must be specified 
when instantiating the module. Both the time period
and system clock frequency are specified via parameters.

When instantiating the module, only time periods
greater than 2x the period of the system clock are allowed.
The time period is specified in seconds and frequency in Hz.

*/

module led_flasher    (input logic clk,reset,
                       output logic[3:0] led_on,
                       input logic control);
                       
                       parameter SYS_FREQ = 100000000;
                       parameter PERIOD = 20;
                       
                       localparam int MAX = SYS_FREQ * PERIOD;
                       
                       typedef enum{idle,run} state_type;
                       state_type state, state_next;
                       
                       logic[31:0] max_count;
                       assign max_count = MAX;
                       
                       logic[31:0] count, count_next;
                       
                       always_ff @(posedge reset,posedge clk)
                            if(reset) begin
                                count <= '0;
                                state <= idle;
                            end
                            
                            else begin
                                count <= count_next;
                                state <= state_next;
                            end
                       
                       always_comb begin
                            count_next = '0;
                            led_on = '0;
                            case(state)
                                idle:begin
                                    /*As soon as signal is received to stop sending
                                    we immediately light up the LEDS and start the counter*/
                                    if(control) begin
                                        count_next = count + 1;
                                        state_next = run;
                                        led_on = '1;
                                    end
                                end
                                
                                run:begin
                                    led_on = '1;
                                    count_next = count + 1;
                                    if(count == max_count - 1) begin
                                        state_next = idle;
                                        count_next = '0;
                                    end
                                end
                            endcase
                       end
                                 
endmodule
