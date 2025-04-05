module spi_master(
    input clk,newd,rst,
    input [11:0] din,
    output reg sclk,mosi,cs
);

    typedef enum reg [1:0] {IDLE,ENABLE,SEND,COMP} state_t;
    state_t state=IDLE;

    int countc=0;
    int count=0;

    // Generation of clock
    always @(posedge clk) begin
        if(rst) begin
            countc<=0;
            sclk<=1'b0;
        end
        else begin
            if(countc<10) begin
                countc<=countc+1; 
            end
            else begin
                countc<=0;
                sclk<=~sclk;
            end
        end
    end

    reg [11:0] temp;
    always @(posedge clk) begin
        if(rst) begin
            mosi<=1'b0;
            cs<=1'b1;
        end
        else begin
            case(state)
                IDLE: begin
                    if(newd) begin
                        state<=SEND;
                        temp<=din;
                        cs<=1'b0;
                    end
                    else begin
                        state<=IDLE;
                        temp<=8'h00;
                    end

                SEND: begin
                    if(count<=11) begin
                        mosi<=temp[count];
                        count<=count+1;
                    end
                    else begin
                        count<=0;
                        state<=IDLE;
                        cs<=1'b1;
                        mosi<=1'b0;
                    end
                end

                default: begin
                    state<=IDLE;
                end
            endcase
        end
    end
endmodule


module spi_slave(
    input sclk,mosi,cs,
    output [11:0] dout,
    output reg done
);

    typedef enum bit {detect_start,read_data} state_t;
    state_t state=detect_start;
    
    reg [11:0] temp=12'h000;
    int count=0;

    always @(posedge sclk) begin
        case(state) 
            detect_start: begin
                if(cs==1'b0) begin
                    state<=read_data;
                end
                else begin
                    state<=detect_start;
                end
            end
            read_data: begin 
                if(count<=11) begin
                    count<=count+1;
                    temp= {mosi,temp[11:1]};
                end
                else begin
                    count<=0;
                    done<=1'b1;
                    state<=detect_start;
                end
            end
        endcase
    end
assign dout=temp;
endmodule

// synchronizing both the master and slave
module top(
    input clk,rst,newd,
    input [11:0] din,
   // output sclk,mosi,cs,
    output [11:0] dout,
    output done
);

wire sclk,mosi,cs;
spi_master u1(
    .clk(clk),
    .rst(rst),
    .newd(newd),
    .din(din),
    .sclk(sclk),
    .mosi(mosi),
    .cs(cs)
);

spi_slave u2(
    .sclk(sclk),
    .mosi(mosi),
    .cs(cs),
    .dout(dout),
    .done(done)
);

// interface
interface spi_if;
    logic clk,newd,rst,sclk,cs,mosi;
    logic [11:0] din,dout;
endinterface
    
