`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2026 09:57:29 PM
// Design Name: 
// Module Name: BRAM_framebuffer
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

module BRAM_framebuffer#(
    // dimensions of the VISIBLE AREA OF THE SCREEN, not the display resolution (rest is black)
    parameter WIDTH  = 800,
    parameter HEIGHT = 600
)(
    input  wire        clk,

    input  wire [11:0] pixel_x,
    input  wire [11:0] pixel_y,
    input  wire display_en,

    output reg  [7:0]  r,
    output reg  [7:0]  g,
    output reg  [7:0]  b
);

    localparam ADDR_WIDTH = 19; // enough for 800x600 (~19 bits)

    wire [ADDR_WIDTH-1:0] addr;
    assign addr = pixel_y * WIDTH + pixel_x;

    // BRAM
    reg [23:0] bram [0: WIDTH * HEIGHT - 1];
    
    integer i, j;
    initial begin
        for (i = 0; i < WIDTH; i = i + 1) begin
            for (j = 0; j < HEIGHT; j = j +1) begin
                if (j == 0 || j == HEIGHT -1 || i == 0 || i == WIDTH - 1)
                    bram[j * WIDTH + i] = 24'hffffff;
                else
                    bram[j * WIDTH + i] = 24'h000000;
            end
        end
    end
    
    // colour strip test
//    for (i = 0; i < WIDTH; i = i + 1) begin
//            for (j = 0; j < HEIGHT; j = j +1) begin
//                if (i < (WIDTH / 4))
//                    bram[j * WIDTH + i] = 24'hff0000; //red
//                else if (i < (2 * WIDTH / 4))
//                    bram[j * WIDTH + i] = 24'h00ff00; // green
//                else if(i < (3 * WIDTH / 4))
//                    bram[j * WIDTH + i] = 24'h0000ff; // blue
//                else 
//                    bram[j * WIDTH + i] = 24'h11249c; // deep blue
//            end
//        end

    // read pipeline (BRAM is synchronous)
    reg [23:0] pixel_d;
    reg display_enable_reg;

    always @(posedge clk) begin
        display_enable_reg <= display_en;
        
        if (display_en && pixel_x < WIDTH && pixel_y < HEIGHT) 
            pixel_d <= bram[pixel_y * WIDTH + pixel_x];
        else
            pixel_d <= 0;
    end

    // one clock cycle later values should be available
    always @(posedge clk) begin
        if (display_enable_reg) begin
            r <= pixel_d[23:16];
            g <= pixel_d[15:8];
            b <= pixel_d[7:0];
        end else begin
            r <= 0;
            g <= 0;
            b <= 0;
        end
    end

endmodule