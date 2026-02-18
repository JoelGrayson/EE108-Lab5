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
    wire x_msb, x_lsb; //thrown away
    wire [1:0] x_region;
    wire [6:0] x_middle; //1+2+7+1=11
    assign { x_msb, x_region, x_middle, x_lsb } = x;
    
    wire is_x_in_region = (x_region == 2'b01) | (x_region == 2'b10); //used to see if valid
    
    // Assign read_addr based on x variables and read_index
    assign read_address = { read_index, x_region == 2'b10, x_middle };
    
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
    wire [5:0] curr_y;
    wire y_msb; //only when y_msb == 0 is it drawn
    wire _y_lsb; //thrown out so starting with _ makes you remember it is not used
    assign { y_msb, curr_y, _y_lsb } = read_value; //read_val is 8 bits, so curr_y is 6 bits. Since double pixel heigth it is 128 pixels which is ok I guess
    // END (2)
    
    // BEGIN (3)
    // Remember previous y_value (curr_y) in p_y (p_ standing for previous_)
    wire [5:0] p_y;
    dffr #(6) p_y_dff(
        .d(curr_y),
        .q(p_y),
        .clk(clk),
        .r(reset)
    );
    
    // END (3)
    
    // BEGIN (4)
    wire is_y_in_region = y[9] == 0;
    wire is_y_in_wave =
        // p_y < y < curr_y - wave going up
        (p_y < y && y < curr_y)
        ||
        // curr_y < y < p_y - wave going down
        (curr_y < y && y << p_y)
        ;
    assign valid_pixel = is_y_in_region & is_x_in_region; //1'b1;//is_y_in_region & is_y_in_wave & is_x_in_region & valid;
    assign { r, g, b } = valid_pixel ? `WHITE : `BLACK;
    // END (4)
endmodule
