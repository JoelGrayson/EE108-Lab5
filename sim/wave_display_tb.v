module wave_display_tb;
    reg clk;
    reg reset;
    // Simulating signals from the vga driver
    reg [10:0] x;
    reg [9:0] y;
    reg valid;
    // Simulating signals to/from RAM
    wire [7:0] read_value;
    wire [8:0] read_address;
    // Simulating signal from wave_capture
    reg read_index;
    
    wire valid_pixel;
    wire [7:0] r, g, b;
    
    wave_display dut(
        .clk(clk),
        .reset(reset),
        .x(x),
        .y(y),
        .valid(valid),
        .read_value(read_value),
        .read_index(read_index),
        .read_address(read_address),
        .valid_pixel(valid_pixel),
        .r(r),
        .g(g),
        .b(b)
    );
    
    fake_sample_ram ram(
        .clk(clk),
        .addr(read_address),
        .dout(read_value)
    );
    
    
    integer cycle; //learned about these from AI
    initial cycle = 0;
    
    always begin
        clk = 1'b1;
        #5;
        clk = 1'b0;
        #5;
        cycle = cycle + 1;
    end
    
    initial begin
        #1;
        // In the middle of cycle 0. Setting up variablesr for cycle 1
        reset = 1'b1;
        #10;
        // In the middle of cycle 1. Setting up variables for cycle 2
        reset = 1'b0;
        x = 0; //start crawling up
        y = 3;
        valid = 1'b1;
        read_index = 1'b0;
        // read_value from RAM
        
        // Imagine as a 5 by 5 display
        
        #10 x = 1; y = 0;
        #10 x = 2;
        #10 x = 3;
        #10 x = 4;
        #10 x = 5;
        $display("Finished y = 0 on cycle %d", cycle);
        
        #10 x = 1; y = 1;
        #10 x = 2;
        #10 x = 3;
        #10 x = 4;
        #10 x = 5;
        $display("Finished y = 1 on cycle %d", cycle);

        #10 x = 1; y = 2;
        #10 x = 2;
        #10 x = 3;
        #10 x = 4;
        #10 x = 5;
        $display("Finished y = 2 on cycle %d", cycle);
        
        #10 x = 1; y = 3;
        #10 x = 2;
        #10 x = 3;
        #10 x = 4;
        #10 x = 5;
        $display("Finished y = 3 on cycle %d", cycle);
        
        #10 x = 1; y = 4;
        #10 x = 2;
        #10 x = 3;
        #10 x = 4;
        #10 x = 5;
        $display("Finished y = 4 on cycle %d", cycle);
        
        #10 x = 1; y = 5;
        #10 x = 2;
        #10 x = 3;
        #10 x = 4;
        #10 x = 5;
        $display("Finished y = 5 on cycle %d", cycle);
    end
endmodule
