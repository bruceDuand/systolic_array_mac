module register_sync #(
    parameter integer WIDTH             = 8
) (
    input   wire                        clk,
    input   wire                        reset,
    input   wire    [WIDTH - 1 : 0]     in,
    output  wire    [WIDTH - 1 : 0]     out
);

    reg [ WIDTH - 1 : 0 ]   out_reg;

    always @(posedge clk) begin
        if (reset) begin
            out_reg <= 'b0;
        end else begin
            out_reg <= in;
        end
    end

    assign out = out_reg;

endmodule