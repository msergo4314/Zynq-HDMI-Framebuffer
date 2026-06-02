`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/26/2026 06:27:52 PM
// Design Name: 
// Module Name: dummy_bram_out
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


module dummy_bram_out(
    input wire pixel_clk,
    input wire bram_enable,
    input wire [11:0] x,
    input wire [11:0] y,
    output [23:0] dummy_colour_out
    );
    
    reg [23:0] out1, out2;
    
    always@(posedge pixel_clk) begin
        out1 <= (x == 0 && y == 0 && bram_enable) ? 24'hff0000 : 24'h000000;
        out2 <= out1;
    
    end
    
    assign dummy_colour_out = out2;
endmodule
