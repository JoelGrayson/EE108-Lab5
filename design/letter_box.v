// Starting addresses
`define A_ADDR 9'h008
`define B_ADDR 9'h010
`define C_ADDR 9'h018
`define D_ADDR 9'h020
`define E_ADDR 9'h028
`define F_ADDR 9'h030
`define G_ADDR 9'h038
`define SHARP_ADDR 9'h118
`define BLANK_LETTER 9'h100

module letter_box(
    input wire in_region,
    input wire [7:0] rel_x,
    input wire [7:0] rel_y,
    input wire [3:0] letter,
    input wire is_second_char, //if the letter is A# and is_second_char is 1, show #. if 0, show A

    output is_pixel_on
);
    // BEGIN (1) tcgrom_starting_addr from letter and is_second_char
    // Need to use a switch statement to go between letter and figuring out the note rather than using arithmetic because of the sharps (e.g., A#)
    reg [8:0] tcgrom_starting_addr;
    always @(*) begin
        casex ({ is_second_char, letter })
            {1'bx, 8'd0}: tcgrom_starting_addr = `BLANK_LETTER; //blank letter
            {1'b0, 8'd1}: tcgrom_starting_addr = `A_ADDR;
            {1'b1, 8'd1}: tcgrom_starting_addr = `SHARP_ADDR;
            {1'b0, 8'd2}: tcgrom_starting_addr = `B_ADDR;
            {1'b1, 8'd2}: tcgrom_starting_addr = `SHARP_ADDR;
            {1'b0, 8'd3}: tcgrom_starting_addr = `C_ADDR;
            {1'b1, 8'd3}: tcgrom_starting_addr = `SHARP_ADDR;
            {1'b0, 8'd4}: tcgrom_starting_addr = `D_ADDR;
            {1'b1, 8'd4}: tcgrom_starting_addr = `SHARP_ADDR;
            {1'bx, 8'd5}: tcgrom_starting_addr = `E_ADDR; //there is no E#
            {1'b0, 8'd6}: tcgrom_starting_addr = `F_ADDR;
            {1'b1, 8'd6}: tcgrom_starting_addr = `SHARP_ADDR;
            {1'b0, 8'd7}: tcgrom_starting_addr = `G_ADDR;
            {1'b1, 8'd7}: tcgrom_starting_addr = `SHARP_ADDR;
            default: tcgrom_starting_addr = `BLANK_LETTER; //for debugging, use some other letter like 9'h170, the period (.)
        endcase
    end



    // BEGIN (2) tcg_rom_addr from tcgrom_starting_addr and rel_y
    wire [8:0] tcgrom_addr = tcgrom_starting_addr + rel_y;
    wire [7:0] tcgrom_data;
    tcgrom t(
        .addr(tcgrom_addr),
        .data(tcgrom_data)
    );

    // BEGIN (3) is_pixel_on from tcg_rom_data and in_region
    assign is_pixel_on = in_region & tcgrom_data[rel_x];
endmodule

