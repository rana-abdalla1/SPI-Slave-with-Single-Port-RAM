module RAM #(
    parameter MEM_DEPTH = 256,  // Memory depth
    parameter ADDR_SIZE = 8    // Address size
)(
    input clk,
    input rst_n,
    input rx_valid,
    input [9:0] din,         // 10-bit input data
    output reg [7:0] dout,   // 8-bit output data
    output reg tx_valid      // Transmission valid signal
);

// Creating the memory array
reg [ADDR_SIZE-1:0] memory [MEM_DEPTH-1:0]; // Memory array with address size equal to memory width

// Internal registers
reg [7:0] addr_wr; // Write address for storing data
reg [7:0] addr_re; // Read address for retrieving data

// Sequential logic for memory operations
always @(posedge clk) begin  
    if (!rst_n) begin   
        // Reset logic (synchronous reset)
        dout <= 8'b0;
        tx_valid <= 1'b0;
        addr_wr <= 8'b0;
        addr_re <= 8'b0;
    end else begin
        if (rx_valid) begin // Process input only when rx_valid is high
            case (din[9:8])
                2'b00: begin
                    // Store the write address
                    addr_wr <= din[7:0];
                    tx_valid <= 1'b0;
                end
                2'b01: begin
                    // Write data to the previously specified address
                    memory[addr_wr] <= din[7:0];
                    tx_valid <= 1'b0;
                end
                2'b10: begin
                    // Store the read address
                    addr_re <= din[7:0];
                    tx_valid <= 1'b0;
                end
                2'b11: begin
                    // Read data from the previously specified address and send it out
                    dout <= memory[addr_re];
                    tx_valid <= 1'b1;
                end
            endcase
        end
    end
end

endmodule
