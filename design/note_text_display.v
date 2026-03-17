module note_text_display(
    input clk,
    input reset,
    input wire [8:0] x_scaled, //0 to 400
        // this is 8 cells of 32 width each
    input wire [7:0] y_scaled, //0 to 255
    input wire in_region, //bool indicating that in the region. When false, the y_scaled value can't be trusted
    input wire [5:0] curr_note, //0 to 63. Spans multiple octaves.

    output wire is_pixel_on
);
    // BEGIN (1) curr_note_letter, p_note_letter, pp_note_letter
    wire [3:0] curr_note_letter = curr_note == 0 ? 0 : (curr_note % 12); //so that 0 is nothing. A is 1.
    wire [3:0] temp_p_note_letter, p_note_letter, pp_note_letter /*anteprevious*/;
    dffr #(4) temp_p_note_letter_dff(
        .d(curr_note_letter),
        .q(temp_p_note_letter),
        .clk(clk),
        .r(reset)
    );

    wire note_just_changed = curr_note_letter != temp_p_note_letter; //indicates that you should shift from curr_note_letter to p_note_letter and p_note_letter to pp_note_letter
    dffre #(4) p_note_letter_dff(
        .d(temp_p_note_letter),
        .q(p_note_letter),
        .clk(clk),
        .r(reset),
        .en(note_just_changed)
    );

    dffre #(4) pp_note_letter_dff(
        .d(p_note_letter),
        .q(pp_note_letter),
        .en(note_just_changed),
        .r(reset),
        .clk(clk)
    );


    // BEGIN (2) Show note_letter with letter_box
    wire cell1_is_pixel_on, cell2_is_pixel_on, cell4_is_pixel_on, cell5_is_pixel_on, cell7_is_pixel_on, cell8_is_pixel_on;
    wire is_y_in_region = y_scaled >= 0 && y_scaled <= 32;
    // Current note
    letter_box cell1(
        .in_region(x_scaled >= 32 * 1 && x_scaled < 32 * 2 && is_y_in_region),
        .rel_x((x_scaled - 32 * 1) / 4),
        .rel_y(y_scaled / 4),
        // .letter(2), //A#
        .letter(curr_note_letter),
        .is_second_char(0),
        .is_pixel_on(cell1_is_pixel_on)
    );
    letter_box cell2(
        .in_region(x_scaled >= 32 * 2 && x_scaled < 32 * 3 && is_y_in_region),
        .rel_x((x_scaled - 32 * 2) / 4),
        .rel_y(y_scaled / 4),
        // .letter(2),
        .letter(curr_note_letter),
        .is_second_char(1),
        .is_pixel_on(cell2_is_pixel_on)
    );
    wire within_curr_note_x = x_scaled >= 32 * 1 && x_scaled <= 32 * 3;
    // Previous note
    letter_box cell4(
        .in_region(x_scaled >= 32 * 4 && x_scaled < 32 * 5 && is_y_in_region),
        .rel_x((x_scaled - 32 * 4) / 4),
        .rel_y(y_scaled / 4),
        // .letter(5),
        .letter(p_note_letter),
        .is_second_char(0),
        .is_pixel_on(cell4_is_pixel_on)
    );
    letter_box cell5(
        .in_region(x_scaled >= 32 * 5 && x_scaled < 32 * 6 && is_y_in_region),
        .rel_x((x_scaled - 32 * 5) / 4),
        .rel_y(y_scaled / 4),
        // .letter(5),
        .letter(p_note_letter),
        .is_second_char(1),
        .is_pixel_on(cell5_is_pixel_on)
    );
    wire within_p_note_x = x_scaled >= 32 * 4 && x_scaled < 32 * 6;
    // Anteprevious note
    letter_box cell7(
        .in_region(x_scaled >= 32 * 7 && x_scaled < 32 * 8 && is_y_in_region),
        .rel_x((x_scaled - 32 * 7) / 4),
        .rel_y(y_scaled / 4),
        // .letter(7),
        .letter(pp_note_letter),
        .is_second_char(0),
        .is_pixel_on(cell7_is_pixel_on)
    );
    letter_box cell8(
        .in_region(x_scaled >= 32 * 8 && x_scaled < 32 * 9 && is_y_in_region),
        .rel_x((x_scaled - 32 * 8) / 4),
        .rel_y(y_scaled / 4),
        // .letter(7),
        .letter(pp_note_letter),
        .is_second_char(1),
        .is_pixel_on(cell8_is_pixel_on)
    );
    wire within_pp_note_x = x_scaled >= 32 * 7 && x_scaled < 32 * 9;

    assign is_pixel_on = in_region
        & (
            // In letter
            (cell1_is_pixel_on | cell2_is_pixel_on | cell4_is_pixel_on | cell5_is_pixel_on | cell7_is_pixel_on | cell8_is_pixel_on)
            | 
            // In boundary
            (
                // x
                // (within_curr_note_x | within_p_note_x | within_pp_note_x)
                (within_curr_note_x | within_p_note_x) //asymmetry shows you what the pp_ is
                &
                // y
                (y_scaled >= 35 & y_scaled <= 36)
            )
        );


    // ILA for note_text_display inspects:
    // curr_note_letter, p_note_letter, pp_note_letter
    ila_note_text_display note_text_display_ila (
        .clk(clk), // input wire clk
        .probe0(curr_note_letter), // input wire [3:0]  probe0  
        .probe1(temp_p_note_letter), // input wire [3:0]  probe1 
        .probe2(p_note_letter), // input wire [3:0]  probe2 
        .probe3(pp_note_letter), // input wire [3:0]  probe3 
        .probe4(note_just_changed), // input wire [0:0]  probe4
            // used for trigger
        .probe5(curr_note)
    );
endmodule

