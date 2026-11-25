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
    parameter TOTAL_EVENTS = 500;
    logic [3:0] expected_events [0:TOTAL_EVENTS-1];
    integer accepted_count = 0;
    integer processed_count = 0;
    integer valid_event_count = 0;
    integer invalid_event_count = 0;
    integer correct_weight_count = 0;
    integer incorrect_weight_count = 0;
    integer missing_count = 0;
    integer duplicate_count = 0;
    integer routing_error_count = 0;
    integer i;
    integer random_choice;
    integer random_gap;
    logic finish_driving = 0;
    logic [3:0] sampled_source;
    logic [3:0] sampled_target;
    logic sampled_match;
    logic [3:0] expected_source;
    logic [3:0] expected_target;
    logic [7:0] expected_weight;
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
    function automatic logic [3:0] get_target(
        input logic [3:0] source
    );
        case (source)
            4'b0001: get_target = 4'b0010;
            4'b0010: get_target = 4'b0100;
            4'b0011: get_target = 4'b0110;
            4'b0100: get_target = 4'b1000;
            4'b0101: get_target = 4'b1010;
            default: get_target = 4'b0000;
        endcase
    endfunction
    function automatic logic [7:0] get_weight(
        input logic [3:0] source
    );
        case (source)
            4'b0001: get_weight = 8'd10;
            4'b0010: get_weight = 8'd20;
            4'b0011: get_weight = 8'd30;
            4'b0100: get_weight = 8'd40;
            4'b0101: get_weight = 8'd50;
            default: get_weight = 8'd0;
        endcase
    endfunction
    always @(negedge clk) begin
        if (!reset && !finish_driving) begin
            output_ready = $urandom_range(0, 1);
        end
        else if (finish_driving) begin
            output_ready = 1'b1;
        end
    end
    always @(posedge clk) begin
        if (!reset && output_valid && output_ready) begin
            sampled_source = DUT.ROUTER.fifo_data;
            sampled_target = target_addr;
            sampled_match = match;
            #1;
            processed_count = processed_count + 1;
            $display(
                "OUTPUT %0d | SOURCE=%b | TARGET=%b | MATCH=%b | WEIGHT=%0d | WEIGHT_VALID=%b",
                processed_count,
                sampled_source,
                sampled_target,
                sampled_match,
                weight_data,
                weight_valid
            );
            if (processed_count > accepted_count) begin
                $display("ERROR: Unexpected output event");
                duplicate_count = duplicate_count + 1;
            end
            else begin
                expected_source =expected_events[processed_count-1];
                expected_target = get_target(expected_source);
                expected_weight = get_weight(expected_source);
                if (sampled_source !== expected_source) begin
                    $display(
                        "ERROR: Event order mismatch. Expected=%b Actual=%b",
                        expected_source, sampled_source
                    );
                    routing_error_count =
                        routing_error_count + 1;
                end
                if (expected_target == 4'b0000) begin
                    invalid_event_count =
                        invalid_event_count + 1;
                    if (sampled_match !== 1'b0 ||
                        sampled_target !== 4'b0000 ||
                        weight_valid !== 1'b0) begin
                        $display("ERROR: Invalid event was handled incorrectly");
                        routing_error_count =
                            routing_error_count + 1;
                    end
                end
                else begin
                    valid_event_count =
                        valid_event_count + 1;
                    if (sampled_match === 1'b1 &&
                        sampled_target === expected_target &&
                        weight_valid === 1'b1 &&
                        weight_data === expected_weight) begin
                        correct_weight_count =
                            correct_weight_count + 1;
                    end
                    else begin
                        incorrect_weight_count =
                            incorrect_weight_count + 1;
                        $display(
                            "WEIGHT ERROR: Expected target=%b weight=%0d",
                            expected_target, expected_weight
                        );
                    end
                end
            end
        end
    end

    task automatic send_event(
        input logic [3:0] addr
    );
        begin
            @(negedge clk);
            source_addr = addr;
            event_valid = 1'b1;
            do begin
                @(posedge clk);
            end while (event_ready !== 1'b1);
            accepted_count = accepted_count + 1;
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
        $display("");
        repeat (3) @(negedge clk);
        reset = 0;
        for (i = 0; i < TOTAL_EVENTS; i = i + 1) begin
            random_choice = $urandom_range(0, 9);
            if (random_choice < 8) begin
                expected_events[i] =
                    $urandom_range(1, 5);
            end
            else begin
                expected_events[i] =
                    $urandom_range(6, 15);
            end
        end
        $display("Random events generated = %0d", TOTAL_EVENTS);
        for (i = 0; i < TOTAL_EVENTS; i = i + 1) begin
            send_event(expected_events[i]);
            random_gap = $urandom_range(0, 5);
            repeat (random_gap)
                @(negedge clk);
        end
        @(negedge clk);
        finish_driving = 1;
        output_ready = 1;
        event_valid = 0;
        wait(processed_count == accepted_count);
        repeat (3) @(negedge clk);
        missing_count = accepted_count - processed_count;
        $display("");
        $display("FINAL RANDOM EVENT TEST REPORT");
        $display("======================================");
        $display("Total events generated       = %0d", TOTAL_EVENTS);
        $display("Total events accepted        = %0d", accepted_count);
        $display("Total events processed       = %0d", processed_count);
        $display("Valid events processed       = %0d", valid_event_count);
        $display("Invalid events processed     = %0d", invalid_event_count);
        $display("Correct weight reads         = %0d", correct_weight_count);
        $display("Incorrect weight reads       = %0d", incorrect_weight_count);
        $display("Missing events               = %0d", missing_count);
        $display("Duplicate/unexpected outputs = %0d", duplicate_count);
        $display("Routing/order errors         = %0d", routing_error_count);
        $display("FIFO EMPTY                   = %b", fifo_empty);
        $display("======================================");
        if (accepted_count == TOTAL_EVENTS &&
            processed_count == TOTAL_EVENTS &&
            missing_count == 0 &&
            duplicate_count == 0 &&
            routing_error_count == 0 &&
            incorrect_weight_count == 0 &&
            fifo_empty == 1) begin
            $display("FINAL RESULT: PASS");
        end
        else begin
            $display("FINAL RESULT: FAIL");
        end
        $finish;
    end
    initial begin
        #200000;
        $display("ERROR: SIMULATION TIMEOUT");
        $finish;
    end
endmodule