// Inspired by tcg_rom

// notes from song_rom
`define C3      6'd28
`define C3SHARP 6'd29
`define D3      6'd30
`define D3SHARP 6'd31
`define E3      6'd32
`define F3      6'd33
`define F3SHARP 6'd34
`define G3      6'd35
`define G3SHARP 6'd36
`define A4      6'd37
`define A4SHARP 6'd38
`define B4      6'd39
`define C4      6'd40
`define C4SHARP 6'd41
`define D4      6'd42
`define D4SHARP 6'd43
`define E4      6'd44
`define F4      6'd45
`define F4SHARP 6'd46
`define G4      6'd47
`define G4SHARP 6'd48
`define A5      6'd49
`define A5SHARP 6'd50
`define B5      6'd51

// Map keys to the song notes
`define A_KEY `C3
`define S_KEY `D3
`define D_KEY `E3
`define F_KEY `F3
`define G_KEY `G3
`define H_KEY `A4
`define J_KEY `B4
`define K_KEY `C4
`define L_KEY `D4
`define SEMICOLON_KEY `E4
`define QUOTE_KEY `F4

`define W_KEY `C3SHARP
`define E_KEY `D3SHARP

`define T_KEY `F3SHARP
`define Y_KEY `G3SHARP
`define U_KEY `A4SHARP

`define O_KEY `C4SHARP
`define P_KEY `D4SHARP

`define REST_NOTE 6'd0 //nothing played

// From scan set 2: https://webdocs.cs.ualberta.ca/~amaral/courses/329/labs/scancodes.html
`define PS2_A 8'h1C
`define PS2_S 8'h1B
`define PS2_D 8'h23
`define PS2_F 8'h2B
`define PS2_G 8'h34
`define PS2_H 8'h33
`define PS2_J 8'h3B
`define PS2_K 8'h42
`define PS2_L 8'h4B

`define PS2_W 8'h1D
`define PS2_E 8'h24

`define PS2_T 8'h2C
`define PS2_Y 8'h35
`define PS2_U 8'h3C

`define PS2_O 8'h44
`define PS2_P 8'h4D

`define PS2_SEMICOLON 8'h4C
`define PS2_QUOTE 8'h52

// 01000110110
// 10001101

module keyboard_signal_rom(
    input wire [7:0] ps2_key_code, //8 bit signal. FKA keyboard_signal
    output reg [5:0] keyboard_note //note to be played, doesn't include the duration
);
    // From reality: 11**00011011**0. We only care about the bits in between for our scan set.
   
    // Only use make codes to start playing a note
    always @(*) begin
        casex (ps2_key_code) //don't care what first bit (start bit) and last bit (stop bit) are. Only care about the middle 8 bits. Parity is not checked here.
            `PS2_A: keyboard_note = `A_KEY;
            `PS2_S: keyboard_note = `S_KEY;
            `PS2_D: keyboard_note = `D_KEY;
            `PS2_F: keyboard_note = `F_KEY;
            `PS2_G: keyboard_note = `G_KEY;
            `PS2_H: keyboard_note = `H_KEY; // H_NOTE (assign the key code as appropriate if you wish to define `H_NOTE`)
            `PS2_J: keyboard_note = `J_KEY; // J_NOTE
            `PS2_K: keyboard_note = `K_KEY; // K_NOTE
            `PS2_L: keyboard_note = `L_KEY; // L_NOTE
            `PS2_SEMICOLON: keyboard_note = `SEMICOLON_KEY;
            `PS2_QUOTE: keyboard_note = `QUOTE_KEY;

            `PS2_W: keyboard_note = `W_KEY;
            `PS2_E: keyboard_note = `E_KEY;

            `PS2_T: keyboard_note = `T_KEY;
            `PS2_Y: keyboard_note = `Y_KEY;
            `PS2_U: keyboard_note = `U_KEY;
            
            `PS2_O: keyboard_note = `O_KEY;
            `PS2_P: keyboard_note = `P_KEY;
            
            default: keyboard_note = `REST_NOTE; //space bar clears by setting to rest note
        endcase
    end

    // // Only use make codes to start playing a note
    // always @(*) begin
    //     casex (ps2_frame) //don't care what first bit (start bit) and last bit (stop bit) are. Only care about the middle 8 bits. Parity is not checked here.
    //         11'bx00000000xx: // Just in case
    //             keyboard_note = `REST_NOTE;
    //         11'bx00111000xx: //A
    //             keyboard_note = `A_NOTE;
    //         11'bxx00011011x: //S. From testbench: 01101100011. From reality: 11000110110
    //             keyboard_note = `S_NOTE;
    //         11'bx11000100xx: //D
    //             keyboard_note = `D_NOTE;
    //         11'bx11010100xx: //F
    //             keyboard_note = `F_NOTE;
    //         11'bx00101100xx: //G
    //             keyboard_note = `G_NOTE;
    //         11'bx11001100xx: //H
    //             keyboard_note = `H_NOTE; // H_NOTE (assign the key code as appropriate if you wish to define `H_NOTE`)
    //         11'bx11011100xx: //J
    //             keyboard_note = `J_NOTE; // J_NOTE
    //         11'bx01000010xx: //K
    //             keyboard_note = `K_NOTE; // K_NOTE
    //         11'bx11010010xx: //L
    //             keyboard_note = `L_NOTE; // L_NOTE
            
    //         default: keyboard_note = `REST_NOTE;
    //     endcase
    // end
endmodule

