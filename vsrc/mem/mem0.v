`include "common.vh"
module mem0(
    // input              clk,                          // 时钟
    
    // input      [ 31:0] dm_rdata_i,                      // 访存读数据
    output     [ 31:0] dm_addr_o,                       // 访存读写地址
    output reg [  3:0] dm_be_n_o,                      // 访存写使能
    output reg [ 31:0] dm_wdata_o,                      // 访存写数据
    output     dm_re_o,                                 // 选择读(1)写(0) 
    output     dm_we_o,

    input      [`EX2MEM0BusSize - 1:0] ex2mem0_bus_ri,    // EXE->MEM总线
    output     [`MEM02MEM1BusSize - 1:0] mem02mem1_bus_o,     // MEM->WB总线

    input                       ctl_mem0_valid_i,
    output                      ctl_mem0_over_o,
    output [`RegAddrBusW-1:0]   ctl_mem0_dest_o,
    output [`RegW - 1: 0]       ctl_mem0_pc_o
);
    /*==================================================*/
    //                 级间寄存器信号解析
    /*==================================================*/
    //访存需要用到的load/store信息
    wire [5 :0] mem_control;  //MEM需要使用的控制信号
    wire [`RegW - 1:0] store_data;   //store操作的存的数据
    
    //EXE结果
    wire [`RegW - 1:0] exe_result;
    
    //写回需要用到的信息
    wire [4:0] wb_wdest;  //写回的目的寄存器
    wire       wb_we;    //写回的寄存器写使能
    
    
    //pc
    `NO_TOUCH wire [`RegW - 1:0] pc;

    assign {
        mem_control,
        store_data,
        exe_result,
        wb_wdest,
        wb_we,
        pc 
    } = ex2mem0_bus_ri;  

    /*==================================================*/
    //                 load/store访存
    /*==================================================*/
    /*
        TODO: 
        自然对齐是指,访问半字对象时地址是 2 字节边界对齐,
        访问字对象时地址是 4 字节边界对齐,访问双字对象时地址是 8 字节边界对齐...
    */

    wire        inst_load;      // load操作
    wire        inst_store;     // store操作
    wire        ld_bh_sign;     // load一字节为有符号load
    wire [2:0]  ld_st_size;     // load/store为 4:byte;2:halfword;1:word

    assign {inst_load,inst_store,ld_bh_sign,ld_st_size} = mem_control;

    // 选择读写
    assign dm_re_o = inst_load;
    assign dm_we_o = inst_store;
    // 访存读写地址
    assign dm_addr_o = exe_result;
    
    // load/store操作的读写操作掩码
    always @ (*)
    begin
        if (ctl_mem0_valid_i && (inst_store || inst_load)) // 访存级有效时,才可以进行 load/store 操作
        begin
            case (ld_st_size )
                3'b100  : begin
                    case(exe_result[1:0])
                        2'b00: dm_be_n_o = 4'b1110;
                        2'b01: dm_be_n_o = 4'b1101;
                        2'b10: dm_be_n_o = 4'b1011;
                        2'b11: dm_be_n_o = 4'b0111;
                    endcase
                end
                3'b010  : begin
                    case(exe_result[1])
                        1'b0: dm_be_n_o = 4'b1100;
                        1'b1: dm_be_n_o = 4'b0011;
                    endcase
                end
                3'b001  : dm_be_n_o = 4'b0000; 
                default : dm_be_n_o = 4'b1111;
            endcase
        end
        else
        begin
            dm_be_n_o = 4'b1111;
        end
    end 
    
    //store操作的写数据
    always @ (*)
    begin
        dm_wdata_o = store_data;
    end
    

    /*==================================================*/
    //              下级所需数据/总线生成
    /*==================================================*/
    
    assign mem02mem1_bus_o = {
        mem_control,
        exe_result,
        wb_wdest,
        wb_we,
        pc
    };                               

    /*==================================================*/
    //                控制信号与冒险处理
    /*==================================================*/
    assign ctl_mem0_dest_o = wb_wdest & {5{ctl_mem0_valid_i}};

    assign ctl_mem0_over_o = ctl_mem0_valid_i;

    assign ctl_mem0_pc_o = pc;

endmodule

