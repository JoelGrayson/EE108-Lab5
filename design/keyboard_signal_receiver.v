`define STATE_WIDTH 3
`define IDLE_STATE 3'b100
`define SAVING_INPUT_STATE 3'b010 //uses read_bit_index
`define TRANSMIT_KEY_STATE 3'b001
`define DEFAULT_STATE `IDLE_STATE
`define NUMBER_OF_CLK100_CYCLES_IN_A_PS2_CLK_CYCLE 8000 //was close to 8200
`define CYCLE_TIMEOUT 3*`NUMBER_OF_CLK100_CYCLES_IN_A_PS2_CLK_CYCLE //3*8000 is 24,000 which fits in 16 bits


module keyboard_signal_receiver(
    input wire clk,
    input wire reset,

    // Passed down from the .xdc file (PMOD)
    input wire ps2_clk, //ps2_clk_in
    input wire ps2_data,

    output wire new_key, //one-pulse indicating new key pressed and new note should be played
    output wire [10:0] key_code //11 bits
);
    // Use ILA to record the signal coming from the keyboard in real life to ensure there is no debouncing necessary
    // Shows what the oscilloscope would have read
    ila_0 oscilloscope_reader ( //my_ila_for_debugging_ps2
        .clk(clk), // input wire clk (clk100)
        .probe0(ps2_clk), // input wire [0:0]  probe0  
        .probe1(ps2_data), // input wire [0:0]  probe1 
        .probe2(state), // input wire [2:0]  probe2 
        .probe3(key_code), // input wire [10:0]  probe3 
        .probe4(read_bit_index), // input wire [3:0]  probe4 
        .probe5(new_key) // input wire [0:0]  probe5
    );


    // Save the previous clock signal so you can see if the clock signal is rising
    wire p_ps2_clk;
    dffr #(1) p_ps2_clk_dff(
        .d(ps2_clk),
        .q(p_ps2_clk),
        .clk(clk),
        .r(reset)
    );


    // State (control)
    wire [2:0] state; //current state. 100 is IDLE, 010 is SAVING_INPUT, and 001 is TRANSMIT_KEY
    reg [2:0] next_state;

    dff #(`STATE_WIDTH) state_dff(
        .clk(clk),
        .d(reset ? `DEFAULT_STATE : next_state),
        .q(state)
    );
    
    
    
    // Number of read bits. 0 to 11
    wire [3:0] read_bit_index; //enough memory for 0 to 16
    reg [3:0] next_read_bit_index;
    // When ps2_clk goes up, this should increment if in the SAVING_INPUT state
    always @(*) begin
        casex ({p_ps2_clk, ps2_clk, state})
            {1'b0, 1'b1, `SAVING_INPUT_STATE}: next_read_bit_index = read_bit_index + 1'b1; //clock rose in the saving_input state
            {1'bx, 1'bx, `SAVING_INPUT_STATE}: next_read_bit_index = read_bit_index; //otherwise, just keep the next_read_bit the same
            default: next_read_bit_index = 4'b0;
        endcase
    end
    dffr #(4) read_bit_index_dff(
        .clk(clk),
        .r(reset),
        .d(next_read_bit_index),
        .q(read_bit_index)
    );


    // Compute next state
    always @(*) begin
        casex ({state,            p_ps2_clk, ps2_clk, read_bit_index, reset_to_idle_flag})
            {3'bx,                1'bx,      1'bx,   {4{1'bx}}, 1'b1 }: next_state = `IDLE_STATE;
            // The following lines are about advancing the state (incrementing). Otherwise, it stays at the same state because of the default case
            {`IDLE_STATE,         1'b1,      1'b0,   {4{1'bx}}, 1'b0 }: next_state = `SAVING_INPUT_STATE;
                // in IDLE state but the clk just went down so now it's time for capture
            {`SAVING_INPUT_STATE, 1'bx,      1'bx,   4'd11,     1'b0}: next_state = `TRANSMIT_KEY_STATE; //once at the 11th signal, all signals have been read so it's time to transmit the key
            {`TRANSMIT_KEY_STATE, 1'bx,      1'bx,   {4{1'bx}}, 1'b0 }: next_state = `IDLE_STATE; //only for one cycle does it need to pulse to show the key
            default: next_state = state;
        endcase
    end


    // The data from the PS/2. Comes in 11 bit packet.
    reg [10:0] next_key_code;
    dffr #(11) ps2_seq_dff(
        .d(next_key_code),
        .q(key_code),
        .clk(clk),
        .r(reset)
    );


    // Calculate the next key_code. Should be if in IDLE_STATE changing based on read_bit_index
    always @(*) begin
        casex ({reset, state, p_ps2_clk, ps2_clk})
            {1'b1, { 5{1'bx} } }: next_key_code = 11'b0; //should be 0 when reset
            {1'b0, `IDLE_STATE, 1'bx, 1'bx}: next_key_code = 11'b0; //should be 0 when idle
            {1'b0, `SAVING_INPUT_STATE, 1'b0, 1'b1}: next_key_code = key_code | (ps2_data << read_bit_index);
            default: next_key_code = key_code;
        endcase
    end
    
    
    // new_key
    assign new_key = state == `TRANSMIT_KEY_STATE;



    // 3/14/26-3:50pm feature to prevent getting stuck in SAVING_INPUT_STATE
    wire [15:0] cycles_since_read_bit_index_changed;
    wire reset_to_idle_flag = cycles_since_read_bit_index_changed > `CYCLE_TIMEOUT && state != `IDLE_STATE; //a boolean
    dffr #(16) cycles_since_read_bit_index_changed_dff(
        .clk(clk),
        .d(cycles_since_read_bit_index_changed + 16'b1),
        .q(cycles_since_read_bit_index_changed),
        .r(
            read_bit_index != next_read_bit_index //a change is happening
            ||
            state == `IDLE_STATE //when in IDLE reset the counter
        )
        //.en(state != `IDLE_STATE) //the counter should only go up when the state is not in IDLE this way it is able to not keep counting when in IDLE
    );
    
endmodule

