`define KEYBOARD_NOTE_DURATION 6'd16

`define KEYBOARD_STATE_WIDTH 2
`define KEYBOARD_READER_IDLE_STATE 2'b10
`define KEYBOARD_READER_PLAYING_STATE 2'b01
`define DEFAULT_KEYBOARD_STATE `KEYBOARD_READER_IDLE_STATE

module keyboard_reader(
    input wire clk,
    input wire reset,
    input wire enabled,
    input wire note_done_pulse, //pulse from music_player indicating that we are done

    input wire ps2_clk,
    input wire ps2_data,
    input wire ps2_reset,

    output wire new_note_pulse,
    output wire keyboard_play,
    output wire [5:0] duration,
    output wire [5:0] note
);
    // Get signal from keyboard
    wire [10:0] ps2_frame;
    wire [7:0] ps2_key_code = ps2_frame[8:1];

    keyboard_signal_receiver ksr(
        .clk(clk),

        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .reset(ps2_reset),

        .new_key(new_key),
        .ps2_frame(ps2_frame)
    );


    // Decode signal into its note
    keyboard_signal_rom ks_rom( //case statement mapping the 11 bits keyboard_signal to the keyboard note that can be played (just the 6 bits of the note, not the duration)
        .ps2_key_code(ps2_key_code), //8 bits input
        .keyboard_note(note)  //6 bits output
    );


    // Need to use p_new_key instead of new_key because need one cycle for the duration/note to settle down for note_player to ingest it (setup time constraint)
    wire p_new_key; //Value of new_key on clk cycle ago
    dffr #(1) delay_new_key_dff(
        .d(new_key),
        .q(p_new_key),
        .clk(clk),
        .r(reset)
    );
    assign new_note_pulse = p_new_key && enabled;
    assign duration = `KEYBOARD_NOTE_DURATION;


    // State to set keyboard_play. Keyboard_play should be set to 1 when new_note_pulse starts and go back to 0 when note_done_pulse occurs
    wire [`KEYBOARD_STATE_WIDTH-1:0] state;
    reg [`KEYBOARD_STATE_WIDTH-1:0] next_state;
    dff #(`KEYBOARD_STATE_WIDTH) keyboard_state(
        .d(reset ? `DEFAULT_KEYBOARD_STATE : next_state),
        .q(state),
        .clk(clk)
    );
    always @(*) begin
        casex ({ state, new_note_pulse, note_done_pulse })
            { `KEYBOARD_READER_IDLE_STATE, 1'b1, 1'bx }: next_state = `KEYBOARD_READER_PLAYING_STATE; //go from idle to playing when new_note
            { `KEYBOARD_READER_PLAYING_STATE, 1'b0, 1'b1 }: next_state = `KEYBOARD_READER_IDLE_STATE; //note_done causes back to idle
            { `KEYBOARD_READER_PLAYING_STATE, 1'bx, 1'bx }: next_state = `KEYBOARD_READER_PLAYING_STATE; //ensure it stays in the same state if not note_done_pulse
            default: next_state = `DEFAULT_KEYBOARD_STATE; //by default, be in idle
        endcase
    end

    assign keyboard_play = state == `KEYBOARD_READER_PLAYING_STATE
        || next_state == `KEYBOARD_READER_PLAYING_STATE; //added this line for timing issue where keyboard_play is no true when new_note_pulse occurs.


    // ila_1 is useful for seeing what key is being sent out due to the PS2 signals
    // keyboard_note (probe 1) is the note we have played from the keyboard_signal_rom
    // probe 2 is helpful for trigger
    // probe 3 is helpful to see what the keyboard said literally from the scope
//    ila_1 ps2_frame_ila(
//	    .clk(clk), // input wire clk
//        .probe0(keyboard_note), // input wire [5:0] probe0
//        .probe1(new_key), // input wire [0:0]  probe1
//    	.probe2(ps2_frame), //input wire [10:0]  probe2
//        .probe3(ps2_key_code) // input wire [7:0]  probe3
//    );
    // #0 - keyboard_note, new_key, ps2_frame, #3 - ps2_key_code //this row is OG
    // #4 - keyboard_play, state, #6 - next_state, #7 - note, duration, #9 - new_note_pulse
    // #10 - enabled, note_done_pulse
    ila_1 ps2_frame_ila(
        .clk(clk), // input wire clk
        .probe0(note), // input wire [5:0]  probe0  
        .probe1(new_key), // input wire [0:0]  probe1 
        .probe2(ps2_frame), // input wire [10:0]  probe2 
        .probe3(ps2_key_code), // input wire [7:0]  probe3 
        .probe4(keyboard_play), // input wire [0:0]  probe4 
        .probe5(state), // input wire [1:0]  probe5 
        .probe6(next_state), // input wire [1:0]  probe6 
        .probe7(note), // input wire [5:0]  probe7 
        .probe8(duration), // input wire [5:0]  probe8 
        .probe9(new_note_pulse), // input wire [0:0]  probe9 
        .probe10(enabled), // input wire [0:0]  probe10 
        .probe11(note_done_pulse) // input wire [0:0]  probe11
    );
endmodule


