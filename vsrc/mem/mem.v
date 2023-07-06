`include "common.vh"
module mem(
    // input              clk,                          // 时钟
    
    input      [ 31:0] dm_rdata_i,                      // 访存读数据
    output     [ 31:0] dm_addr_o,                       // 访存读写地址
    output reg [  3:0] dm_wbe_n_o,                      // 访存写使能
    output reg [ 31:0] dm_wdata_o,                      // 访存写数据
    output     dm_rw_o,                                 // 选择读(1)写(0) 

    input      [`EX2MEMBusSize - 1:0] ex2mem_bus_ri,    // EXE->MEM总线
    output     [`MEM2WBBusSize - 1:0] mem2wb_bus_o,     // MEM->WB总线

    input                       ctl_mem_valid_i,
    output                      ctl_mem_over_o,
    output [`RegAddrBusW-1:0]   ctl_mem_dest_o
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
    wire [4:0] rf_wdest;  //写回的目的寄存器
    wire       rf_wen;    //写回的寄存器写使能
    
    
    //pc
    wire [`RegW - 1:0] pc;

    assign {
        mem_control,
        store_data,
        exe_result,
        rf_wdest,
        rf_wen,
        pc 
    } = ex2mem_bus_ri;  

    /*==================================================*/
    //                 load/store访存
    /*==================================================*/

    wire        inst_load;      // load操作
    wire        inst_store;     // store操作
    wire        ld_bh_sign;     // load一字节为有符号load
    wire [2:0]  ld_st_size;     // load/store为 4:byte;2:halfword;1:word

    assign {inst_load,inst_store,ld_bh_sign,ld_st_size} = mem_control;

    // 选择读写
    assign dm_rw_o = inst_load & !inst_store;
    // 访存读写地址
    assign dm_addr_o = exe_result;
    
    // store操作的写使能
    always @ (*)
    begin
        if (ctl_mem_valid_i && inst_store) // 访存级有效时,才可以进行 store 操作
        begin
            case (ld_st_size)
                3'b100  : dm_wbe_n_o = 4'b1110;
                3'b010  : dm_wbe_n_o = 4'b1100;
                3'b001  : dm_wbe_n_o = 4'b0000; 
                default : dm_wbe_n_o = 4'b1111;
            endcase
        end
        else
        begin
            dm_wbe_n_o = 4'b1111;
        end
    end 
    
    //store操作的写数据
    always @ (*)
    begin
        dm_wdata_o = store_data;
    end
    
    // load读出的数据
    wire        load_sign;
    wire [31:0] load_result;
    assign load_sign =  (ld_st_size == 3'd4 ) ? dm_rdata_i[ 7] :
                        (ld_st_size == 3'd2 ) ? dm_rdata_i[15] : dm_rdata_i[31] ;

    assign load_result =    (ld_st_size == 3'd4 ) ? {{24{ld_bh_sign & load_sign}}, dm_rdata_i[7:0]}  :
                            (ld_st_size == 3'd2 ) ? {{16{ld_bh_sign & load_sign}}, dm_rdata_i[15:0]} :
                            dm_rdata_i[31:0];


    /*==================================================*/
    //              下级所需数据/总线生成
    /*==================================================*/
    wire [31:0] mem_result; //MEM传到WB的result为load结果或EXE结果
    assign mem_result = inst_load ? load_result : exe_result;
    
    assign mem2wb_bus_o = {
        rf_wdest,rf_wen,    // WB需要使用的信号
        mem_result,         // 最终要写回寄存器的数据
        pc                  // PC值
    };                               

    /*==================================================*/
    //                控制信号与冒险处理
    /*==================================================*/
    assign ctl_mem_dest_o = rf_wdest & {5{ctl_mem_valid_i}};

    assign ctl_mem_over_o = ctl_mem_valid_i;

endmodule

