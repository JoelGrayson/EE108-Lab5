// Rewrote it in SystemVerilog to practice SystemVerilog

module keyboard_reader(
    input logic clk,
    input logic reset,
    input logic enabled,
    input logic note_done_pulse, //pulse from music_player indicating that we are done

    input logic ps2_clk,
    input logic ps2_data,
    input logic ps2_reset,

    output logic new_note_pulse,
    output logic keyboard_play,
    output logic [5:0] duration,
    output logic [5:0] note
);
    localparam logic [5:0] KEYBOARD_NOTE_DURATION = 6'd16;
    typedef enum logic [1:0] {
        IDLE = 2'b10, //I already assigned them on my iPad
        PLAYING = 2'b01
    } keyboard_state;


    // Get signal from keyboard
    logic [10:0] ps2_frame;
    logic [7:0] ps2_key_code;
    assign ps2_key_code = ps2_frame[8:1];
    logic new_key;

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
    logic p_new_key; //Value of new_key on clk cycle ago
    always_ff @(posedge clk) begin
        if (reset)
            p_new_key <= '0;
        else
            p_new_key <= new_key;
    end

    assign new_note_pulse = p_new_key && enabled;
    assign duration = KEYBOARD_NOTE_DURATION;


    // State to set keyboard_play. Keyboard_play should be set to 1 when new_note_pulse starts and go back to 0 when note_done_pulse occurs
    keyboard_state state;
    keyboard_state next_state;
    always_ff @(posedge clk) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    always_comb begin
        case ({ state, new_note_pulse, note_done_pulse }) inside
            { IDLE, 1'b1, 1'b? }: next_state = PLAYING; //go from idle to playing when new_note
            { PLAYING, 1'b0, 1'b1 }: next_state = IDLE; //note_done causes back to idle
            { PLAYING, 1'b?, 1'b? }: next_state = PLAYING; //ensure it stays in the same state if not note_done_pulse
            default: next_state = IDLE; //by default, be in idle
        endcase
    end

    assign keyboard_play = state == PLAYING
        || next_state == PLAYING; //added this line for timing issue where keyboard_play is no true when new_note_pulse occurs.


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

    // ila_1 ps2_frame_ila(
    //     .clk(clk), // input wire clk
    //     .probe0(note), // input wire [5:0]  probe0  
    //     .probe1(new_key), // input wire [0:0]  probe1 
    //     .probe2(ps2_frame), // input wire [10:0]  probe2 
    //     .probe3(ps2_key_code), // input wire [7:0]  probe3 
    //     .probe4(keyboard_play), // input wire [0:0]  probe4 
    //     .probe5(state), // input wire [1:0]  probe5 
    //     .probe6(next_state), // input wire [1:0]  probe6 
    //     .probe7(note), // input wire [5:0]  probe7 
    //     .probe8(duration), // input wire [5:0]  probe8 
    //     .probe9(new_note_pulse), // input wire [0:0]  probe9 
    //     .probe10(enabled), // input wire [0:0]  probe10 
    //     .probe11(note_done_pulse) // input wire [0:0]  probe11
    // );
endmodule


