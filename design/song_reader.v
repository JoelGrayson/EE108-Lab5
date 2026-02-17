`include "my_macros.vh"

`define REST_NOTE 6'b0
`define REST_DURATION 6'b0

module song_reader(
    input clk,
    input reset,
    input play, //boolean indicating if song_reader should be playing
    input [1:0] song, //specified by MCU
    input note_done, //specified by note_player. Indicates if new note should be outputted by the song_reader
    
    
    // Outputs
    output song_done, //tell MCU that we're done with the song (one pulse)
    
    // 12-bits for the note. This data is used by note_player.
    output [5:0] note, //note and duration from song_rom
    output [5:0] duration,
    
    output new_note //one-cycle pulse for note_player to remember note & duration and start playing
);
    // DFF storing current_state
    wire [`STATE_WIDTH-1:0] current_state;
    reg [`STATE_WIDTH-1:0] next_state;
    dff #(`STATE_WIDTH) state_dff(
        .clk(clk),
        .d(next_state),
        .q(current_state) //reset controlled by next_state computation
    );
    
    // DFF stores current_note_index
    wire [5:0] current_note_index;
        /* First bit indicates if you are done because 10000 (32) indicates that you just finished playing all 32 notes (0 through 31) and should now go back to idle
        Next four bits are current note index number from 0 to 31 */
    wire [4:0] current_note_index_for_addr = current_note_index[4:0]; //just the last five bits is necessary
    
    reg [5:0] next_note_index; //current_note_index changes to next_note_index in increment state
    wire finished_song = next_note_index[5]; //if overflow occurred. When next_note_index is 10000, you finished playing all first 0-31 notes and should go idle again

    
    dffr #(7) note_dff(
        .clk(clk),
        .d(next_note_index),
        .q(current_note_index),
        .r(reset)
    );
    
    // next_note_index should be 0 when in idle state. Should be current note + 1 when in increment state. Otherwise, previous value
    always @(*) begin
        case (current_state)
            `IDLE_STATE: next_note_index = 0; //start new songs from the beginning
            `INCREMENT_STATE: next_note_index = current_note_index + 1;
            default: next_note_index = current_note_index; //maintain previous value
        endcase
    end
    
    
    // song_rom fetches note_data from note_addr
    wire [6:0] note_addr = { song, current_note_index_for_addr };
    wire [11:0] note_data;
    song_rom sr( //picks 1 of the 128 notes
        .clk(clk),
        .addr(note_addr),
        .dout(note_data)
    );
    
    wire [5:0] note_data_note, note_data_duration;
    assign { note_data_note, note_data_duration } = note_data;
    
    
    // Compute next_state
    always @(*) begin
        // reset, play, and note_done are all external inputs whereas current_state and finished_song are internal state
        casex ({reset, current_state, play, note_done, finished_song}) //case is better than if here because no sequentialness. All cases run in parallel.
            {1'b1, {`STATE_WIDTH{1'bx}}, 1'bx, 1'bx, 1'bx}: next_state = `IDLE_STATE; //any state resets to idle
            
            {1'b0, `IDLE_STATE, 1'b1, 1'bx, 1'bx}: next_state = `LOAD_NOTE_STATE; //playing, so go to load_note
            {1'b0, `IDLE_STATE, 1'b0, 1'bx, 1'bx}: next_state = `IDLE_STATE; //not playing, so stay idle
            {1'b0, `LOAD_NOTE_STATE, 1'b1, 1'bx, 1'bx}: next_state = `PLAY_NOTE_STATE;
            {1'b0, `PLAY_NOTE_STATE, 1'bx, 1'bx, 1'bx}: next_state = `WAIT_FOR_NOTE_DONE_STATE;
            {1'b0, `WAIT_FOR_NOTE_DONE_STATE, 1'bx, 1'b1, 1'bx}: next_state = `INCREMENT_STATE;
            {1'b0, `INCREMENT_STATE, 1'bx, 1'bx, 1'b1}: next_state = `IDLE_STATE; //finished the song
            {1'b0, `INCREMENT_STATE, 1'bx, 1'bx, 1'b0}: next_state = `LOAD_NOTE_STATE; //go to next note
            
            default: next_state = current_state; //stay on current state
        endcase
    end
    
    
    
    // Compute outputs
    assign song_done = current_state == `IDLE_STATE;
    assign new_note = current_state == `PLAY_NOTE_STATE; //only lasts one cycle
    assign note = current_state == `PLAY_NOTE_STATE ? note_data_note : `REST_NOTE; //TODO: see if this is necessary or if I can just do assign . = note_data_note
    assign duration = current_state == `PLAY_NOTE_STATE ? note_data_duration : `REST_DURATION; // "
endmodule

