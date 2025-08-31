`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/25/2025 09:17:38 AM
// Design Name: 
// Module Name: dual_portram
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dual_portram(
    input logic clk,
    input logic reset,
    input logic[7:0] data_in,
    output logic[7:0] data_out,
    input logic[8:0] address_a,address_b,r_address,
    input logic ena,
    input logic enb
    );
    
    logic[7:0] mem_array[255:0];
    
    always_ff @(posedge clk,posedge reset) 
        if(ena)
            mem_array[address_a] <= data_in;
        
    always_ff @(posedge clk, posedge reset)    
        if(enb)
            mem_array[address_b] <= '0;
           
    
    assign data_out = mem_array[r_address];
            
endmodule
