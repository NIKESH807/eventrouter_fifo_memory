`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.11.2026 20:06:43
// Design Name: 
// Module Name: tb_fifo_corner_cases
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
module tb_fifo_corner_cases;
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
    integer errors = 0;
    logic [3:0] received_data;
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
    task automatic push(input logic [3:0] data);
        begin
            @(negedge clk);
            source_addr = data;
            event_valid = 1'b1;
            while (event_ready !== 1'b1)
                @(negedge clk);
            @(posedge clk);
            @(negedge clk);
            event_valid = 1'b0;
        end
    endtask
    task automatic pop_check(input logic [3:0] expected);
        begin
            @(negedge clk);
            output_ready = 1'b1;
            while (output_valid !== 1'b1)
                @(negedge clk);
            received_data = DUT.fifo_data;
            @(posedge clk);
            if (received_data === expected) begin
                $display("PASS: Expected = %b, Received = %b",expected, received_data);
            end
            else begin
                $display("FAIL: Expected = %b, Received = %b",expected, received_data);
                errors = errors + 1;
            end
            @(negedge clk);
            output_ready = 1'b0;
        end
    endtask
    task automatic check_count(input integer expected);
        begin
            if (DUT.count === expected) begin
                $display("PASS: FIFO count = %0d", expected);
            end
            else begin
                $display("FAIL: Expected count = %0d, Actual count = %0d",
                         expected, DUT.count);
                errors = errors + 1;
            end
        end
    endtask
    initial begin
        clk = 0;
        reset = 1;
        event_valid = 0;
        source_addr = 0;
        output_ready = 0;
        $display("");
        $display("====================================");
        $display("       FIFO CORNER CASE TESTING");
        $display("====================================");
        $display("");
        $display("TEST 1: RESET AND EMPTY");
        repeat (3) @(negedge clk);
        reset = 0;
        @(negedge clk);
        if (fifo_empty && !fifo_full)
            $display("PASS: FIFO is empty after reset");
        else begin
            $display("FAIL: FIFO reset condition");
            errors = errors + 1;
        end
        check_count(0);
        $display("");
        $display("TEST 2: READ WHEN EMPTY");
        output_ready = 1;
        @(posedge clk);
        @(negedge clk);
        output_ready = 0;
        if (fifo_empty && DUT.count == 0)
            $display("PASS: Read blocked when FIFO is empty");
        else begin
            $display("FAIL: Empty read condition");
            errors = errors + 1;
        end
        $display("");
        $display("TEST 3: FILL FIFO");
        push(4'b0001);
        push(4'b0010);
        push(4'b0011);
        push(4'b0100);
        push(4'b0101);
        if (fifo_full)
            $display("PASS: FIFO became FULL");
        else begin
            $display("FAIL: FIFO did not become FULL");
            errors = errors + 1;
        end
        check_count(5);
        $display("");
        $display("TEST 4: WRITE WHEN FULL");
        @(negedge clk);
        source_addr = 4'b0110;
        event_valid = 1;
        output_ready = 0;
        if (!event_ready)
            $display("PASS: FIFO rejected new event when full");
        else begin
            $display("FAIL: FIFO accepted event when full");
            errors = errors + 1;
        end
        @(posedge clk);
        @(negedge clk);
        event_valid = 0;
        check_count(5);
        $display("");
        $display("TEST 5: READ AND CHECK EVENT ORDER");
        pop_check(4'b0001);
        pop_check(4'b0010);
        pop_check(4'b0011);
        pop_check(4'b0100);
        pop_check(4'b0101);
        if (fifo_empty)
            $display("PASS: FIFO became EMPTY after reading");
        else begin
            $display("FAIL: FIFO is not empty");
            errors = errors + 1;
        end
        check_count(0);
        $display("");
        $display("TEST 6: SIMULTANEOUS READ AND WRITE");
        push(4'b0001);
        push(4'b0010);
        push(4'b0011);
        @(negedge clk);
        source_addr = 4'b0100;
        event_valid = 1;
        output_ready = 1;
        if (event_ready && output_valid)
            $display("PASS: Read and write both enabled");
        else begin
            $display("FAIL: Simultaneous operation not enabled");
            errors = errors + 1;
        end
        @(posedge clk);
        @(negedge clk);
        event_valid = 0;
        output_ready = 0;
        check_count(3);
        pop_check(4'b0010);
        pop_check(4'b0011);
        pop_check(4'b0100);
        $display("");
        $display("TEST 7: READ AND WRITE REQUEST WHEN FULL");
        push(4'b0001);
        push(4'b0010);
        push(4'b0011);
        push(4'b0100);
        push(4'b0101);
        @(negedge clk);
        source_addr = 4'b0110;
        event_valid = 1;
        output_ready = 1;
        if (!event_ready && output_valid)
            $display("PASS: Read allowed, write blocked when full");
        else begin
            $display("FAIL: Incorrect full boundary behavior");
            errors = errors + 1;
        end
        @(posedge clk);
        @(negedge clk);
        event_valid = 0;
        output_ready = 0;
        check_count(4);
        pop_check(4'b0010);
        pop_check(4'b0011);
        pop_check(4'b0100);
        pop_check(4'b0101);
        $display("");
        $display("TEST 8: READ AND WRITE REQUEST WHEN EMPTY");
        @(negedge clk);
        source_addr = 4'b1001;
        event_valid = 1;
        output_ready = 1;
        if (event_ready && !output_valid)
            $display("PASS: Write allowed, read blocked when empty");
        else begin
            $display("FAIL: Incorrect empty boundary behavior");
            errors = errors + 1;
        end
        @(posedge clk);
        @(negedge clk);
        event_valid = 0;
        output_ready = 0;
        check_count(1);
        pop_check(4'b1001);
        $display("");
        $display("TEST 9: POINTER WRAPAROUND");
        push(4'b0001);
        pop_check(4'b0001);
        push(4'b0010);
        pop_check(4'b0010);
        push(4'b0011);
        pop_check(4'b0011);
        push(4'b0100);
        pop_check(4'b0100);
        push(4'b0101);
        pop_check(4'b0101);
        push(4'b0110);
        pop_check(4'b0110);
        if (fifo_empty && DUT.count == 0)
            $display("PASS: FIFO pointer wraparound test");
        else begin
            $display("FAIL: FIFO pointer wraparound test");
            errors = errors + 1;
        end
        $display("");
        $display("====================================");
        $display("          FINAL TEST REPORT");
        $display("====================================");
        $display("Total test errors = %0d", errors);
        if (errors == 0)
            $display("RESULT: ALL TESTS PASSED");
        else
            $display("RESULT: SOME TESTS FAILED");
        $display("====================================");
        $finish;
    end
endmodule