`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/26/2026 12:22:23 AM
// Design Name: 
// Module Name: mux2
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


module mux2(
    input wire [23 : 0] a, // when select is 0
    input wire [23 : 0] b, // when select is 1
    input wire select_line,
    output [23:0] y
    );
    
    assign y = (select_line == 0) ? a : b;
endmodule
