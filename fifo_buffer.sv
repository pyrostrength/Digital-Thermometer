/*Fifo buffer implemented as a circular queue.
Has synchronous write and asynchronous read.

Fifo buffers size and data width can be configured
through the SIZE and DW parameters*/

module fifo_buffer#(parameter DW = 7, SIZE = 15)
                   (input logic clk,reset,
                    input logic write,read,
                    output logic full,empty,
                    input logic[DW:0] wr_data,
                    output logic[DW:0] rd_data);
                    
                                       
                    logic[DW:0] mem_array[SIZE:0]; /*16 entry mem array of logic vectors with 
                    width DW.*/
                    
                    /*Read and write pointers. The upper bits denote loop back
                    in the memory and are used to indicate when buffer is full or empty*/
                    logic[4:0] wr_ptr, wr_ptr_next;
                    logic[4:0] rd_ptr, rd_ptr_next;
                    
                    /*If data has been sent over to PC 
                    we clear the entry. For FIFO buffers
                    this requires reading the entry and incrementing
                    the read_ptr to point to new top of the stack
                    */                
                    
                                     
                    always_ff @(posedge clk,posedge reset)
                        if(reset) begin
                            rd_ptr <= '0;
                            wr_ptr <= '0;
                        end
                        
                        else begin
                            rd_ptr <= rd_ptr_next;
                            wr_ptr <= wr_ptr_next;
                        end
                    
                    //Synchronous write                   
                    always_ff @(posedge clk) 
                        /*Only write to the buffer if buffer isn't full and
                        a write was requested*/
                        if(write & !full) begin
                            mem_array[wr_ptr[3:0]] <= wr_data;
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
                                	
                    //Only increment rd_ptr if a read was requested on non-empty buffer            	
                    assign rd_ptr_next = (read & !empty) ? rd_ptr + 1 : rd_ptr;
                    
                    //Only increment wr_ptr if a write was requested on non-full buffer
                    assign wr_ptr_next = (write & !full) ? wr_ptr + 1 : wr_ptr;
endmodule
                                		
                                                
                                      
                                      
                                      
                                      
