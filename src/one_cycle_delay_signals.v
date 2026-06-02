`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/23/2026 04:19:46 PM
// Design Name: 
// Module Name: one_cycle_delay
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


module one_cycle_delay_signals(
    input wire clk,
    input wire display_enable,
    input wire h_sync,
    input wire v_sync,
    
    output reg de_d1,
    output reg h_sync_d1,
    output reg v_sync_d1
    
    );
    
    always@(posedge clk) begin
        de_d1 <= display_enable;
        h_sync_d1 <= h_sync;
        v_sync_d1 <= v_sync;
    end
    
endmodule