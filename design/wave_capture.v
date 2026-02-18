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
    
    
    // DFFs that are a chain of delayed from new_sample
    // Current sample
    wire [15:0] curr_sample;
    dffre #(16) curr_sample_dff(
        .d(new_sample_in),
        .q(curr_sample),
        .en(new_sample_ready),
        .r(reset)
    );
    
    // prev_sample
    wire [15:0] prev_sample;
    dffre #(16) prev_sample_dff( //delayed by another cycle from curr_sample_dff
        .d(curr_sample),
        .q(prev_sample),
        .en(new_sample_ready),
        .r(reset)
    );
    wire is_curr_sample_negative = curr_sample[15];
    wire is_prev_sample_negative = prev_sample[15];
    
    
    // Compute next_state
    always @(*) begin
        case (state)
            `ARMED_STATE: next_state = (!is_curr_sample_negative && is_prev_sample_negative) ? `ACTIVE_STATE : `ARMED_STATE;
            `ACTIVE_STATE: next_state = (count == 8'd255 && new_sample_ready) ? `WAIT_STATE : `ACTIVE_STATE;
            `WAIT_STATE: next_state = wave_display_idle ? `ARMED_STATE : `WAIT_STATE;
            default: next_state = `ARMED_STATE;
        endcase
    end
    
    // Compute next_count
    always @(*) begin
        case (state)
            `ARMED_STATE: next_count = 8'b0;
            `ACTIVE_STATE: next_count = count + 1'b1;
            `WAIT_STATE: next_count = 8'b0;
            default: next_count = 8'b0;
        endcase
    end
    
    // Outputs
    assign write_address = { ~read_index, count };
    assign write_sample = curr_sample[15:8]; //so 1-cycle delay. When new_sample_ready occurs, new_sample is the new value so we need the curr_sample
    assign write_en = new_sample_ready & state == `ACTIVE_STATE;
endmodule
