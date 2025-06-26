module SPI_SLAVE(
    input MOSI , tx_valid , clk , rst_n , ss_n ,
    input [7:0] tx_data ,
    output reg  MISO , rx_valid , 
    output reg [9:0] rx_data  
);

// State Encoding
localparam IDLE = 3'b000,
           CHK_CMD = 3'b001,
           WRITE = 3'b010,
           READ_ADD = 3'b011,
           READ_DATA = 3'b100;

// Internal Registers
reg [2:0] cs , ns ; // Current state and next state
reg ADD_DATA_checker ; // Flag to determine whether to go to READ_ADD or READ_DATA state
reg [3:0] counter1 ; // General counter for filling rx_data
reg [2:0] counter2 ; // Specific counter for READ_DATA state
reg [9:0] bus ; // Internal buffer to store received data before assigning to rx_data

// State Memory - Sequential Logic
// Updates the current state on each clock cycle
always @(posedge clk)
begin
    if(~rst_n) 
        cs <= IDLE; // Reset to IDLE state
    else 
        cs <= ns ; // Transition to next state
end

// Next State Logic - Combinational Logic
always @(*) begin
    ns = cs ; // Default to current state
    case(cs)
        IDLE : begin
            if(ss_n) // If slave select is high, remain in IDLE
                ns = IDLE;
            else    
                ns = CHK_CMD; // Otherwise, check the command
        end
        CHK_CMD : begin
            if(ss_n)
                ns = IDLE; // If slave select is high, return to IDLE
            else begin
                if((~ss_n) && (MOSI == 0))
                    ns = WRITE; // MOSI = 0 -> Write operation
                else if ((~ss_n) && (MOSI == 1) && (ADD_DATA_checker == 1))
                    ns = READ_ADD; // MOSI = 1 and ADD_DATA_checker = 1 -> Read Address
                else if ((~ss_n) && (MOSI == 1) && (ADD_DATA_checker == 0))
                    ns = READ_DATA; // MOSI = 1 and ADD_DATA_checker = 0 -> Read Data
            end
        end
        WRITE : begin
            if(ss_n || counter1 == 4'b1111) // If slave select is high or data transfer is complete
                ns = IDLE;
            else 
                ns = WRITE; // Continue writing
        end
        READ_ADD : begin 
            if(ss_n || counter1 == 4'b1111) // If slave select is high or data transfer is complete
                ns = IDLE;     
            else
                ns = READ_ADD; // Continue reading address
        end
        READ_DATA : begin        
            if(ss_n)
                ns = IDLE; // If slave select is high, go to IDLE
            else
                ns = READ_DATA; // Continue reading data
        end
    endcase
end

// Output Logic - Handles Data Transfer and Control Signals
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        // Reset values
        counter1 <= 9; 
        counter2 <= 7; 
        ADD_DATA_checker <= 1; // Default: Read Address first
        bus <= 0;
        rx_data <= 0;
        rx_valid <= 0; 
        MISO  <= 0; // Default MISO output is zero
    end
    else begin
        // IDLE state behavior
        if(cs == IDLE) begin
            rx_valid <= 0;
            counter1 <= 9; // Reset counters for next operations
            counter2 <= 7; 
        end
        // WRITE state behavior
        else if(cs == WRITE) begin
            if (counter1 >= 0) begin
                bus[counter1] <= MOSI; // Shift received bit into bus
                counter1 <= counter1 - 1; // Decrement counter
            end
            if(counter1 == 4'b1111) begin // Data transfer complete
                rx_valid = 1;
                rx_data <= bus; // Send received data to rx_data
            end
        end
        // READ_ADD state behavior (similar to WRITE state)
        else if (cs == READ_ADD) begin
            if (counter1 >= 0) begin
                bus[counter1] <= MOSI;
                counter1 <= counter1 - 1; 
            end
            if(counter1 == 4'b1111) begin // Data transfer complete
                rx_valid <= 1;
                rx_data <= bus;
                ADD_DATA_checker <= 0; // Address received, prepare for data read
            end
        end
        // READ_DATA state behavior
        else if (cs == READ_DATA) begin
            if (counter1 >= 0) begin
                bus[counter1] <= MOSI;
                counter1 <= counter1 - 1; 
            end
            if(counter1 == 4'b1111) begin // Data transfer complete
                rx_valid <= 1;
                rx_data <= bus;
                counter1 <= 9; // Reset counter for next operation
            end
            if(rx_valid == 1) rx_valid <= 0; // Reset rx_valid after data is received
            
            if(tx_valid == 1 && counter2 >= 0) begin
                MISO <= tx_data[counter2]; // Send data from tx_data over MISO
                counter2 <= counter2 - 1;
            end
            if(counter2 == 3'b111) begin
                ADD_DATA_checker <= 1; // Reset ADD_DATA_checker to require address next time
            end
        end
    end
end

endmodule
