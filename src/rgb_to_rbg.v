`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/26/2026 03:57:42 AM
// Design Name: 
// Module Name: rgb_to_rbg
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


module rgb_to_rbg(
    input wire [23:0] rgb,
    output wire [23:0] rbg
    );
    
    assign rbg = {rgb[23:16], rgb[7:0], rgb[15:8]};
endmodule
