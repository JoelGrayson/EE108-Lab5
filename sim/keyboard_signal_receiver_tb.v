module keyboard_signal_receiver_tb;
    reg clk, reset;

    reg ps2_clk;
    reg ps2_data;
    wire new_key;
    wire [10:0] key_code;

    // Reset and clk
    initial begin
        clk = 1'b0;
        reset = 1'b1;
        repeat (4) #5 clk = ~clk;
        reset = 1'b0;
        forever #5 clk = ~clk;
    end

    keyboard_signal_receiver dut(
        .clk(clk),
        .reset(reset),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),

        // Outputs
        .new_key(new_key),
        .key_code(key_code)
    );


    initial begin
        // Line starts idle
        ps2_clk = 1'b1;
        ps2_data = 1'b1;
        #10_000;

        // Inspired by the key S press
        // It takes 4000 clock cycles for PS2_clk to toggle

        // Pull down the data before pulling down clk (because of the setup time delay of the data)
        ps2_data = 1'b0;
        #1000;
        ps2_clk = 1'b0; //A

        #4000;
        ps2_clk = 1'b1; //ck1
        #1000;
        ps2_data = 1'b1; //B
        #3000;
        ps2_clk = 1'b0;
        #4000;
        ps2_clk = 1'b1; //C. ck2
        #4000;
        ps2_clk = 1'b0;
        #4000;
        ps2_clk = 1'b1; //ck3

        #1000;
        ps2_data = 1'b0;
        #3000;
        ps2_clk = 1'b0;
        #4000;
        ps2_clk = 1'b1; //ck4
        #1000 ps2_data = 1'b1;
        #3000 ps2_clk = 1'b0;
        #4000 ps2_clk = 1'b1; //ck5
        #4000 ps2_clk = 1'b0;
        #4000 ps2_clk = 1'b1; //ck6
        #1000 ps2_data = 1'b0;
        #3000 ps2_clk = 1'b0;
        #4000 ps2_clk = 1'b1; //ck7

        #4000 ps2_clk = 1'b0;
        #4000 ps2_clk = 1'b1; //ck8
        #4000 ps2_clk = 1'b0;
        #4000 ps2_clk = 1'b1; //ck9

        #1000 ps2_data = 1'b1;
        #3000 ps2_clk = 1'b0;

        #4000 ps2_clk = 1'b1; //ck10
        #4000 ps2_clk = 1'b0;
        #4000 ps2_clk = 1'b1; //ck11

        // That's it. Now they stay idle
        
        #10_000;



        $stop;

    end
    
    always @(*) begin 
        if (new_key == 1'b1) begin //display what the output result is
            $display("Inputted signal s which is 01101100011"); //01101100011 is indeed what the ground truth was measured to be when I pressed the S key (both from the scope and ILA in hw_ila_2)
            $display("We expect the key_code to be 11000110110, which is what was measured from the oscilloscope");
            $display("What was gotten: %b", key_code);
        end
    end
endmodule

