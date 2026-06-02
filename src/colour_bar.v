`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2026 03:24:17 AM
// Design Name: 
// Module Name: 
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
`timescale 1ns / 1ps
module HDMI_timing_generator #(
    //enums
    parameter horizontal_pixels = 1920,
    parameter vertical_pixels = 1080
) (
    input wire pixel_clk, 
    input wire reset_n,
    output reg h_sync,   // active low h sync
    output reg v_sync,   // active low v sync (indicates end of frame)
    output reg display_enable, // indicates if we are in the "active" region of the pixel area
    output reg [11:0] pixel_x,
    output reg [11:0] pixel_y
);

localparam H_ACTIVE_REGION =
    (horizontal_pixels == 1920 && vertical_pixels == 1080) ? 1920 :
    (horizontal_pixels == 1280 && vertical_pixels == 720)  ? 1280 :
                                800;

localparam H_FRONT_PORCH =
    (horizontal_pixels == 1920 && vertical_pixels == 1080) ? 88 :
    (horizontal_pixels == 1280 && vertical_pixels == 720)  ? 110 :
                                40;

localparam H_SYNC =
    (horizontal_pixels == 1920 && vertical_pixels == 1080) ? 44 :
    (horizontal_pixels == 1280 && vertical_pixels == 720)  ? 40 :
                                128;

localparam H_BACK_PORCH =
    (horizontal_pixels == 1920 && vertical_pixels == 1080) ? 148 :
    (horizontal_pixels == 1280 && vertical_pixels == 720)  ? 220 :
                                88;
// Vertical settings
localparam V_ACTIVE_REGION =
    (horizontal_pixels == 1920 && vertical_pixels == 1080) ? 1080:
    (horizontal_pixels == 1280 && vertical_pixels == 720)  ? 720:
                                600;

localparam V_FRONT_PORCH =
    (horizontal_pixels == 1920 && vertical_pixels == 1080) ? 4 :
    (horizontal_pixels == 1280 && vertical_pixels == 720)  ? 5 :
                                1;

localparam V_SYNC =
    (horizontal_pixels == 1920 && vertical_pixels == 1080) ? 5 :
    (horizontal_pixels == 1280 && vertical_pixels == 720)  ? 5 :
                                4;

localparam V_BACK_PORCH =
    (horizontal_pixels == 1920 && vertical_pixels == 1080) ? 36 :
    (horizontal_pixels == 1280 && vertical_pixels == 720)  ? 20 :
                                23;

    // note that the these are 1 more than the max pixel count in either direction
    localparam H_TOTAL_PIXELS = H_ACTIVE_REGION + H_FRONT_PORCH + H_SYNC + H_BACK_PORCH;
    localparam V_TOTAL_PIXELS = V_ACTIVE_REGION + V_FRONT_PORCH + V_SYNC + V_BACK_PORCH;
    
    localparam H_SYNC_BEGIN = 0;
    localparam H_SYNC_END= H_SYNC;
    
    localparam V_SYNC_BEGIN = 0;
    localparam V_SYNC_END= V_SYNC;
    
    localparam H_ACTIVE_REGION_START = H_SYNC_END + H_BACK_PORCH;
    localparam H_ACTIVE_REGION_END = H_ACTIVE_REGION_START + H_ACTIVE_REGION;
    
    localparam V_ACTIVE_REGION_START = V_SYNC_END + V_BACK_PORCH;
    localparam V_ACTIVE_REGION_END = V_ACTIVE_REGION_START + V_ACTIVE_REGION;
    
    reg [11:0] h_count = 0; //horizontal position
    reg [11:0] v_count = 0; // vertical position
//    wire next_cyle_is_in_active_region;
//    reg pixel_data_req; // request pixel data one clock ahead of time (for the next cycle)
    
    /* Intuitively, it makes sense to think of each scan line for VGA as (active -> front porch -> sync -> back porch). This allows a counter value of 0
       to be pixel 0,0 at the top left. However, a more conventional layout is: (sync -> back porch -> active -> front porch). This is less intuitive but
       may be more stable for allowing the monitor to (correctly) detect the resolution
    */

    always @(posedge pixel_clk or negedge reset_n) begin
        if(~reset_n)begin
            h_count <= 12'd0;
            v_count <= 12'd0;
            display_enable<= 1'b0;
        end
        else begin 
            if (h_count < H_TOTAL_PIXELS - 1'b1)
                h_count <= h_count + 1;
            else begin
                h_count <= 0;
                if (v_count < V_TOTAL_PIXELS - 1'b1)
                    v_count <= v_count + 1;
                else
                    v_count <= 0;
            end
            // sync signals are active low and idle high
            h_sync <= (h_count >= H_SYNC_BEGIN && h_count < H_SYNC_END) ? 1'b0 : 1'b1;
            v_sync <= (v_count >= V_SYNC_BEGIN && v_count < V_SYNC_END) ? 1'b0 : 1'b1;
            
            display_enable <= ((h_count >= H_ACTIVE_REGION_START && h_count < H_ACTIVE_REGION_END)
                            && (v_count >= V_ACTIVE_REGION_START && v_count < V_ACTIVE_REGION_END)) ? 1'b1:1'b0;
                            
            // subtract 1 from active region to indicate the next cycle is in the valid region                            
//            pixel_data_req <= ((h_count >= H_ACTIVE_REGION_START -1'b1) && (h_count < H_ACTIVE_REGION_END -1'b1)                          
//                &&(v_count >= V_ACTIVE_REGION_START -1'b1) && (v_count < V_ACTIVE_REGION_END -1'b1))? 1'b1:1'b0;
            pixel_x <= (display_enable) ? h_count - H_ACTIVE_REGION_START : 0;
            pixel_y <= (display_enable) ? v_count - V_ACTIVE_REGION_START  : 0; 
     end
    
    end
endmodule
