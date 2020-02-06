module signed_adder #(
    parameter           REGISTER_OUTPUT     = "FALSE",
    parameter integer   IN1_WIDTH           = 20,
    parameter integer   IN2_WIDTH           = 32,
    parameter integer   OUT_WIDTH           = 32
) (
    input   wire                            clk,
    input   wire                            reset,
    input   wire    [ IN1_WIDTH - 1 : 0 ]   a,
    input   wire    [ IN2_WIDTH - 1 : 0 ]   b,
    output  wire    [ OUT_WIDTH - 1 : 0 ]   out
);

    wire    signed  [ IN1_WIDTH - 1 : 0 ]   _a;
    wire    signed  [ IN2_WIDTH - 1 : 0 ]   _b,
    wire    signed  [ OUT_WIDTH - 1 : 0 ]   add_out;

    assign _a = a;
    assign _b = b;
    assign add_out = _a + _b;
    if ( REGISTER_OUTPUT == "TRUE" ) begin
        reg [ OUT_WIDTH - 1 : 0 ]   _add_out;
        always @(posedge clk) begin
            if (reset) begin
                _add_out <= 'b0;
            end else begin
                _add_out <= add_out;
            end
        end
        assign out = _add_out;
    end   
    
endmodule