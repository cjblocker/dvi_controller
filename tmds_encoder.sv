module tmds_encoder (
    input logic clk, rst_n,
    input [7:0] din,
    input [1:0] ctrl, 
    input disp_en, 
    output [9:0] dout
);

    function automatic logic [7:0] xnor_out(input logic [7:0] din);
        logic [7:0] dout;
        dout[0] = din[0];
        for (int i = 1; i < 8; i++) begin
            dout[i] = din[i] ~^ dout[i-1];
        end
        return dout;
    endfunction : xnor_out

    function automatic logic [7:0] xor_out(input logic [7:0] din);
        logic [7:0] dout;
        dout[0] = din[0];
        for (int i = 1; i < 8; i++) begin
            dout[i] = din[i] ^ dout[i-1];
        end
        return dout;
    endfunction : xor_out

    function automatic logic [3:0] count_bits(input logic [8:0] din);
        logic [3:0] result = 0;
        for (int i = 0; i < 8; i++)
            if(din[i]=1) result++;
        return result;
    endfunction : count_bits

    always_comb begin
        onesD = count_bits({0,din});
        if(onesD > 4 || (onesD == 4 && din[0] = 0)) begin
            x[7:0] = xnor_out(din);
            x[8] = 0;
        end
        else begin 
            x[7:0] = xor_out(din);
            x[8] = 1;
        end

        if(disp_en) begin
            dout[8] = x[8];
            onesX = count_bits(x);
            if(disparity_reg == 0 || onesX == 4) begin
                dout[9] = ~x[8];
                if(dout[9]) begin
                    dout[7:0] = ~x[7:0]
                    disparity_next = disparity_reg + 8 - (onesX + onesX);
                end
                else begin 
                    dout[7:0] = x[7:0];
                    disparity_next = disparity_reg - 8 + (onesX + onesX);
                end
            end
            else if(disparity_reg > 0 && onesX > 4 ||
                    disparity_reg < 0 && onesX < 4) begin
                dout[9] = 1;
                dout[7:0] = ~x[7:0];
                if(!x[8]) disparity_next = disparity_reg + 8 - (onesX + onesX);
                else disparity_next = disparity_reg + 8 - (onesX + onesX) + 2;   
            end
            else begin
                dout[9] = 0;
                dout[7:0] = x[7:0];
                if(!x[8]) disparity_next = disparity_reg - 8 + (onesX + onesX) - 2;
                else disparity_next = disparity_reg - 8 + (onesX + onesX);
            end
        end
        else begin
            unique casez (ctrl)
                2'b00: dout = 10'b11_0101_0100;
                2'b01: dout = 10'b00_1010_1011;
                2'b10: dout = 10'b01_0101_0100;
                2'b11: dout = 10'b10_1010_1011;
            endcase
            disparity_next = 0;
        end
    end

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n) disparity_reg <= 0;
        else disparity_reg <= disparity_next;

endmodule