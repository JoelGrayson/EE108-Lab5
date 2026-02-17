`define SONG_0_START 3'd0
`define SONG_0_END 3'd4
`define SONG_1_START 3'd1
`define SONG_1_END 3'd5
`define SONG_2_START 3'd2
`define SONG_2_END 3'd6
`define SONG_3_START 3'd3
`define SONG_3_END 3'd7
`define PLAY_OFF 1'd0
`define PLAY_ON 1'd1
`define RESET_PLAYER_OFF 1'd0
`define RESET_PLAYER_ON 1'd1

module mcu(
    input clk,
    input reset,
    input play_button,
    input next_button,
    output play,
    output reset_player,
    output [1:0] song,
    input song_done
);
    wire [2:0] song_state;
    wire play_state, reset_player_state, song_done_pulse;
    reg [2:0] next_song_state;
    reg next_play_state, next_reset_player_state;

    one_pulse done_pulse(.clk(clk), .reset(reset), .in(song_done), .out(song_done_pulse));
    
    dffr #(.WIDTH(3)) song_state_reg(.clk(clk), .r(reset), .d(next_song_state), .q(song_state));
    dffr play_state_reg(.clk(clk), .r(reset | next_button | song_done_pulse), .d(next_play_state), .q(play_state));
    dffr reset_player_state_reg(.clk(clk), .r(reset), .d(next_reset_player_state), .q(reset_player_state)); 
    
    always @(*) begin
        casex(song_state)
            `SONG_0_START: next_song_state = next_button ? `SONG_1_START : (play_button ? `SONG_0_END : `SONG_0_START);
            `SONG_0_END: next_song_state = (next_button | song_done_pulse) ? `SONG_1_START : `SONG_0_END;
            `SONG_1_START: next_song_state = next_button ? `SONG_2_START : (play_button ? `SONG_1_END : `SONG_1_START);
            `SONG_1_END: next_song_state = (next_button | song_done_pulse) ? `SONG_2_START : `SONG_1_END;
            `SONG_2_START: next_song_state = next_button ? `SONG_3_START : (play_button ? `SONG_2_END : `SONG_2_START);
            `SONG_2_END: next_song_state = (next_button | song_done_pulse) ? `SONG_3_START : `SONG_2_END;
            `SONG_3_START: next_song_state = next_button ? `SONG_0_START : (play_button ? `SONG_3_END : `SONG_3_START);
            `SONG_3_END: next_song_state = (next_button | song_done_pulse) ? `SONG_0_START : `SONG_3_END;
            default: next_song_state = `SONG_0_START;
        endcase
    end

    always @(*) begin
        casex(play_state) 
            `PLAY_OFF: next_play_state = play_button ? `PLAY_ON : `PLAY_OFF;
            `PLAY_ON: next_play_state = play_button ? `PLAY_OFF : `PLAY_ON;
            default: next_play_state = `PLAY_OFF;
        endcase
    end

    always @(*) begin
        casex(reset_player_state)
            `RESET_PLAYER_OFF: next_reset_player_state = (next_button | song_done_pulse) ? `RESET_PLAYER_ON : `RESET_PLAYER_OFF;
            `RESET_PLAYER_ON: next_reset_player_state = (next_button | song_done_pulse) ? `RESET_PLAYER_ON : `RESET_PLAYER_OFF; 
            default: next_reset_player_state = `RESET_PLAYER_OFF;
        endcase
    end

    assign song = song_state[1:0];
    assign play = play_state;
    assign reset_player = reset_player_state;
endmodule