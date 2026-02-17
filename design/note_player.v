module note_player(
    input clk,
    input reset,
    input play_enable,  // When high we play, when low we don't.
    input [5:0] note_to_load,  // The note to play
    input [5:0] duration_to_load,  // The duration of the note to play
    input load_new_note,  // Tells us when we have a new note to load
    output done_with_note,  // When we are done with the note this stays high.
    input beat,  // This is our 1/48th second beat
    input generate_next_sample,  // Tells us when the codec wants a new sample
    output [15:0] sample_out,  // Our sample output
    output new_sample_ready  // Tells the codec when we've got a sample
);

reg [5:0] next;
wire [5:0] count;
reg [5:0] decremented_value;
wire [19:0] step_size_raw;
wire [19:0] step_size_effective;
wire [15:0] sine_out_raw;

// use wire to store the frequency of the note when load_note is high
wire [5:0] active_note;

dffre #(6) store_note_flip_flop (
    .clk(clk),
    .r(reset),
    .d(note_to_load),
    .q(active_note),
    .en(load_new_note)
);

dffr #(6) duration_flip_flop (
    .clk(clk),
    .r(reset),
    .d(next),
    .q(count)
);

// load note mux
always @(*) begin
    case(load_new_note) 
        default: next = duration_to_load;
        1'b0: next = decremented_value;
    endcase
end

wire effective_beat = beat & play_enable & (count != 0);

always @(*) begin
    case(effective_beat)
        default: decremented_value = count - 1;
        1'b0: decremented_value = count;
    endcase
end

assign done_with_note = (6'b000000 == count);

// instantiate the rom
frequency_rom freq_rom_list (
    .clk(clk),
    .addr(active_note),
    .dout(step_size_raw)
);

// implement pause behavior (force step_size to 0 when not playing)
assign step_size_effective = play_enable ? step_size_raw: 20'd0;

// instantiate the sine reader
sine_reader sine_reader_instance (
    .clk(clk),
    .reset(reset),
    .step_size(step_size_effective),
    .generate_next(generate_next_sample),
    .sample_ready(new_sample_ready),
    .sample(sine_out_raw)
);

assign sample_out = sine_out_raw;

endmodule