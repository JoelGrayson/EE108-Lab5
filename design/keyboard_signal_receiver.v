module keyboard_signal_receiver(
    input wire clk,
    input wire reset,

    // Passed down from the .xdc file (PMOD)
    input wire ps2_clk,
    input wire ps2_data,

    output wire new_key, //one-pulse indicating new key pressed and new note should be played
    output wire [11:0] key_code //like the notes in song_rom. This is the 12-bit note that specifies 
);
    always @(posedge ps2_clk) begin
        
    end
endmodule



