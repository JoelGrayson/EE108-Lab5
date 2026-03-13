`define STATE_WIDTH 3
`define IDLE_STATE 3'b100
`define SAVING_INPUT_STATE 3'b010 //uses read_bit_index
`define TRANSMIT_KEY_STATE 3'b001
`define DEFAULT_STATE `IDLE_STATE

module keyboard_signal_receiver(
    input wire clk,
    input wire reset,

    // Passed down from the .xdc file (PMOD)
    input wire ps2_clk,
    input wire ps2_data,

    output wire new_key, //one-pulse indicating new key pressed and new note should be played
    output wire [11:0] key_code //like the notes in song_rom. This is the 12-bit note that specifies 
);
    // State (control)
    wire [2:0] state; //current state. 100 is IDLE, 010 is SAVING_INPUT, and 001 is TRANSMIT_KEY
    reg [2:0] next_state;

    dff #(STATE_WIDTH) state_dff(
        .clk(clk),
        .d(reset ? `DEFAULT_STATE : next_state),
        .q(state)
    );



    // Number of read bits. 0 to 11
    wire [3:0] read_bit_index; //enough memory for 0 to 16
    reg [3:0] next_read_bit_index;
    dffr #(4) read_bit_index_dff(
        .clk(clk),
        .r(reset),
        .d(next_read_bit_index),
        .q(read_bit_index)
    );


    // 11 bit key sequence
    // The data from the PS/2. Comes in 11 bit packet.
    wire [10:0] key_code; //11 bits from the PS/2 data cable on each clock rise. It is the PS/2 seq. The 1:8 are the actual key information that differs.
    reg [10:0] next_key_code;
    dffr #(11) ps2_seq_dff(
        .d(next_key_code),
        .q(key_code),
        .clk(clk),
        .r(reset)
    );



    // Save the previous clock signal so you can see if the clock signal is rising
    wire p_ps2_clk;
    dffr #(1) p_ps2_clk_dff(
        .d(ps2_clk),
        .q(p_ps2_clk),
        .clk(clk),
        .r(reset)
    );
    
    // Compute next state
    always @(*) begin
        case ({state, ps2_clk, p_ps2_clk, })
            {`IDLE_STATE, 1'b1, 1'b0}: next_state = `SAVING_INPUT_STATE;
                // in IDLE state but the clk just went down so now it's time for capture
            {`SAVING_INPUT_STATE, 1'bx, 1'bx}

            {`}
        endcase
    end
endmodule



