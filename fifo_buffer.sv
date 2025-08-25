/*Fifo buffer implemented as a circular queue.
Fifo buffer entry is "cleared" on write_ptr increment*/

module fifo_buffer#(PARAMETER  DW = 7)
                                      (input logic clk,reset,
                                       input logic write,transmit_complete,
                                       output logic full,empty,
                                       input logic[DW:0] wr_data,
                                       output logic[DW:0] rd_data);
                                       
                                       logic[DW:0] mem_array[15:0]; //16 entry mem array of logic vectors with width DW.
                                       logic[4:0] wr_ptr, wr_ptr_next;
                                       logic[4:0] rd_ptr, rd_ptr_next;
                                       logic read;
                                       
                                       assign read = transmit_complete;
                                       
                                       always_ff @(posedge clk,posedge reset)
                                            if(reset) begin
                                                rd_ptr <= '0;
                                                wr_ptr <= '0;
                                            end
                                            
                                            else begin
                                                rd_ptr <= rd_ptr_next;
                                                wr_ptr <= wr_ptr_next;
                                            end
                                        
                                        always_ff @(posedge clk) 
                                        	if(write) begin
                                        		mem_array[wr_ptr[3:0]] <= wr_data;
                                        	end	
                                
                                	
                                	assign full = (wr_ptr[3:0] == rd_ptr[3:0]) && wr_ptr[4] == 1'b1;
                                	assign empty = (wr_ptr[3:0] == rd_ptr) && (!full);
                                	assign rd_data = mem_array[rd_ptr];
                                	
                                	assign rd_ptr_next = (read & !empty) ? rd_ptr + 1 : rd_ptr; //Prevent rd_ptr increments if empty
                                	assign wr_ptr_next = (write & !full) ? wr_ptr + 1 : wr_ptr; //Prevent wr_ptr increments if full
endmodule
                                		
                                                
                                      
                                      
                                      
                                      
