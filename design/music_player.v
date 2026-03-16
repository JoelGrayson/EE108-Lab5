//
//  music_player module
//
//  This music_player module connects up the MCU, song_reader, note_player,
//  beat_generator, and codec_conditioner. It provides an output that indicates
//  a new sample (new_sample_generated) which will be used in lab 5.
//

module music_player(
    // Standard system clock and reset
    input clk,
    input reset,

    // Our debounced and one-pulsed button inputs.
    input play_button,
    input next_button,

    // The raw new_frame signal from the ac97_if codec.
    input new_frame,

    // This output must go high for one cycle when a new sample is generated.
    output wire new_sample_generated,

    // Our final output sample to the codec. This needs to be synced to
    // new_frame.
    output wire [15:0] sample_out,

    output wire [5:0] curr_note,

    input wire ps2_clk,
    input wire ps2_data,
    input wire ps2_reset
);
    // The BEAT_COUNT is parameterized so you can reduce this in simulation.
    // If you reduce this to 100 your simulation will be 10x faster.
    parameter BEAT_COUNT = 1000;

//
//  ****************************************************************************
//      Master Control Unit
//  ****************************************************************************
//   The reset_player output from the MCU is run only to the song_reader because
//   we don't need to reset any state in the note_player. If we do it may make
//   a pop when it resets the output sample.
//
 
    wire song_reader_play;
    wire reset_player;
    wire [1:0] current_song;
    wire song_done;
    mcu mcu( //mcu controls the song_reader but the keyboard_reader is a separate module
        .clk(clk),
        .reset(reset),
        .play_button(play_button),
        .next_button(next_button),
        .play(song_reader_play),
        .reset_player(reset_player),
        .song(current_song),
        .song_done(song_done)
    );
    /*
    always @(posedge clk) begin  
        $display("mcu play: %d", play);
        $display("mcu reset_player: %d", reset_player);
        $display("mcu song: %d", current_song);
        $display("mcu song_done: %d", song_done);      
    end
    */
//
//  ****************************************************************************
//      Song Reader
//  ****************************************************************************
//
    wire [5:0] song_reader_note; //FKA song_reader_note
    wire [5:0] song_reader_duration; //FKA song_reader_duration
    wire song_reader_new_note;
    wire note_done;
    song_reader song_reader(
        .clk(clk),
        .reset(reset | reset_player),
        .play(song_reader_play),
        .song(current_song),
        .song_done(song_done),
        .note(song_reader_note),
        .duration(song_reader_duration),
        .new_note(song_reader_new_note),
        .note_done(note_done)
    );
    /*
    always @(posedge clk) begin  
        $display("song_reader song_done: %d", play);
        $display("song_reader note: %d", song_reader_note);
        $display("song_reader duration: %d", song_reader_duration);
        $display("song_reader new_note: %d", new_note);      
    end
    */

// //   
// //  ****************************************************************************
// //      Keyboard Signal Receiver
// //  ****************************************************************************
// //  
    wire keyboard_new_note;
    wire keyboard_play;
    wire [5:0] keyboard_duration;
    wire [5:0] keyboard_note;

    // // For testing BEGIN
    // assign keyboard_play = 1'b0;
    // assign keyboard_new_note = 1'b0;
    // // END
    
    keyboard_reader keyboard_reader_device(
        // Inputs
        .clk(clk),
        .reset(reset | reset_player),
        .enabled(!song_reader_play), //while a song is playing, don't be in keyboard mode
        .note_done_pulse(note_done),

        // PS2
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .ps2_reset(ps2_reset),

        // Outputs
        .new_note_pulse(keyboard_new_note), //a one-pulse indicating new note should be played
        .keyboard_play(keyboard_play), //should be true when it should be playing (for the whole duration of the note)
        .duration(keyboard_duration),
        .note(keyboard_note) //which note it is
    );
    
    // Merge info from song_reader and keyboard_reader
    wire new_note = keyboard_new_note | song_reader_new_note;
    wire play = keyboard_play | song_reader_play;
    wire [5:0] note = keyboard_play ? keyboard_note : song_reader_note;
    wire [5:0] duration = keyboard_play ? keyboard_duration : song_reader_duration;
    assign curr_note = note; //outputted to VGA display
    

