`timescale 1ns/1ps

// Try inputting A# in note_text_display with .is_second_char(0) and seeing that when you do the appropriate x and y values it is indeed setting the correct is_pixel_on values. Try it with .is_second_char(1) and see that it is showing a # sign.

module letter_box_tb;
    reg in_region;
    reg [7:0] rel_x, rel_y;
    reg [3:0] letter;
    reg is_second_char;
    wire is_pixel_on;
    
    letter_box dut(
        .in_region(in_region),
        .rel_x(rel_x),
        .rel_y(rel_y),
        .letter(letter),
        .is_second_char(is_second_char),
        .is_pixel_on(is_pixel_on)
    );
    
    wire expected_is_pixel_on;
    
    initial begin
        in_region = 1'b1; //for the purposes of this testbench I am going to set to 1
        is_second_char = 1'b0;
        letter = 1; //A

        rel_x = 0;
        rel_y = 0;

        #10;
        
        $display("dut.tcgrom_starting_addr is %h. Expected 0x008", dut.tcgrom_starting_addr);
        expected = 1'b0;
        if (is_pixel_on != expected_is_pixel_on) $display("is_pixel_on should be %b but got %b", expected_is_pixel_on, is_pixel_on);
        
    end
endmodule

