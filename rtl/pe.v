`include "register_sync"
`include "signed_adder"

module pe #(
    parameter           PE_MODE             = "FMA",
    parameter integer   ACT_WIDTH           = 16,
    parameter integer   WGT_WIDTH           = 16,
    parameter integer   MULT_OUT_WIDTH      = ACT_WIDTH + WGT_WIDTH,
    parameter integer   PE_OUT_WIDTH        = MULT_OUT_WIDTH  
)(
    input   wire                                    clk,
    input   wire                                    reset,
    input   wire    [ ACT_WIDTH         - 1 : 0 ]       a,
    input   wire    [ WGT_WIDTH         - 1 : 0 ]       b,
    input   wire    [ PE_OUT_WIDTH      - 1 : 0 ]       c,
    output  wire    [ PE_OUT_WIDTH      - 1 : 0 ]       out
);

    wire    signed  [ MULT_OUT_WIDTH    - 1 : 0]        mult_out;
    wire    signed  [ ACT_WIDTH         - 1 : 0]        _a;
    wire    signed  [ WGT_WIDTH         - 1 : 0]        _b;

    assign _a = a;
    assign _b = b;

    assign mult_out = _a * _b;

    if ( PF_MODE == "FMA") begin
        signed_adder #(
            .REGISTER_OUTPUT            ( "TRUE"            ),
            .IN1_WIDTH                  ( MULT_OUT_WIDTH    ),
            .IN2_WIDTH                  ( PE_OUT_WIDTH      ),
            .OUT_WIDTH                  ( PE_OUT_WIDTH      )
        ) adder_inst (
            .clk                        ( clk               ),
            .reset                      ( reset             ),
            .a                          ( mult_out          ),
            .b                          ( c                 ),
            .out                        ( out               )
        );
    end else begin
        wire    [ PE_OUT_WIDTH      - 1 : 0 ]       _mult_out;
        assign  _mult_out = mult_out;

        register_sync #(
            .WIDTH                      ( PE_OUT_WIDTH      )
        ) reg_inst (
            .clk                        ( clk               ),
            .reset                      ( reset             ),
            .in                         ( _mult_out         ),
            .out                        ( out               )
        )
    end 
    
endmodule