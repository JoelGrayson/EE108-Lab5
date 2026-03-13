// Inspired by tcg_rom

`define A_NOTE 5'd37
`define S_NOTE 5'd39
`define D_NOTE 5'd40
`define F_NOTE 5'd44
`define G_NOTE 5'd47
`define H_NOTE 5'd48
`define J_NOTE 5'd49
`define K_NOTE 5'd50
`define L_NOTE 5'd51
`define REST_NOTE 5'd0 //nothing played

module keyboard_signal_rom(
    input wire [10:0] keyboard_signal,
    output reg [5:0] keyboard_note
);
    // Only use make codes to start playing a note
    always @(*) begin
        casex (keyboard_signal) //don't care what first bit (start bit) and last bit (stop bit) are. Only care about the middle 8 bits. Parity is not checked here.
            11'bx00000000xx: //TODO: measure the Perixx keyboard to find out what the values are here
                keyboard_note = `REST_NOTE;
            11'bx00000000xx: //A
                keyboard_note = `A_NOTE;
            11'bx00000000xx: //S
                keyboard_note = `S_NOTE;
            11'bx00000000xx: //D
                keyboard_note = `D_NOTE;
            11'bx00000000xx: //F
                keyboard_note = `F_NOTE;
            11'bx00000000xx: //G
                keyboard_note = `G_NOTE;
            11'bx00000000xx: //H
                keyboard_note = `H_NOTE; // H_NOTE (assign the key code as appropriate if you wish to define `H_NOTE`)
            11'bx00000000xx: //J
                keyboard_note = `J_NOTE; // J_NOTE
            11'bx00000000xx: //K
                keyboard_note = `K_NOTE; // K_NOTE
            11'bx00000000xx: //L
                keyboard_note = `L_NOTE; // L_NOTE
            
            default: keyboard_note = `REST_NOTE;
        endcase
    end
endmodule

