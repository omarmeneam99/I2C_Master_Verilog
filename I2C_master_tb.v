`timescale 1ps/1ps
module I2C_master_tb ();
reg clk,rst,start,stop,rw,ack;
reg [6:0] slave_addr;
reg[7:0] tx_data;
wire busy,error,data_ready;
wire [7:0] rx_data;
wire SCL;
wire SDA;
reg SDA_tb;
reg SDA_tb_en;

assign SDA = SDA_tb_en ? SDA_tb : 1'bz;

I2C_master DUT(clk, rst, start, stop, rw, ack,slave_addr, tx_data,busy, error, data_ready,rx_data,SCL, SDA);

    initial begin
        clk=0;
        forever begin
            #5 clk=~clk;
        end
    end
    reg [7:0] slave_data;
    initial begin
        rst=1; start=0; stop=0; ack=0; rw=0; SDA_tb_en = 0; SDA_tb = 1; // reset and initialization
        @(negedge clk);
        rst=0;
        @(negedge clk); 
        // Start condition + address (write)
        start=1;
        slave_addr=7'b1111111;
        rw=0;
        @(negedge SCL);
        start=0;
        repeat (8) @(posedge SCL);
        // WRITE (#) bytes
        repeat(5) begin
            SDA_tb_en = 1;
            SDA_tb = 0;
            tx_data=$random;
            @(negedge SCL);
            SDA_tb_en = 0;
            repeat(9) @(posedge SCL);
        end
        //STOP condition after write
        stop=1;
        @(negedge SCL);
        stop=0;
        SDA_tb_en = 0;
        @(negedge SCL);
        //Start condition + address (read)
        start=1;
        slave_addr=7'b1111111;
        rw=1;
        @(negedge SCL);
        start=0;
        repeat (8) @(posedge SCL);
        SDA_tb_en = 1;
        SDA_tb = 0;
        @(negedge SCL);
        //////// READ (#) bytes
        repeat(5) begin
        slave_data=$random;
        ack=0;
        repeat(9) begin
            SDA_tb_en=1;
            @(posedge SCL);
            SDA_tb=slave_data[7];
            slave_data={slave_data[6:0],1'b0};
        end 
        SDA_tb_en = 0;
        ack=1;
        @(negedge SCL);
        SDA_tb_en = 0;
        end
        //  write then read (#) bytes
        repeat (5)begin
        ack=0;
        stop=1;
        SDA_tb_en = 0; SDA_tb = 1;
        @(posedge SCL);
        stop=0;
        SDA_tb_en = 0;
        @(negedge SCL);
        start=1;
        slave_addr=$random(3);
        rw=0;
        tx_data=$random;
        @(negedge SCL);
        start=0;
        repeat (8) @(posedge SCL);
        SDA_tb_en = 1;
        SDA_tb = 0;
        @(negedge SCL);
        SDA_tb_en = 0;
        repeat(9) @(posedge SCL);
        //write
        SDA_tb_en = 1;
        SDA_tb = 0;
        stop=1;
        @(negedge SCL);
        stop=0;
        SDA_tb_en = 0;
        @(negedge SCL);
        start=1;
        slave_addr=$random(3);
        rw=1;
        @(negedge SCL);
        start=0;
        repeat (8) @(posedge SCL);
        SDA_tb_en = 1;
        SDA_tb = 0;
        @(negedge SCL);
        slave_data=tx_data;
        repeat(9) begin
            SDA_tb_en=1;
            @(posedge SCL);
            SDA_tb=slave_data[7];
            slave_data={slave_data[6:0],1'b0};
        end 
        SDA_tb_en = 0;
        ack=1;
        @(negedge SCL);
        SDA_tb_en = 0;
        end
        // Going back to idle
        ack=0;
        stop=1;
        SDA_tb_en = 0; SDA_tb = 1;
        @(posedge SCL);
        stop=0;
        SDA_tb_en = 0;
        @(negedge SCL);
        // read then write (#) bytes
        repeat (5)begin
            start=1;
            slave_addr=$random;
            rw=1;
            tx_data=$random;
            @(negedge SCL);
            start=0;
            repeat (8) @(posedge SCL);
            SDA_tb_en = 1;
            SDA_tb = 0;
            @(negedge SCL);
            SDA_tb_en = 0;
            repeat(9) begin
            SDA_tb_en=1;
            @(posedge SCL);
            SDA_tb=slave_data[7];
            slave_data={slave_data[6:0],1'b0};
            end 
            SDA_tb_en = 0;
            ack=1;
            @(negedge SCL);
            ack=0;
            stop=1;
            SDA_tb_en = 0; SDA_tb = 1;
            @(posedge SCL);
            stop=0;
            SDA_tb_en = 0;
            @(negedge SCL);
            start=1;
            slave_addr=$random;
            rw=0;
            tx_data=$random;
            @(negedge SCL);
            start=0;
            repeat (8) @(posedge SCL);
            SDA_tb_en = 1;
            SDA_tb = 0;
            @(negedge SCL);
            SDA_tb_en = 0;
            repeat(9) @(posedge SCL);
            SDA_tb_en = 1;
            SDA_tb = 0;
            stop=1;
            @(negedge SCL);
            stop=0;
            SDA_tb_en = 0;
            @(negedge SCL);
        end
        // NACK during write
        start=1;
        slave_addr=7'b1111111;
        rw=0;
        tx_data=8'b10101010;
        @(negedge SCL);
        start=0;
        repeat (8) @(posedge SCL);
        SDA_tb_en = 1;
        SDA_tb = 0;
        @(negedge SCL);
        SDA_tb_en = 0;
        repeat(9) @(posedge SCL);
        // write done 
        SDA_tb_en = 1;
        SDA_tb = 1;
        @(negedge SCL);
        SDA_tb_en = 0;
        @(negedge SCL);
        // NACK during read
        start=1;
        slave_addr=7'b1111111;
        rw=1;
        tx_data=8'b10101010;
        @(negedge SCL);
        start=0;
        repeat (8) @(posedge SCL);
        SDA_tb_en = 1;
        SDA_tb = 0;
        @(negedge SCL);
        slave_data=tx_data;
        repeat(9) begin
            SDA_tb_en=1;
            @(posedge SCL);
            SDA_tb=slave_data[7];
            slave_data={slave_data[6:0],1'b0};
        end 
        //read done
        SDA_tb_en = 0;
        SDA_tb = 0;
        ack=0;
        @(negedge SCL);
        SDA_tb_en = 0;
        @(negedge SCL);
        ////////
        $display("test done all working"); // ^_^
        $stop;
    end
endmodule //I2C_master_tb