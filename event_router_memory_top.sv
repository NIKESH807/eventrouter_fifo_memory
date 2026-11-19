`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.11.2026 23:26:59
// Design Name: 
// Module Name: event_router_memory_top
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
module event_router_memory_top (
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
    output logic fifo_empty,
    output logic [7:0] weight_data,
    output logic weight_valid
);
    logic memory_rd_en;
    assign memory_rd_en =
        output_valid && output_ready && match;
    event_router ROUTER (
        .clk(clk),
        .reset(reset),
        .event_valid(event_valid),
        .source_addr(source_addr),
        .event_ready(event_ready),
        .output_ready(output_ready),
        .target_addr(target_addr),
        .match(match),
        .output_valid(output_valid),
        .fifo_full(fifo_full),
        .fifo_empty(fifo_empty)
    );
    weight_memory WEIGHT_MEM (
        .clk(clk),
        .reset(reset),
        .rd_en(memory_rd_en),
        .addr(target_addr),
        .rd_data(weight_data),
        .rd_valid(weight_valid)
    );
endmodule
