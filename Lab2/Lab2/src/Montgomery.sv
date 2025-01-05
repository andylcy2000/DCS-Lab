module Montgomery (
    input          i_clk,
    input          i_rst,
    input          i_start,
    input  [255:0] i_N, i_a, i_b,
    output [255:0] o_montgomery,
    output         o_finished
);
    typedef enum logic {
        S_IDLE,
        S_CALC
    } state_t;

    localparam m_size = 4;
    localparam cycles = 256 / m_size;

    state_t state, state_nxt;
    logic [257:0] tmp1 [0:m_size-1];
    logic [257:0] tmp2 [0:m_size-1];
    logic [257:0] tmp3 [0:m_size-1];
    logic [257:0] m_r;
    logic [257:0] m_w;
    logic [255:0] N, a, b;
    logic [255:0] o_montgomery_r;
    logic o_finished_r;
    logic [8:0] cycle, cycle_nxt;
    logic [255:0] filter, filter_nxt;
    integer i;

    assign o_finished = o_finished_r;
    assign o_montgomery = o_montgomery_r;

    always_comb begin
        state_nxt = state;
        cycle_nxt = 0;
        filter_nxt = 1;
        for (i = 0; i < m_size; i = i + 1) begin
            tmp1[i] = 0;
            tmp2[i] = 0;
            tmp3[i] = 0;
        end
        m_w = 0;
        case(state)
            S_IDLE: begin
                if(i_start) begin
                    state_nxt = S_CALC;
                end
                filter_nxt = 1;
            end
            S_CALC: begin
                cycle_nxt = cycle + 1;
                filter_nxt = filter << m_size;
                if(cycle < cycles) begin
                    state_nxt = S_CALC;
                    tmp1[0] = (| (a & filter)) ? m_r + b : m_r;
                    tmp2[0] = (| (tmp1[0] & 1'b1)) ? tmp1[0] + N : tmp1[0];
                    tmp3[0] = tmp2[0] >> 1;
                    for (i = 1; i < m_size; i = i + 1) begin
                        tmp1[i] = (| (a & (filter << i))) ? tmp3[i - 1] + b : tmp3[i - 1];
                        tmp2[i] = (| (tmp1[i] & 1'b1)) ? tmp1[i] + N : tmp1[i];
                        tmp3[i] = tmp2[i] >> 1;
                    end
                    m_w = tmp3[m_size - 1];
                end else begin
                    state_nxt = S_IDLE;
                    cycle_nxt = 0;
                end
            end
        endcase
    end

    always_ff @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            m_r <= 0;
            state <= S_IDLE;
            cycle <= 0;
            o_finished_r <= 0;
            o_montgomery_r <= 0;
            filter <= 1;
            a <= 0;
            b <= 0;
            N <= 0;
        end else begin
            o_finished_r <= 0;
            o_montgomery_r <= (m_r >= {2'b0, N}) ? m_r - N : m_r;
            state <= state_nxt;
            cycle <= cycle_nxt;
            filter <= filter_nxt;
            if (state == S_IDLE && state_nxt == S_CALC) begin
                N <= i_N;
                a <= i_a;
                b <= i_b;
                m_r <= 0;
            end else if (state == S_CALC && state_nxt == S_CALC) begin
                m_r <= m_w;
            end else if (state == S_CALC && state_nxt == S_IDLE) begin
                o_finished_r <= 1;
            end
        end
    end

    
    
endmodule