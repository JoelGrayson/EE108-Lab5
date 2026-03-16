`timescale 1ns/1ps

// Try inputting A# in note_text_display with .is_second_char(0) and seeing that when you do the appropriate x and y values it is indeed setting the correct is_pixel_on values. Try it with .is_second_char(1) and see that it is showing a # sign.

module letter_box_tb();
    reg clk, reset;
    reg [7:0] x_scaled, y_scaled, curr_y;
    reg in_region;
    wire is_pixel_on;
    
    note_text_display dut(
        .clk(clk),
        .reset(reset),
        .x_scaled(x_scaled),
        .y_scaled(y_scaled),
        .valid(valid),
        .read_value(read_value),
        .read_index(read_index),
        .read_address(read_address),
        .valid_pixel(valid_pixel),
        .r(r), .g(g), .b(b)
    );
   
    // Clock and reset
    initial begin
        clk = 1'b0;
        reset = 1'b1;
        repeat (4) #5 clk = ~clk;
        reset = 1'b0;
        forever #5 clk = ~clk;
    end
   
    initial begin
        x = 11'b00000000000;
        y= 10'b0000000000;
        valid = 1;
        read_index = 0;
        #10
       
        forever begin
            repeat (1279) #10 x = x + 1;
            #10
            x = 0;
            y = y+1;
        end
       
        #100
        $stop;
    end
    /*
    initial begin
        // since read_address should be 0, this should cause r,g,b to be 00, ff, 00, but valid pixel should be low
        x = 11'b00000000000;
        y= 10'b0000000000;
        valid = 1;
        read_index = 0;
        #100
       
        // same as previous, but valid pixel should now be high
        x = 11'b00100000000;
        y= 10'b0000000000;
        #100
       
        // valid pixel should still be high since x[7:1] hasn't changed
        x = 11'b00100000001;
        y= 10'b0000000000;
        #100
       
        // valid pixel should now be low since y is not in bounds
        x = 11'b00100000001;
        y= 10'b1000000000;
        #100
       
        // read_value should be 00000001, prev_read_value should be 00000000, so r,g,b should be 00,ff,00 for one cycle
        // while y_coord is in the range, then read_value and prev_read_value will both be 00000001 so r,g,b should go to
        // 00,00,00
        x = 11'b00100000100;
        y= 10'b0000000000;
        #100
       
        // this new y value should be back in the range of x(n) and x(n-1), so r,g,b should be 00,ff,00 for a cycle
        x = 11'b00100001000;
        y= 10'b0000000010;
        #100
       
        // this new y value should be back in the range of x(n) and x(n-1), so r,g,b should be 00,ff,00 for a cycle
        // test for next quadrant of x
        x = 11'b01000001000;
        y= 10'b0010000010;
        #100
       
        // this new y value should be back in the range of x(n) and x(n-1), so r,g,b should be 00,ff,00 for a cycle
        // test for read_index high
        read_index =  1;
        x = 11'b01000001000;
        y= 10'b0110000010;
        #100
       
        // vga coordinates invalid should bring valid_pixel low
        valid = 0;
        #100
        valid = 1;
       
        // valid pixel should be high for the case x[10:8] = 010 as well
        x = 11'b01000000001;
        y= 10'b0000000000;
        #100
       
        // valid pixel should be low for the case x[10:8] = 100
        x = 11'b10000000001;
        y= 10'b0000000000;
        #100
       
        $stop;
    end
    */
endmodule