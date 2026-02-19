`define WHITE 24'hFFFFFF
`define BLACK 24'h000000

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
    // x is msb (thrown away), region (2 bits), middle (7 bits), and lsb (thrown away)
    // middle and real_index are used to construct real_addr
    wire _x_lsb; //thrown away. LSB thrown away so that two x-pixels maps to one changed x-value, making the graph thicker 
    wire [2:0] x_region;
    wire [6:0] x_middle;
    assign { x_region, x_middle, _x_lsb } = x; //3+7+1=11
    
    wire is_x_in_region = (x_region == 3'b001) | (x_region == 3'b010); //used to see if valid
    
    // Assign read_addr based on x variables and read_index
    assign read_address = { read_index, x_region == 3'b010, x_middle }; //1+1+7=9
    // Commented out because you cannot use a wire with a case statement, only a wire (learned this from AI)
//    always @(*) begin
//        case (x_region)
//            2'b01: read_address = { read_index, 1'b0, x_middle }; //1 + 1 + 7 = 9 bits
//            2'b10: read_address = { read_index, 1'b1, x_middle };
//            default: read_address = 9'b0; //don't care
//        endcase
//    end
    // END (1)
    
    // BEGIN (2)
    // Calculate curr_y from read_value
    wire [7:0] curr_y;
    assign curr_y = (read_value >> 1'b1) + 6'd32; // /2+32
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
    
    wire [7:0] y_trunc = y[8:1]; //drop MSB (only top half used) and LSB (fattening) so 10 bits -> 8 bits
    
    
    // END (3)
    
    // BEGIN (4)
    wire is_y_in_region = y[9] == 0; //in top half of screen
    wire is_y_in_wave =
        // p_y < y < curr_y - wave going up
        (p_y <= y_trunc && y_trunc <= curr_y)
        ||
        // curr_y < y < p_y - wave going down
        (curr_y <= y_trunc && y_trunc <= p_y)
        ;
    wire is_x_beyond_artifact = !(x_region == 3'b001 && x_middle < 2); //chop off the beg
    assign valid_pixel = is_y_in_region //in top half of screen
                        & is_x_in_region //in quadrant 1 or 2 x-wise
                        & is_y_in_wave
                        & valid
                        & is_x_beyond_artifact;
    assign { r, g, b } = `WHITE; //rgb will be blacked out if valid_pixel is false by the wave_display_top module
    // END (4)
endmodule
