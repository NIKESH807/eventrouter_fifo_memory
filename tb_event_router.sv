`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.11.2026 08:21:09
// Design Name: 
// Module Name: tb_event_router
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
module tb_event_router;
    logic clk;
    logic reset;
    logic event_valid;
    logic [3:0] source_addr;
    logic event_ready;
    logic output_ready;
    logic [3:0] target_addr;
    logic match;
    logic output_valid;
    logic fifo_full;
    logic fifo_empty;
    event_router DUT (
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
    always #5 clk = ~clk;
    always @(posedge clk) begin
       if (output_valid && output_ready) begin
        $display("TIME=%0t SOURCE=%b TARGET=%b MATCH=%b FIFO_COUNT=%0d",
            $time, DUT.fifo_data, target_addr, match, DUT.count);
       end
    end
    task send_event(input logic [3:0] addr);
        begin
            @(negedge clk);
            while (!event_ready)
                @(negedge clk);
            source_addr = addr;
            event_valid =1'b1;
            @(negedge clk);
            event_valid = 1'b0;
        end
    endtask
    initial begin
    clk = 0;
    reset = 1;
    event_valid = 0;
    source_addr = 0;
    output_ready = 0;
    #20;
    reset = 0;
    send_event(4'b0001);
    send_event(4'b0010);
    send_event(4'b0011);
    send_event(4'b0100);
    send_event(4'b0101);
    #1;
    $display("FIFO FULL = %b", fifo_full);
    output_ready = 1;
    wait(fifo_empty);
    send_event(4'b1111);
    wait(fifo_empty);
    #20;
    $display("SIMULATION COMPLETED");
    $finish;
end
endmodule

