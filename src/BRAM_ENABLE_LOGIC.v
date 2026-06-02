`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/25/2026 11:22:33 PM
// Design Name: 
// Module Name: BRAM_READ_ADDRESS_LOGIC
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


module BRAM_READ_ADDRESS_LOGIC(
    input [11:0] x,
    input [11:0] y,
    input display_enable,
    output bram_enable,
    output [31:0] bram_read_address
    );
    
    assign bram_enable = ((x < 300 && y < 300) & display_enable) ? 1'b1 : 1'b0;

    // multiply by 4 for byte offset not word index
    assign bram_read_address = ((x < 300 && y < 300 )& display_enable) ? ((y * 300 + x) << 2) : 32'b0;
endmodule
