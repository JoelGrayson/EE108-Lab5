// Use this to run the code: https://www.tutorialspoint.com/compilers/online-verilog-compiler.htm

module main;
    reg [10:0] ps2_frame = 11'b00000110110;
    reg [3:0] read_bit_index = 4'd9;
    reg ps2_data = 1'b1;
    wire [10:0] new_ps2_frame = ps2_frame | ({10'b0, ps2_data} << read_bit_index);
    initial begin
        #10;
        $display("ps2_frame: %b", ps2_frame);
        $display("new_ps2_frame: %b", new_ps2_frame);
    end
endmodule

