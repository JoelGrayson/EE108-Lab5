`define WHITE 24'hFFFFFF
`define BLACK 24'h000000

`define INIT_X 11'd88
`define INIT_Y 10'd32
`define WIDTH 11'd800 // X from 88 to 888
`define HEIGHT 10'd480 // Y from 32 to 32+480=512

module wave_display (
    input clk,
    input reset,
    input [10:0] x,  // [0..1279]
    input [9:0]  y,  // [0..1023]
    input valid,
    input [7:0] read_value,
    input read_index,
    output wire [8:0] read_address,
    output wire valid_pixel,
    output wire [7:0] r,
    output wire [7:0] g,
    output wire [7:0] b
);
    // BEGIN (1)
    wire is_x_in_region = x >= `INIT_X && x <= `INIT_X + (`WIDTH / 9'd256) * 9'd256; //remove x-artifacts at end due to integer division truncation
    wire is_y_in_region = y >= `INIT_Y && y <= `INIT_Y + (`HEIGHT / 2'd2) + 15; //this ensures only one is shown (top vertical half, not just the bottom of the screen)
    // there are 256 data addresses and WIDTH variables, which means WIDTH/256 = 3.125 or 3 x-pixels per y-value. 
    assign read_address = ({ read_index, x } - `INIT_X) / (`WIDTH / 9'd256); //x_scaled. /3    
    
    // Scaled y value
    wire [7:0] y_scaled = (y - `INIT_Y) / (`HEIGHT / 9'd256); //due to integer truncation, must divide by a divided ratio
    // read_address (x_scaled) used to fetch the value based on curr x positino
    // 1 right now which is pretty useless due to integer truncatoin
    
    // Curr y position leads to y_scaled which is compared to the data coming out which is also a byte
     // END (1)
    
    // BEGIN (2)
    // Calculate curr_y from read_value
    wire [7:0] curr_y;
    assign curr_y = read_value; //old scaling: (read_value >> 1'b1) + 6'd32; // /2+32
    // END (2)

    wire [8:0] p_read_address;
    dffr #(9) p_read_address_dff(
        .d(read_address),
        .q(p_read_address),
        .clk(clk),
        .r(reset)
    );
    
    
    // BEGIN (3)
    // Remember previous y_value (curr_y) in p_y (p_ standing for previous_)
    wire [7:0] p_y;
    dffre #(8) p_y_dff(
        .d(curr_y),
        .q(p_y),
        .clk(clk),
        .r(reset),
        .en(read_address != p_read_address)
    );
    // END (3)
    
    // BEGIN (4)
    wire is_y_in_wave =
        // p_y < y < curr_y - wave going up
        (p_y <= y_scaled && y_scaled <= curr_y)
        ||
        // curr_y < y < p_y - wave going down
        (curr_y <= y_scaled && y_scaled <= p_y);
    wire is_x_beyond_artifact = !(is_x_in_region & read_address < 2'd2); //valid & first two x. used to chop off the beginning
    assign valid_pixel = is_y_in_region //in top half of screen
                         & is_x_in_region //in quadrant 1 or 2 x-wise
                         & is_y_in_wave
                         & valid
                         & is_x_beyond_artifact;
    assign { r, g, b } = `WHITE; //rgb will be blacked out if valid_pixel is false by the wave_display_top module
//     // END (4)
endmodule
