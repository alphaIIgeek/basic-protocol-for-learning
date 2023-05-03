`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/04/28 15:05:17
// Design Name: 
// Module Name: iic_rt
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


module iic_rt(
input wire clk,
input wire valid,//����һ�����ڣ���������
output reg ready=1,//�Ƿ�׼��������/�������(�ߵ�ƽʱread��ok��Ч)
input wire[7:0] write,
output reg[7:0] read=0,
output reg ok=0,//�ôβ����Ƿ�ɹ� 0ʧ�� 1�ɹ�
input wire RW,//����:0д/1��
input wire[1:0] SP,//�Ƿ�ִ����ʼ��ֹͣ��MSB1ִ����ʼ LSB1ִ��ֹͣ

inout wire SDA,
output reg SCL=1
    );
localparam IDLE  = 5'b0_0001;
localparam START = 5'b0_0010;
localparam DATA  = 5'b0_0100;
localparam ACK   = 5'b0_1000;
localparam STOP  = 5'b1_0000;    
reg[5:0] state = IDLE;//IIC״̬��

localparam LEVEL0 = 5'b0_0001;
localparam LEVEL1 = 5'b0_0010;
localparam LEVEL2 = 5'b0_0100;
localparam LEVEL3 = 5'b0_1000;
localparam LEVEL4 = 5'b1_0000;
reg[4:0] level=LEVEL0;//����״̬��ƽ����

reg[7:0] byte=0;
reg rw=0;
reg[1:0] sp=0;
reg io=0;//0д1��
reg sda=1;
assign SDA = (io==0)? sda:1'bz;//inout����

reg[7:0] bit=8'b0000_0001;  
  
always@(posedge clk)begin
    case(state)
        IDLE:   begin
                    if(valid) begin
                        byte<=write;
                        rw<=RW;
                        sp<=SP;//��ȡvalid�ߵ�ƽ����
                        ready<=0;
                        state<=(SP[1])? START:DATA;
                    end
                    else begin
                        ready<=1;
                        state<=IDLE;
                    end
                end
        START:  begin
                    case(level)
                        LEVEL0: begin
                                    io<=0;
                                    sda<=1;
                                    level<=LEVEL1;
                                end
                        LEVEL1: begin
                                    SCL<=1;
                                    level<=LEVEL2;
                                end        
                        LEVEL2: begin
                                    sda<=0;
                                    level<=LEVEL3;
                                end      
                        LEVEL3: begin
                                    level<=LEVEL4;
                                end   
                        LEVEL4: begin
                                    SCL<=0;
                                    level<=LEVEL0;//��λ
                                    state<=DATA;
                                end         
                    endcase
                end
        DATA:  begin
                    if(rw==0) begin//д����
                        case(level)
                            LEVEL0: begin
                                        SCL<=0;
                                        level<=LEVEL1;
                                    end
                            LEVEL1: begin
                                        io<=0;
                                        sda<=byte[7];
                                        level<=LEVEL2;
                                    end
                            LEVEL2: begin
                                        SCL<=1;
                                        level<=LEVEL3;
                                    end
                            LEVEL3: begin
                                        
                                        level<=LEVEL4;
                                    end
                            LEVEL4: begin
                                        SCL<=0;
                                        byte<=byte<<1;
                                        bit<=(bit==8'b1000_0000)? 8'b0000_0001:bit<<1;
                                        level<=LEVEL0;
                                        state<=(bit==8'b1000_0000)? ACK:DATA;
                                    end                                                                                                            
                        endcase
                    end
                    else begin//������
                        case(level)
                            LEVEL0: begin
                                        SCL<=0;
                                        read<=read<<1;
                                        level<=LEVEL1;
                                    end
                            LEVEL1: begin
                                        io<=1;
                                        level<=LEVEL2;
                                    end
                            LEVEL2: begin
                                        SCL<=1;
                                        read[0]<=SDA;
                                        level<=LEVEL3;
                                    end
                            LEVEL3: begin
                                        level<=LEVEL4;
                                    end
                            LEVEL4: begin
                                        SCL<=0;
                                        bit<=(bit==8'b1000_0000)? 8'b0000_0001:bit<<1;
                                        state<=(bit==8'b1000_0000)? ACK:DATA;
                                        level<=LEVEL0;
                                    end                                                                                                            
                        endcase
                    end
                end
        ACK:    begin
                    if(rw==0) begin//д����
                        case(level)
                            LEVEL0: begin
                                        io<=1;//�ͷ�SDA
                                        level<=LEVEL1;
                                    end
                            LEVEL1: begin
                                        SCL<=1;
                                        level<=LEVEL2;
                                    end
                            LEVEL2: begin
                                        ok<=~SDA;
                                        level<=LEVEL3;
                                    end
                            LEVEL3: begin
                                        SCL<=0;
                                        level<=LEVEL4;
                                    end
                            LEVEL4: begin
                                        io<=0;
                                        level<=LEVEL0;
                                        state<=(sp[0]==0)? IDLE:STOP;
                                    end                                                                                                            
                        endcase
                    end
                    else begin//������
                        case(level)
                            LEVEL0: begin
                                        io<=0;
                                        sda<=sp[0];
                                        level<=LEVEL1;
                                    end
                            LEVEL1: begin
                                        SCL<=1;
                                        level<=LEVEL2;
                                    end
                            LEVEL2: begin
                                        ok<=1;
                                        level<=LEVEL3;
                                    end
                            LEVEL3: begin
                                        SCL<=0;
                                        level<=LEVEL4;
                                    end
                            LEVEL4: begin
                                        state<=(sp[0]==0)? IDLE:STOP;
                                        level<=LEVEL0;
                                    end                                                                                                            
                        endcase
                    end
                end
        STOP:   begin
                    case(level)
                        LEVEL0: begin
                                    sda<=0;
                                    level<=LEVEL1;
                                end
                        LEVEL1: begin
                                    SCL<=1;
                                    level<=LEVEL2;
                                end
                        LEVEL2: begin
                                    level<=LEVEL3;
                                end
                        LEVEL3: begin
                                    sda<=1;
                                    level<=LEVEL4;
                                end
                        LEVEL4: begin
                                    state<=IDLE;
                                    level<=LEVEL0;
                                end
                    endcase
                end
        default: state<=STOP;
    endcase
end
   
endmodule