//   
//  ****************************************************************************
//      Note Player
//  ****************************************************************************
//  
    wire beat;
    wire generate_next_sample, generate_next_sample0;
    wire [15:0] note_sample, note_sample0;
    wire note_sample_ready, note_sample_ready0;

    // These pipeline registers were added to decrease the length of the critical path!
    dffr pipeline_ff_gen_next_sample (.clk(clk), .r(reset), .d(generate_next_sample0), .q(generate_next_sample));
    dffr #(.WIDTH(16)) pipeline_ff_note_sample (.clk(clk), .r(reset), .d(note_sample0), .q(note_sample));
    dffr pipeline_ff_new_sample_ready (.clk(clk), .r(reset), .d(note_sample_ready0), .q(note_sample_ready));

    note_player note_player(
        .clk(clk),
        .reset(reset),
        .play_enable(/*play*/1'b1), //play is from MCU/song_reader to indicate that the audio should be playing. If it is never set to false, then it will play indefinitely (never stop)
            // keyboard_play is used to indicate that the note should be playing because the keyboard just hit it
        .note_to_load(note),
        .duration_to_load(duration),
        .load_new_note(new_note),
        // .play_enable(play), //play is from MCU/song_reader to indicate that the audio should be playing. If it is never set to false, then it will play indefinitely (never stop)
            // keyboard_play is used to indicate that the note should be playing because the keyboard just hit it
        //.note_to_load(song_reader_note),
        //.duration_to_load(song_reader_duration),
        //.load_new_note(new_note),

        .done_with_note(note_done),
        .beat(beat),
        .generate_next_sample(generate_next_sample),
        .sample_out(note_sample0),
        .new_sample_ready(note_sample_ready0)
    );
    /*
    always @(posedge clk) begin  
        $display("note_player sample_out: %d", note_sample0);
        $display("note_player new_sample_ready: %d", note_sample_ready0);
    end
    */
//   
//  ****************************************************************************
//      Beat Generator
//  ****************************************************************************
//  By default this will divide the generate_next_sample signal (48kHz from the
//  codec's new_frame input) down by 1000, to 48Hz. If you change the BEAT_COUNT
//  parameter when instantiating this you can change it for simulation.
//  
    beat_generator #(.WIDTH(10), .STOP(BEAT_COUNT)) beat_generator(
        .clk(clk),
        .reset(reset),
        .en(generate_next_sample),
        .beat(beat)
    );

//  
//  ****************************************************************************
//      Codec Conditioner
//  ****************************************************************************
//  
    wire new_sample_generated0;
    wire [15:0] sample_out0; 

    dffr pipeline_ff_nsg (.clk(clk), .r(reset), .d(new_sample_generated0), .q(new_sample_generated));
    //dffr #(.WIDTH(16)) pipeline_ff_sample_out (.clk(clk), .r(reset), .d(sample_out0), .q(sample_out));
    assign sample_out = sample_out0;

    assign new_sample_generated0 = generate_next_sample;
    codec_conditioner codec_conditioner(
        .clk(clk),
        .reset(reset),
        .new_sample_in(note_sample),
        .latch_new_sample_in(note_sample_ready),
        .generate_next_sample(generate_next_sample0),
        .new_frame(new_frame),
        .valid_sample(sample_out0)
    );

    // ila_2 measures what note is currently being played, regardless of whether it is from the song_reader or the keyboard_reader. It should have a trigger of new_note (1 bit) and show what note (6 bit) and duration (6 bit) and new_key are for those
    ila_2 music_player_ila (
        .clk(clk), // input wire clk
        .probe0(keyboard_play), // input wire [0:0]  probe0  
        .probe1(new_note), // input wire [0:0]  probe1 
        .probe2(play), // input wire [0:0]  probe2 
        .probe3(note), // input wire [5:0]  probe3 
        .probe4(duration) // input wire [5:0]  probe4
    );
    // keyboard_play, new_note, play, note, duration
endmodule

