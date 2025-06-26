module SPI_Wrapper #(parameter MEM_DEPTH = 256 , parameter ADDR_SIZE = 8)(
    input clk , ss_n , MOSI , rst_n ,
    output MISO 
);

// This module serves as an interface between the SPI_SLAVE and RAM modules

// Internal signal wires for communication between SPI_SLAVE and RAM
wire [9:0] rxdata;    // Data received from SPI
wire [7:0] txdata;    // Data to be sent back via SPI
wire rx_valid, tx_valid; // Control signals indicating data validity

// Instantiate SPI_SLAVE module
SPI_SLAVE SPI(
    .MOSI(MOSI),
    .MISO(MISO),
    .clk(clk),
    .ss_n(ss_n),
    .rst_n(rst_n),
    .rx_data(rxdata),  // Connect received data to RAM
    .tx_data(txdata),  // Connect transmitted data from RAM
    .rx_valid(rx_valid), // Indicate valid received data
    .tx_valid(tx_valid)  // Indicate valid data for transmission
);

// Instantiate RAM module with parameterized memory depth and address size
RAM #(MEM_DEPTH, ADDR_SIZE) Ram (
    .din(rxdata),       // Data input from SPI_SLAVE
    .dout(txdata),      // Data output to SPI_SLAVE
    .clk(clk),
    .rx_valid(rx_valid),
    .tx_valid(tx_valid),
    .rst_n(rst_n)
);

endmodule
