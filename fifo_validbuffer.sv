/*Modified FIFO buffer with FSM that orders two
concurrent write requests.

Motivation: In an instruction queue, validity of
each entry needs to be indicated. Using 1 FIFO 
buffer requires handling writing of new instruction's
valid bit and removing of completed instruction's valid bit.

Instead of 2 write ports, we order the write operation in
case both write requests happen at the same time.

Priority is given to removing an old instruction's valid bit.
New instruction's valid bit is stored in a register then used
in a write operation when no old instruction is being erased.

For simpler design, we assume that a previous instruction requesting a write 
and a new instruction requesting a write can never occur concurrently. 

If a new instruction is requesting a write 

This buffer size is currently limited to 16 entries.
SIZE parameter can be used to adjust the size and DW parameter
can be used to adjust the width of data in buffer*/

module fifo_validbuffer #(parameter  DW = 7,SIZE = 15)
                         (input logic clk,reset,
                          input logic write,read,
                          output logic full,empty,
                          input logic[DW:0] wr_data,
                          output logic[DW:0] rd_data);
                                      		 
                          logic[DW:0] mem_array[SIZE:0];
                          
                          /*Read and write pointers. The upper bits denote loop back
                          in the memory and are used to indicate when buffer is full or empty*/
                          logic[4:0] wr_ptr, wr_ptr_next;
                          logic[4:0] rd_ptr, rd_ptr_next;
                          
                          
                          //Register to hold prior write requests
                          logic hold_write,hold_write_next; 
                          
                          logic[DW:0] hold_data, hold_data_next;
                                	
                          typedef enum{idle,hold} state_type;
                          state_type state, state_next;
                          
                          /*If data has been sent over to PC 
                          we clear the entry. For FIFO buffers
                          this requires reading the entry and incrementing
                          the read_ptr to point to new top of the stack
                          */      
                                       
                          always_ff @(posedge clk,posedge reset)
                            if(reset) begin
                                rd_ptr <= '0;
                                wr_ptr <= '0;
                                hold_write <= '0;
                                hold_data <= '0;
                                state <= idle;
                            end
                                            
                            else begin
                                rd_ptr <= rd_ptr_next;
                                wr_ptr <= wr_ptr_next;
                                hold_write <= hold_write_next;
                                hold_data <= hold_data_next;
                                state <= state_next;
                            end
                                       
                          
                          /*Priority mechanism through if statements*/
                          always_ff @(posedge clk) 
                            /*Clearing an instruction only when clear signal is given
                            and buffer isn't empty*/
                            if(read && !empty) begin
                                mem_array[rd_ptr[3:0]] <= '0;
                            end	
                            
                            /*If no instruction is being cleared,we allow prior write
                            requests or new write request to go into the buffer*/          	
                            else if((hold_write || write) && !full) begin
                                mem_array[wr_ptr[3:0]] <= (hold_write) ? hold_data : wr_data;
                            end
                     
                                        	
                          /*State machine controlling writes to buffer*/
                          always_comb begin
                            wr_ptr_next = (write && !full) ? wr_ptr + 1 : wr_ptr;
                            hold_write_next = hold_write;
                            hold_data_next = hold_data;
                            state_next = state;
                            
                            case(state)
                                idle: begin
                                    /*If we receive a signal to clear the buffer we
                                    at the same time as an instruction requests a write
                                    we hold data relating to instruction write request and
                                    schedule the write for next clock cycle*/
                                    if(read & !empty) begin
                                        /*Simultaneous clearing and write requests*/
                                        if(write & !full) begin
                                            /*Write request hold state*/
                                            state_next = hold;
                                            wr_ptr_next = wr_ptr;
                                            hold_data_next = wr_data;
                                        	hold_write_next = 1'b1;
                                        end
                                        				
                                        else begin
                                        	hold_write_next = '0;
                                        end
                                    end
                                end
                                
                                hold: begin	
                                /*Might have some hold time violations here*/
                                /* Setup the previous write request in 1 cycle. Change in next*/
                                    hold_data_next = '0;
                                    hold_write_next = '0;
                                    state_next = idle;
                                    wr_ptr_next = wr_ptr + 1;
                                end
                            endcase
                         end
               	         
               	         //Asynchronous read
               	         assign rd_data = mem_array[rd_ptr[3:0]];
               	         
               	         /*If wr_ptr equals rd_ptr with wr_ptr  having looped around the
                         memory then buffer must be full*/
                         assign full = (wr_ptr[3:0] == rd_ptr[3:0]) && (wr_ptr[4] != rd_ptr[4]);
                         
                         /*Since wr_ptr writes data and rd_ptr clears it if
                         rd_ptr equals wr_ptr, accounting for looping, then
                         the buffer is empty*/
                         assign empty = (wr_ptr == rd_ptr);
                         
                         assign rd_ptr_next = (read && !empty) ? rd_ptr + 1 : rd_ptr;
                         
                         /*Recall a previous instruction write request and a new
                         instruction write request don't happen at the same time.
                         We need not account for case in which they do for this design*/
endmodule
                                	
                                				
                                	
