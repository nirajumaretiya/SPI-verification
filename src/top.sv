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

        
    end



    
