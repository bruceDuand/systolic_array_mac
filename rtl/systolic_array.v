`include "pe.v"
`include "register_sync"

module SystolicArray #(
    parameter integer   ARRAY_M                 = 4,
    parameter integer   ARRAY_N                 = 4,
    
    parameter integer   ACT_WIDTH               = 16,
    parameter integer   WGT_WIDTH               = 16,
    parameter integer   BIAS_WIDTH              = 32,
    parameter integer   ACC_WIDTH               = 48,

    parameter integer   MULT_OUT_WIDTH          = ACT_WIDTH + WGT_WIDTH,
    parameter integer   PE_OUT_WIDTH            = MULT_OUT_WIDTH,

    parameter integer   SYSTOLIC_OUT_WIDTH      = ARRAY_M * ACC_WIDTH,
    parameter integer   IBUFF_DATA_WIDTH        = ARRAY_N * ACT_WIDTH,
    parameter integer   WBUFF_DATA_WIDTH        = ARRAY_M * ARRAY_N * WGT_WIDTH,
    parameter integer   BBUFF_DATA_WIDTH        = ARRAY_M * BIAS_WIDTH,
    parameter integer   OUT_WIDTH               = ARRAY_M * ACC_WIDTH,

    parameter integer   OBUF_ADDR_WIDTH         = 16,
    parameter integer   BBUF_ADDR_WIDTH         = 16
)(
    input   wire                                    clk,
    input   wire                                    reset,

    input   wire                                    acc_clear,

    input   wire    [ IBUFF_DATA_WIDTH  - 1 : 0 ]   ibif_read_data,
    input   wire    [ WBUFF_DATA_WIDTH  - 1 : 0 ]   wbuff_read_data,
    
    input   wire    [ OUT_WIDTH         - 1 : 0 ]   obuf_read_data,
    input   wire    [ OBUF_ADDR_WIDTH   - 1 : 0 ]   obuf_read_addr,
    input   wire    [ OUT_WIDTH         - 1 : 0 ]   obuf_write_data,
    input   wire    [ OBUF_ADDR_WIDTH   - 1 : 0 ]   obuf_write_addr,
    input   wire                                    obuf_write_req,
    
    input   wire                                    bbias_read_req,
    input   wire    [ BBUFF_DATA_WIDTH  - 1 : 0 ]   bbias_read_data,
    input   wire    [ BBUF_ADDR_WIDTH   - 1 : 0 ]   bbias_read_addr,

);
    
    wire    [ SYSTOLIC_OUT_WIDTH    - 1 : 0 ]       systolic_out;

    // FSM determines accumulation status
    reg     [ 2                     - 1 : 0 ]       acc_state_next;
    reg     [ 2                     - 1 : 0 ]       acc_state;                                            
    wire                                            _addr_eq;
    reg                                             addr_eq;

    //=============================================================
    // Systolic array 
    //=============================================================
    genvar  n, m;
    generate;
        for (int m=0; m<ARRAY_M; m=m+1) 
        begin: LOOP_INPUT_FORWARD
            for (int n=0; n<ARRAY_N; n=n+1) 
            begin: LOOP_WEIGHT_FORWARD
                wire    [ ACC_WIDTH         - 1 : 0 ]       a;
                wire    [ WGT_WIDTH         - 1 : 0 ]       b;
                wire    [ PE_OUT_WIDTH      - 1 : 0 ]       c;
                wire    [ PE_OUT_WIDTH      - 1 : 0 ]       pe_out;


                if ( m == 0 ) begin
                    assign  a       =   ibif_read_data[n * ACT_WIDTH +: ACT_WIDTH];
                end else begin
                    wire    [ ACT_WIDTH     - 1 : 0 ]       fwd_a;
                    assign  fwd_a   =   LOOP_INPUT_FORWARD[m-1].LOOP_WEIGHT_FORWARD[n].a;
                    assign  a       =   fwd_a;
                end

                assign      b       =   wbuff_read_data((m + n*ARRAY_M) * WGT_WIDTH +: WGT_WIDTH);

                localparam  PE_MODE =   n == 0 ? "MULT" : "FMA";

                if ( n == 0 ) begin
                    assign  c       =   {PE_OUT_WIDTH{1'bz}};
                end else begin
                    assign  c       =   LOOP_INPUT_FORWARD[m].LOOP_WEIGHT_FORWARD[n-1].pe_out;
                end

                pe  #(
                    .PE_MODE                    .( PE_MODE          ),
                    .ACT_WIDTH                  .( ACT_WIDTH        ),
                    .WGT_WIDTH                  .( WGT_WIDTH        ),
                    .PE_OUT_WIDTH               .( PE_OUT_WIDTH     )
                ) pe_inst (
                    .clk                        .( clk              ),
                    .reset                      .( reset            ),
                    .a                          .( a                ),
                    .b                          .( b                ),
                    .c                          .( c                ),
                    .out                        .( pe_out           )
                );

                if ( n == ARRAY_N - 1 ) begin
                    assign systolic_out[m * PE_OUT_WIDTH +: PE_OUT_WIDTH] = pe_out;
                end
            end
        end
    endgenerate

    //=============================================================
    // Accumulator valid FSM
    //=============================================================
    genvar i;

    reg     [ OBUF_ADDR_WIDTH       - 1 : 0 ]   prev_obuf_write_addr;

    always @( posedge clk ) begin
        if (obuf_write_req)
            prev_obuf_write_addr <= obuf_write_addr;
    end

    localparam integer  ACC_INVALID             = 0;
    localparam integer  ACC_VALID               = 1;

    assign _addr_eq = (obuf_write_addr == prev_obuf_write_addr) && (obuf_write_req) && (acc_state != ACC_INVALID)
    always @( posedge clk ) begin
        if ( reset )
            addr_eq <= 1'b0;
        else
            addr_eq <= _addr_eq;
    end
    
    wire acc_clear_dly1;
    register_sync #(1) acc_clear_dlyreg (
        .clk                        .( clk              ),
        .reset                      .( reset            ),
        .in                         .( acc_clear        ),
        .out                        .( acc_clear_dly1   ),
    );

    always @( * ) begin
        acc_state_next = acc_state;
        case( acc_state )
            ACC_VALID: begin
                if ( acc_clear_dly1 )
                    acc_state_next = ACC_INVALID;
            end
            ACC_INVALID: begin
                if ( obuf_write_req )
                    acc_state_next = ACC_VALID;
            end
    end

    always @( posedge clk ) begin
        if ( reset )
            acc_state <= ACC_INVALID;
        else
            acc_state <= acc_state_next;
    end

    //=============================================================
    // Accumulator control logic
    //=============================================================
    
    // A signle output is ready after ARRAY_N cycles
    register_sync #(1) out_valid_delay(clk, reset, ou)

    
    
endmodule