`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.11.2026 23:25:49
// Design Name: 
// Module Name: weight_memory
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module weight_memory (
    input logic clk,
    input logic reset,
    input logic rd_en,
    input logic [3:0] addr,
    output logic [7:0] rd_data,
    output logic rd_valid
);
    logic [7:0] mem [0:15];
    initial begin
        for (int i = 0; i < 16; i++)
        mem[i] = 8'd0;
        mem[2]  = 8'd10;
        mem[4]  = 8'd20;
        mem[6]  = 8'd30;
        mem[8]  = 8'd40;
        mem[10] = 8'd50;
    end
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            rd_data  <= 8'd0;
            rd_valid <= 1'b0;
        end
        else begin
            rd_valid <= rd_en;
            if (rd_en)
                rd_data <= mem[addr];
        end
    end
endmodule
