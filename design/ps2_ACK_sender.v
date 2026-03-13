// localparam is better code syntax than `define because it is typed and local to the file not global


// Sends the PS/2 "Enable Scanning" command (0xF4) to the keyboard after reset.
// Runs once, then asserts send_done permanently so the receiver can take over.
//
// PS/2 host-to-device protocol:
//   1. Pull CLK low for >= 100us to inhibit keyboard
//   2. Pull DATA low (start bit), then release CLK
//   3. Keyboard generates clock; on each falling edge, host places next bit on DATA
//   4. Frame: start(0) + 8 data bits (LSB first) + parity + stop(1)
//   5. Keyboard ACKs by pulling DATA low for one clock cycle
//
// 0xF4 = 11110100, LSB-first = 00101111, odd parity = 0

module ps2_ACK_sender(
    input wire clk,       // 100 MHz system clock
    input wire reset,

    input wire ps2_clk_in,
    input wire ps2_data_in,

    output reg ps2_clk_oe,
    output reg ps2_data_oe,
    output reg ps2_clk_out,
    output reg ps2_data_out,

    output wire send_done
);

    localparam [2:0] S_WAIT    = 3'd0,
                     S_INHIBIT = 3'd1,
                     S_START   = 3'd2,
                     S_SEND    = 3'd3,
                     S_WAIT_ACK = 3'd4,
                     S_DONE    = 3'd5;

    // 0xF4 frame: start(0), D0-D7 (LSB first: 00101111), parity(0), stop(1)
    localparam [10:0] TX_FRAME = 11'b1_0_11110100_0;
    //                              stop par D7..D0  start
    // Bit index 0 = start = 0
    // Bit index 1..8 = data LSB first = 0,0,1,0,1,1,1,1
    // Bit index 9 = parity = 0
    // Bit index 10 = stop = 1

    reg [2:0] state, next_state;
    reg [22:0] counter, next_counter;  // up to ~50ms at 100MHz
    reg [3:0] bit_index, next_bit_index;

    // Track falling edge of ps2_clk_in
    reg ps2_clk_prev;
    always @(posedge clk) begin
        if (reset)
            ps2_clk_prev <= 1'b1;
        else
            ps2_clk_prev <= ps2_clk_in;
    end
    wire ps2_clk_fall = ps2_clk_prev & ~ps2_clk_in;

    // State register
    always @(posedge clk) begin
        if (reset) begin
            state     <= S_WAIT;
            counter   <= 0;
            bit_index <= 0;
        end else begin
            state     <= next_state;
            counter   <= next_counter;
            bit_index <= next_bit_index;
        end
    end

    assign send_done = (state == S_DONE);

    // 50ms = 5,000,000 cycles at 100MHz
    localparam [22:0] WAIT_COUNT    = 23'd5_000_000;
    // 120us = 12,000 cycles at 100MHz
    localparam [22:0] INHIBIT_COUNT = 23'd12_000;
    // Timeout for ACK: ~2ms = 200,000 cycles (generous)
    localparam [22:0] ACK_TIMEOUT   = 23'd200_000;

    always @(*) begin
        next_state     = state;
        next_counter   = counter;
        next_bit_index = bit_index;

        ps2_clk_oe   = 1'b0;
        ps2_data_oe  = 1'b0;
        ps2_clk_out  = 1'b0;
        ps2_data_out = 1'b0;

        case (state)
            S_WAIT: begin
                // Wait ~50ms for keyboard BAT to complete
                next_counter = counter + 1;
                if (counter >= WAIT_COUNT) begin
                    next_state   = S_INHIBIT;
                    next_counter = 0;
                end
            end

            S_INHIBIT: begin
                // Pull CLK low for ~120us to inhibit keyboard communication
                ps2_clk_oe  = 1'b1;
                ps2_clk_out = 1'b0;
                next_counter = counter + 1;
                if (counter >= INHIBIT_COUNT) begin
                    next_state   = S_START;
                    next_counter = 0;
                end
            end

            S_START: begin
                // Pull DATA low (start bit) while CLK is still held low, then release CLK.
                // The keyboard will see DATA=0 and begin generating clock pulses.
                ps2_data_oe  = 1'b1;
                ps2_data_out = 1'b0;
                ps2_clk_oe   = 1'b0;
                next_state     = S_SEND;
                next_bit_index = 4'd0; // start at bit 0 (start bit) so it's held until first falling edge
            end

            S_SEND: begin
                // Drive DATA with the current frame bit on each falling edge of CLK
                ps2_data_oe  = 1'b1;
                ps2_data_out = TX_FRAME[bit_index];
                if (ps2_clk_fall) begin
                    if (bit_index >= 4'd10) begin
                        // All bits sent (including stop bit); wait for ACK
                        next_state   = S_WAIT_ACK;
                        next_counter = 0;
                    end else begin
                        next_bit_index = bit_index + 1;
                    end
                end
            end

            S_WAIT_ACK: begin
                // Release DATA, wait for keyboard to pull DATA low as ACK
                ps2_data_oe = 1'b0;
                next_counter = counter + 1;
                if (ps2_clk_fall && ~ps2_data_in) begin
                    // Keyboard ACK received
                    next_state = S_DONE;
                end else if (counter >= ACK_TIMEOUT) begin
                    // Timeout: proceed anyway so the system doesn't hang
                    next_state = S_DONE;
                end
            end

            S_DONE: begin
                // All lines released, receiver can take over
                ps2_clk_oe  = 1'b0;
                ps2_data_oe = 1'b0;
            end
        endcase
    end

endmodule

