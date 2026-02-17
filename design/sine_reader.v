`define MAX_ADDR 20'b11111111111111111111

module sine_reader(
    input clk,
    input reset,
    input [19:0] step_size,
    input generate_next,

    output sample_ready,
    output wire [15:0] sample
);
    reg [21:0] next_addr;
    reg [20:0] temp_addr;
    reg [19:0] full_ROM_addr;
    reg [1:0] next_quadrant;
    wire [21:0] cur_addr;
    wire [15:0] abs_sample;
    wire [1:0] sample_quadrant;
    wire sample_enroute;
    
    dffre #(.WIDTH(22)) sin_addr_reg(.clk(clk), .r(reset), .en(generate_next), .d(next_addr), .q(cur_addr));
    dffr #(.WIDTH(2)) quadrant_reg(.clk(clk), .r(reset), .d(cur_addr[21:20]), .q(sample_quadrant));
    dffr queued_reg(.clk(clk), .r(reset), .d(generate_next), .q(sample_enroute));
    dffr ready_reg(.clk(clk), .r(reset), .d(sample_enroute), .q(sample_ready));
    sine_rom sin_vals(.clk(clk), .addr(full_ROM_addr[19:10]), .dout(abs_sample));
    
    always @(*) begin
        temp_addr = cur_addr[19:0] + step_size;
        next_quadrant = cur_addr[21:20] + temp_addr[20];
        next_addr = {next_quadrant, temp_addr[19:0]}; 
 
        //$display("step_size: %b, generate_next: %d, cur_addr: %b, next_addr: %b, temp_addr: %b", step_size[19:10], generate_next, cur_addr[19:10], next_addr[19:10], temp_addr[19:10]);
        
        casex (cur_addr[21:20])
            2'bX0: full_ROM_addr = cur_addr[19:0];
            2'bX1: full_ROM_addr = `MAX_ADDR - cur_addr[19:0];
            default: full_ROM_addr = 20'b0;
        endcase
        
        //$display("full_ROM_addr: %b", full_ROM_addr[19:10]);
    end
    
    assign sample = (sample_quadrant > 2'b01) ? (0 - abs_sample) : abs_sample; 

endmodule
