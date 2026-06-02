`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2026 06:34:01 AM
// Design Name: 
// Module Name: pipeline_delay
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

module pipeline_delay #(
    parameter INPUT_BUS_LEN = 1,
    parameter MAX_DELAY = 16
)(
    input  wire                     clk,
    input  wire                     rst,
    input  wire [INPUT_BUS_LEN-1:0]         din,
    // Runtime-selectable delay
    input  wire [$clog2(MAX_DELAY)-1:0] delay,
    output wire [INPUT_BUS_LEN-1:0]         dout
);

    // Delay storage
    reg [INPUT_BUS_LEN-1:0] shift_reg [0:MAX_DELAY-1];

    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < MAX_DELAY; i = i + 1)
                shift_reg[i] <= 0;
        end
        else begin
            // newest sample
            shift_reg[0] <= din;

            // shift older samples
            for (i = 1; i < MAX_DELAY; i = i + 1)
                shift_reg[i] <= shift_reg[i-1];
        end
    end

    // Select delayed version
    assign dout = (delay== 0) ? din : shift_reg[delay - 1];

endmodule
