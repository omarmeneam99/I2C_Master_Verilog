module I2C_SLave (
    input wire clk,rst,we,  
    input wire [6:0] s_address,
    input wire [7:0] rx_data, // idk where to use it
    output reg [7:0] tx_data,
    inout SDA,
    inout SCL
);  
reg [7:0] slave_mem [0:255]; //slave memory
reg sda_oe,sda_reg,scl_oe,scl_reg;
reg [3:0]bit_cnt; // bit count to complete byte reading
reg [3:0] cs,ns;
reg [7:0] addr_byte; //store address byte to compare to our slave address
wire rw;
assign rw=addr_byte[0];
reg [7:0] written_byte; // store written byte then put in tx data
reg [7:0] write_addr; // to store our write in slave memory
reg [7:0] read_addr; // to send our read in slave memory
// for ack_address
wire address_match;
assign address_match = (addr_byte[7:1] == s_address);
//States
localparam IDLE       = 4'd0; // Idle, waiting for start
localparam ADDRESS    = 4'd1; // Recieve slave address + R/W bit
localparam ACK_ADDR   = 4'd2; // Send ACK if recieved address match my slave addresss
localparam WRITE_DATA = 4'd3; // Recieved data byte is stored in slave memory
localparam ACK_WRITE  = 4'd4; // Send ACK when finish writing (idk if u wanted memory full condition for NACK , spec didnt mention it)
localparam READ_DATA  = 4'd5; // Extract data from my slave memory and send it to master
localparam ACK_READ   = 4'd6; // Master sends ack to continue reading or it stops the process
//clock 
always @(posedge clk) begin
    if (rst)
        scl_reg <= 1'b1;
    else begin
        scl_reg<=~scl_reg;
    end
end
//sda previous to detect start and stop
reg sda_prev;
always @(posedge clk) begin
    sda_prev <= SDA;
end
wire startedge 
assign startedge = (sda_prev == 1 && SDA == 0 && SCL);
wire stopedge  
assign stopedge = (sda_prev == 0 && SDA == 1 && SCL);
//ns-cs
always @(posedge clk or posedge rst) begin
    if (rst)
        cs <= IDLE;
    else
        cs <= ns;
end
//fsm logic
always @(*) begin
    if (stopedge) begin
        ns = IDLE;
    end
    else begin
    case (cs)
        IDLE: begin
            if(startedge) ns=ADDRESS;
            else ns=IDLE;
        end
        ADDRESS: begin
            if(bit_cnt==0) ns=ACK_ADDR;
            else ns=ADDRESS;
        end
        ACK_ADDR: begin
            if(address_match) begin
                if(rw)  ns = READ_DATA;
                else    ns = WRITE_DATA;
            end
        else    ns = IDLE;
        end
        WRITE_DATA: begin
            if(bit_cnt==0) ns=ACK_WRITE;
            else ns=WRITE_DATA;
        end
        ACK_WRITE: begin
            ns=WRITE_DATA;
        end
        READ_DATA: begin
            if(bit_cnt==0) ns = ACK_READ;
            else    ns = READ_DATA;
        end
        ACK_READ: begin
            if(!SDA) ns = READ_DATA;
            else ns=IDLE;
        end
        default: begin
            ns = IDLE;
        end
    endcase
    end
end
//counter and sda_reg logic
always @(posedge clk or posedge rst) begin
    if (rst) begin
        bit_cnt <= 4'd8;
        write_addr <= 8'd0;
        read_addr  <= 8'd0;
    end
    else begin
        case (cs)
            IDLE: begin
                bit_cnt <= 4'd8;
            end 
            ADDRESS: begin
                if (SCL && bit_cnt > 0) begin
                    addr_byte[bit_cnt-1] <= SDA;
                    bit_cnt <= bit_cnt - 1;
                end
            end
            ACK_ADDR: begin
                bit_cnt <= 4'd8;
                if (address_match)begin
                  sda_reg <= 1'b0;
                end  
                else begin
                    sda_reg <= 1'b1;
                end
            end
            WRITE_DATA: begin
                if (SCL && bit_cnt > 0) begin
                    written_byte[bit_cnt-1] <= SDA;
                    bit_cnt <= bit_cnt - 1;
                end
            end
            ACK_WRITE: begin
                sda_reg <= 1'b0;
                bit_cnt <= 4'd8;
                tx_data <= written_byte;
                if (we) begin
                slave_mem[write_addr] <= written_byte;
                write_addr <= write_addr + 1;
            end
            end 
            READ_DATA: begin
                if (SCL && bit_cnt > 0) begin
                sda_reg <= slave_mem[read_addr][bit_cnt-1];
                bit_cnt <= bit_cnt - 1;
            end
            end
            ACK_READ:  begin
                bit_cnt <= 4'd8;
                read_addr<=read_addr+1;
            end
            default : 
                bit_cnt<=bit_cnt;
        endcase
    end
end
//output logic
always @(*) begin
    sda_oe = 0;
    scl_oe = 0;
    case (cs)
        ACK_ADDR:   sda_oe = 1;
        ACK_WRITE:  sda_oe = 1;
        READ_DATA:  sda_oe = 1;
        default:    sda_oe = 0;
    endcase
end
//
assign SDA = sda_oe ? sda_reg : 1'bz;
assign SCL = scl_oe ? scl_reg : 1'bz;
endmodule //I2C_SLave