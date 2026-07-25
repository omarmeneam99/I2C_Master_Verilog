module I2C_master (
    input wire clk,rst,start,stop,rw,ack,
    input wire [6:0] slave_addr,
    input wire[7:0] tx_data,
    output reg busy,error,data_ready,
    output reg [7:0] rx_data,
    inout SCL,
    inout SDA
);
//
reg sda_reg;
reg sda_oe;
reg [3:0] bit_cnt;
reg [7:0] addr_byte;
// State encoding for fsm
localparam IDLE       = 4'd0;  // Idle, waiting for start
localparam START      = 4'd1;  // Generate START condition
localparam ADDRESS    = 4'd2;  // Send slave address + R/W bit
localparam ACK_ADDR   = 4'd3;  // Wait for ACK after address
localparam WRITE_DATA = 4'd4;  // Transmit data byte
localparam ACK_WRITE  = 4'd5;  // Wait for ACK after write
localparam READ_DATA  = 4'd6;  // Receive data byte
localparam ACK_READ   = 4'd7;  // Send ACK/NACK after read
localparam STOP       = 4'd8;  // Generate STOP condition
localparam STOP_HOLD  = 4'd9;  // Hold STOP before returning to idle
localparam START_HOLD = 4'd10; // Hold START before address phase
//
reg[3:0] cs,ns;
//generate SCL 
reg scl_reg;
reg scl_oe;
always @(posedge clk) begin
    if (rst)
        scl_reg <= 1'b1;
    else begin
        case (cs)
            ADDRESS: scl_reg <= ~scl_reg;
            ACK_ADDR: scl_reg <= ~scl_reg;
            WRITE_DATA: scl_reg <= ~scl_reg;
            ACK_WRITE: scl_reg <= ~scl_reg;
            READ_DATA: scl_reg <= ~scl_reg;
            ACK_READ:  scl_reg <= ~scl_reg;
            default:
                scl_reg <= 1'b1; 
        endcase
    end
end
//cs-ns logic
always @(posedge clk or posedge rst) begin
    if (rst)
        cs <= IDLE;
    else
        cs <= ns;
end
//fsm logic
always @(*) begin
    case(cs)
    IDLE: begin
      if(start)
      ns=START;
      else
      ns=IDLE;
    end
    START: begin
      if(scl_reg)
      ns=START_HOLD;
      else 
      ns=START;
    end
    START_HOLD :begin
      ns=ADDRESS;
    end
    ADDRESS: begin
      if (bit_cnt == 0)
        ns = ACK_ADDR;
        else
        ns = ADDRESS;
    end
    ACK_ADDR: begin
    if (scl_reg) begin
        if (SDA)
            ns = STOP;   
        else if (rw)
            ns = READ_DATA;
        else
            ns = WRITE_DATA;
    end
    else
        ns = ACK_ADDR;
    end
    WRITE_DATA: begin
        if(bit_cnt == 0)
            ns = ACK_WRITE;
        else
            ns = WRITE_DATA;
    end
    ACK_WRITE: begin
    if (scl_reg) begin
        if (SDA)
            ns = STOP;
        else if (stop)
            ns = STOP;
        else
            ns = WRITE_DATA;
    end
    else
        ns = ACK_WRITE;
    end
    READ_DATA: begin
        if(stop)
            ns = STOP;
        else if(bit_cnt == 0)
            ns = ACK_READ;
        else
            ns = READ_DATA;
    end
    ACK_READ: begin
        if(ack)
            ns = READ_DATA;
        else
            ns = STOP;
    end
    STOP: begin
    if(scl_reg)
        ns = STOP_HOLD;
    else
        ns = STOP;
    end
    STOP_HOLD :
        ns=IDLE;
    default  ns=IDLE;
    endcase
end
//counter logic
always @(posedge clk or posedge rst) begin
    if (rst)
        bit_cnt <= 4'd8;
    else begin
        case (cs)
            START: begin
                bit_cnt <= 4'd8;
                addr_byte <= {slave_addr,rw};
            end 
            ADDRESS: begin
                if(scl_reg) begin
                 if (bit_cnt > 0)
                    bit_cnt <= bit_cnt - 1;  
                end
            end
            ACK_ADDR: 
                bit_cnt <= 4'd8;
            WRITE_DATA: begin
                if(scl_reg) begin
                 if (bit_cnt > 0)
                    bit_cnt <= bit_cnt - 1;  
                end
            end
            ACK_WRITE:
                bit_cnt <= 4'd8;
            READ_DATA: begin
                if(scl_reg) begin
                rx_data[bit_cnt-1] <= SDA;
                if (bit_cnt > 0)
                    bit_cnt <= bit_cnt - 1;
                end
            end
            ACK_READ: 
                bit_cnt <= 4'd8;
            default : 
                bit_cnt<=bit_cnt;
        endcase
    end
end
//sda logic 
always @(posedge clk or posedge rst) begin
    if(rst) begin
      sda_reg<=1;
    end
    else begin
    case (cs)
        START:
            sda_reg <= 0;
        ADDRESS:
            sda_reg <= addr_byte[bit_cnt-1];
        WRITE_DATA:
            sda_reg <= tx_data[bit_cnt-1];
        ACK_READ: begin
        if (ack)
            sda_reg <= 0;
        else
            sda_reg <= 1;
        end
        STOP:
            sda_reg <= 0;
        STOP_HOLD:
            sda_reg <= 1;
        default : 
            sda_reg <=1;
    endcase
    end
end
//output logic
always @(*) begin
    error=0;
    busy=0;
    data_ready=0;
    sda_oe=0;
    scl_oe=1;
    case(cs)
    IDLE : begin
        busy=0;
        scl_oe=0;
        sda_oe=1;
    end
    START : begin
        busy=1;
        sda_oe=1;
    end
    START_HOLD : begin
        busy=1;
        sda_oe=1;
    end
    ADDRESS : begin
        busy = 1;
        sda_oe=1;       
    end
    ACK_ADDR : begin
        busy = 1;
        sda_oe = 0;
        if(SDA == 1'b1)
        error = 1;
    end
    WRITE_DATA : begin
        busy = 1;
        sda_oe=1;
    end
    ACK_WRITE : begin
        busy = 1;
        sda_oe=0;
        if(SDA == 1'b1)
        error = 1;
    end
    READ_DATA : begin
        busy = 1;
        sda_oe=0;
        if(bit_cnt==0) data_ready=1;
    end
    ACK_READ: begin
    busy = 1;
    sda_oe=1;
    end
    STOP : begin
        busy = 0;
        sda_oe = 1;
    end
    STOP_HOLD : begin
        busy=0;
        sda_oe=1;
    end
    endcase
end
assign SDA = sda_oe ? sda_reg : 1'bz;
assign SCL = scl_oe ? scl_reg : 1'bz;
endmodule //I2C_master