`define WAVE_CAPTURE_STATE_WIDTH 3
`define ARMED_STATE 3'b100
`define ACTIVE_STATE 3'b010
`define WAIT_STATE 3'b001

module wave_capture (
    input clk,
    input reset,
    input new_sample_ready,
    input [15:0] new_sample_in, //16-bit note from music_player
    input wave_display_idle,

    output wire [8:0] write_address,
    output wire write_enable,
    output wire [7:0] write_sample,
    output wire read_index
);
    // State
    wire [`WAVE_CAPTURE_STATE_WIDTH-1:0] state; //current state
    reg [`WAVE_CAPTURE_STATE_WIDTH-1:0] next_state;
    dff #(`WAVE_CAPTURE_STATE_WIDTH) state_dff(
        .d(reset ? `ARMED_STATE : next_state), //default state is armed state, which it gets reset to
        .q(state),
        .clk(clk)
    );
    
    // Count
    wire [7:0] count; //current count
    reg [7:0] next_count;
    dffr #(8) count_dff( //max count is 256 (8 bits)
        .d(next_count),
        .q(count),
        .clk(clk),
        .r(reset)
    );
    
    
    dffr #(1) is_curr_sample_negative_dff(
        
        .r(reset)
    );
    
//    // Previous sample. Used to see if a positive to negative crossing occurred
//    wire [15:0] prev_sample_is_negative; //if this value is true and the current sample is positive, then go from armed to active state
//    dffre #(16) prev_sample_is_negative_dff(
//        .d(prev_sample[15]), //MSB of new_sample_in is 1 when it is negative because of two's complement
//        .q(prev_sample_is_negative), //prev_sample is written to on the next clock cycle so it always has the previous 
//        .r(),
//        .en(new_sample_ready)
//    );
    
    
    // Compute next_state
    always @(*) begin
        case (state)
            `ARMED_STATE: next_state = count
    
    // Compute next_count
    always @(*) begin
        case (state)
            `ARMED_STATE: next_count = 8'b0;
            `ACTIVE_STATE: next_count = count + 1'b1;
            `WAIT_STATE: next_count = 8'b0;
        endcase
    end
    /*
    always @(*) begin
        case ({state, count})
            {`ARMED_STATE, 7'bx}: next_count = 0;
            {`ACTIVE_STATE, }
            {`ACTIVE_STATE, }: next_count = count + 1;
        endcase
    end
    */
    
    // Outputs
    assign write_address = { ~read_index, count };
    assign write_sample = new_sample_in[15:8]; //8 most significant bits
    
    // Write enable should be true when curr == 1 and prev == 0 (about to transition to 
endmodule
