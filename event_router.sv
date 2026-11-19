`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.11.2026 08:17:06
// Design Name: 
// Module Name: event_router
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
module event_router (
    input logic clk,
    input logic reset,
    input logic event_valid,
    input logic [3:0] source_addr,
    output logic event_ready,
    input logic output_ready,
    output logic [3:0] target_addr,
    output logic match,
    output logic output_valid,
    output logic fifo_full,
    output logic fifo_empty

);
    logic [3:0] memory [0:4];
    logic [2:0] write_ptr;
    logic [2:0] read_ptr;
    logic [2:0] count;
    logic [3:0] fifo_data;
    logic fifo_wr_en;
    logic fifo_rd_en;
    logic [3:0] source_table [0:4];
    logic [3:0] target_table [0:4];
    assign fifo_full  = (count == 5);
    assign fifo_empty = (count == 0);
    assign event_ready = !fifo_full;
    assign fifo_wr_en = event_valid && event_ready;
    assign output_valid = !fifo_empty;
    assign fifo_rd_en = output_valid && output_ready;
    assign fifo_data = memory[read_ptr];
    initial begin
        source_table[0] = 4'b0001;
        target_table[0] = 4'b0010;
        source_table[1] = 4'b0010;
        target_table[1] = 4'b0100;
        source_table[2] = 4'b0011;
        target_table[2] = 4'b0110;
        source_table[3] = 4'b0100;
        target_table[3] = 4'b1000;
        source_table[4] = 4'b0101;
        target_table[4] = 4'b1010;
    end
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            write_ptr <= 0;
            read_ptr  <= 0;
            count     <= 0;
        end
        else begin
            if (fifo_wr_en) begin
                memory[write_ptr] <= source_addr;
                if (write_ptr == 4)
                    write_ptr <= 0;
                else
                    write_ptr <= write_ptr + 1;
            end
            if (fifo_rd_en) begin
               if (read_ptr == 4)
                    read_ptr <= 0;
                else
                     read_ptr <= read_ptr + 1;
            end
            case ({fifo_wr_en, fifo_rd_en})
                2'b10: count <= count + 1;
                2'b01: count <= count - 1;
                default: count <= count;
            endcase
        end
    end
    always_comb begin
        target_addr = 4'b0000;
        match = 1'b0;
        for (int i = 0; i < 5; i++) begin
            if (fifo_data == source_table[i]) begin
                target_addr = target_table[i];
                match = 1'b1;
            end
        end
    end
endmodule
