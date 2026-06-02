`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/26/2026 12:57:06 AM
// Design Name: 
// Module Name: delay_one_cycle
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


module delay_one_cycle(
    input signal_to_delay,
    input wire clock,
    output reg reg_in
    );
    
    always@(posedge clock) begin
        reg_in <= signal_to_delay;
    end
endmodule
