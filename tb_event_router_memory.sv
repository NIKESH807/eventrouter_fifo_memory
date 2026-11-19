`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.11.2026 23:45:36
// Design Name: 
// Module Name: tb_event_router_memory
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
module tb_event_router_memory;
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
    logic [7:0] weight_data;
    logic weight_valid;
    integer pass_count = 0;
    integer fail_count = 0;
    logic [3:0] sampled_source;
    logic [3:0] sampled_target;
    logic sampled_match;
    event_router_memory_top DUT (
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
        .fifo_empty(fifo_empty),
        .weight_data(weight_data),
        .weight_valid(weight_valid)
    );
    always #5 clk = ~clk;
    always @(posedge clk) begin
        if (output_valid && output_ready) begin
            sampled_source = DUT.ROUTER.fifo_data;
            sampled_target = target_addr;
            sampled_match = match;
            #1;
            $display(
                "SOURCE=%b TARGET=%b MATCH=%b WEIGHT=%0d WEIGHT_VALID=%b",
                sampled_source,
                sampled_target,
                sampled_match,
                weight_data,
                weight_valid
            );
            case (sampled_source)
                4'b0001: begin
                    if (sampled_target == 4'b0010 &&
                        sampled_match == 1 &&
                        weight_valid == 1 &&
                        weight_data == 8'd10)
                        pass_count = pass_count + 1;
                    else
                        fail_count = fail_count + 1;
                end
                4'b0010: begin
                    if (sampled_target == 4'b0100 &&
                        sampled_match == 1 &&
                        weight_valid == 1 &&
                        weight_data == 8'd20)
                        pass_count = pass_count + 1;
                    else
                        fail_count = fail_count + 1;
                end
                4'b0011: begin
                    if (sampled_target == 4'b0110 &&
                        sampled_match == 1 &&
                        weight_valid == 1 &&
                        weight_data == 8'd30)
                        pass_count = pass_count + 1;
                    else
                        fail_count = fail_count + 1;
                end
                4'b0100: begin
                    if (sampled_target == 4'b1000 &&
                        sampled_match == 1 &&
                        weight_valid == 1 &&
                        weight_data == 8'd40)
                        pass_count = pass_count + 1;
                    else
                        fail_count = fail_count + 1;
                end

                4'b0101: begin
                    if (sampled_target == 4'b1010 &&
                        sampled_match == 1 &&
                        weight_valid == 1 &&
                        weight_data == 8'd50)
                        pass_count = pass_count + 1;
                    else
                        fail_count = fail_count + 1;
                end
                4'b1111: begin
                    if (sampled_match == 0 && weight_valid == 0)
                        pass_count = pass_count + 1;
                    else
                        fail_count = fail_count + 1;
                end
            endcase
        end
    end
    task send_event(input logic [3:0] addr);
        begin
            @(negedge clk);
            while (!event_ready)
                @(negedge clk);
            source_addr = addr;
            event_valid = 1'b1;
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
        #5;
        $display("TOTAL PASS = %0d", pass_count);
        $display("TOTAL FAIL = %0d", fail_count);
        if (pass_count == 6 && fail_count == 0)
            $display("INTEGRATION TEST PASSED");
        else
            $display("INTEGRATION TEST FAILED");
        $display("SIMULATION COMPLETED");
        $finish;
    end
endmodule

