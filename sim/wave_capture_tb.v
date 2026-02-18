`timescale 1ns/1ps

`define WAVE_CAPTURE_STATE_WIDTH 3
`define ARMED_STATE 3'b100
`define ACTIVE_STATE 3'b010
`define WAIT_STATE 3'b001

module wave_capture_tb;
    // Inputs (controlled by tb)
    reg clk;
    reg reset;
    reg new_sample_ready;
    reg [15:0] new_sample_in;
    reg wave_display_idle;
    
    // Outputs controlled by wave_capture
    wire [8:0] write_address;
    wire write_enable;
    wire [7:0] write_sample;
    wire read_index;    
    
    wave_capture dut(
        .clk(clk),
        .reset(reset),
        .new_sample_ready(new_sample_ready),
        .new_sample_in(new_sample_in),
        .wave_display_idle(wave_display_idle),
        .write_address(write_address),
        .write_enable(write_enable),
        .write_sample(write_sample),
        .read_index(read_index)
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
        #9; //set variables in the middle of a cycle. Gives #1 for the variable to settle before the next clock cycle
        // In the middle of cycle 0. Setting up variablesr for cycle 1
        reset = 1'b1;
        #10;
        // In the middle of cycle 1. Setting up variables for cycle 2
        reset = 1'b0;
        new_sample_ready = 1'b0;
        new_sample_in = 16'b0;
        wave_display_idle = 1'b0;
        

        #10;
        // State should be armed
        if (dut.state != `ARMED_STATE)
            $display("Test 1 failed");
        #10;
        // In the middle of cycle 3. Setting up variables for cycle 4
        new_sample_ready = 1'b1;
        new_sample_in = 16'b111_0_0000_0000_0000;
        
        #10; //in cycle 4
        new_sample_ready = 1'b0;
        if (dut.curr_sample != 16'b1110_0000_0000_0000)
            $display("Test 2 failed");
        
        #90; //in cycle 13. Settign up for cycle 14
        new_sample_in = 16'b110_0_0000_0000_0000;
        new_sample_ready = 1'b1;
        #10;
        new_sample_ready = 1'b0;
        
        #90; //in cycle 23. Setting up for cycl 24
        new_sample_in = 16'b010_0_0000_0000_0000;
        new_sample_ready = 1'b1;
        #10;
        new_sample_ready = 1'b0;
        
        
        // Should have triggered shift
        repeat (258) begin
            #90;
            new_sample_in = { cycle[7:0], 8'b1111_0000 }; //this way the sample is different every time due to cycle
            new_sample_ready = 1'b1;
            #10;
            new_sample_ready = 1'b0;
        end
        
        $finish;
    end
endmodule