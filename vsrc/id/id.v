`include "common.vh"

module id(
    input [`IF2IDBusSize - 1:0] if2id_bus_ri,
    // input [`RegW-1:0] if_id_pc_i,
    // input [`RegW-1:0] if_id_pcnow_i,
    // input [`RegW-1:0] if_id_inst_i,

    input [`RegW-1:0] rj_data_i,
    input [`RegW-1:0] rk_data_i,
    output [`RegAddrBusW-1:0] rj_addr_o,
    output [`RegAddrBusW-1:0] rk_addr_o,
    
    // return to IF for jump
    output [32:0] jbr_bus_o,

    // 数据竞争处理
    input [`RegAddrBusW-1:0] ctl_wb_dest_i,
    input [`RegAddrBusW-1:0] ctl_mem_dest_i,
    input [`RegAddrBusW-1:0] ctl_ex_dest_i,
    input [`RegW-1:0]        ctl_ex_pc_i ,
    input [`RegW-1:0]        ctl_mem_pc_i,
    input [`RegW-1:0]        ctl_wb_pc_i ,

    // 前递信号
    input [`RegW-1:0] forward_ex2id_data_i ,
    input [`RegW-1:0] forward_mem2id_data_i,
    input [`RegW-1:0] forward_wb2id_data_i ,
    input forward_ex2id_valid_i,

    // 控制信号
    input ctl_if_over_i,
    input ctl_id_valid_i,
    output ctl_id_over_o,
    output [`ID2EXBusSize - 1:0] id2ex_bus_o

);
    // 从 IF 获取 PC+4 和 instruction
    `NO_TOUCH wire [31:0] pc;
    `NO_TOUCH wire [31:0] inst;
    assign {pc, inst} = if2id_bus_ri;
    // assign pc = if_id_pcnow_i;
    // assign inst = if_id_inst_i;

    // get the default rd address
    wire [4:0] rd_addr;
    assign rd_addr = inst[4:0];
    

    /*==================================================*/
    //                   指令格式定义
    /*==================================================*/

    /*================================*/
    //       OPCODE.length == 6
    /*================================*/
    // JIRL B BL BEQ BNE BLT BGE BLTU BGEU
    
    // la32r_i26 
    wire [5:0] _i26_op;
    wire [15:0] _i26_i26_lo;
    wire [9:0] _i26_i26_hi;

    assign {_i26_op, _i26_i26_lo, _i26_i26_hi} = inst;

    // la32r_1ri21
    // 好像 la32r 没有
    wire [5:0] _1ri21_op;
    wire [15:0] _1ri21_i21_lo;
    wire [4:0] _1ri21_rj;
    wire [4:0] _1ri21_i21_hi;

    assign {_1ri21_op, _1ri21_i21_lo, _1ri21_rj, _1ri21_i21_hi} = inst;

    // la32r_2ri16
    wire [5:0] _2ri16_op;
    wire [15:0] _2ri16_i16;
    wire [4:0] _2ri16_rj;
    wire [4:0] _2ri16_rd;

    assign {_2ri16_op, _2ri16_i16, _2ri16_rj, _2ri16_rd} = inst;

    /*================================*/
    //       OPCODE.length == 7
    /*================================*/
    // LU12I.W & PCADDU12I

    // la32r_1rsi20
    wire [6:0] _1rsi20_op;
    wire [19:0] _1rsi20_si20;
    wire [4:0] _1rsi20_rd;

    assign {_1rsi20_op, _1rsi20_si20, _1rsi20_rd} = inst;

    /*================================*/
    //       OPCODE.length == 8
    /*================================*/

    // la32r_2ri14
    wire [7:0] _2ri14_op;
    wire [13:0] _2ri14_i14;
    wire [4:0] _2ri14_rj;
    wire [4:0] _2ri14_rd;

    assign {_2ri14_op, _2ri14_i14, _2ri14_rj, _2ri14_rd} = inst;

    /*================================*/
    //       OPCODE.length == 10
    /*================================*/

    // la32r_2ri12
    wire [9:0] _2ri12_op;
    wire [11:0] _2ri12_i12;
    wire [4:0] _2ri12_rj;
    wire [4:0] _2ri12_rd;

    assign {_2ri12_op, _2ri12_i12, _2ri12_rj, _2ri12_rd} = inst;

    /*================================*/
    //       OPCODE.length == 12
    /*================================*/
    /*================================*/
    //       OPCODE.length == 14
    /*================================*/

    // 好像 la32r 没有

    /*================================*/
    //       OPCODE.length == 17
    /*================================*/

    // la32r_3r
    wire [16:0] _3r_op;
    wire [4:0] _3r_rk;
    wire [4:0] _3r_rj;
    wire [4:0] _3r_rd;

    assign {_3r_op, _3r_rk, _3r_rj, _3r_rd} = inst;

    /*================================*/
    //       OPCODE.length == 22
    /*================================*/

    // la32r_2r
    wire [21:0] _2r_op;
    wire [4:0] _2r_rj;
    wire [4:0] _2r_rd;

    assign {_2r_op, _2r_rj, _2r_rd} = inst;
    

    /*==================================================*/
    //                 指令列表与解析
    /*==================================================*/
    // OPCODE.length == 22
    // wire inst_RDTIMEL_W, inst_RDTIMEH_W, inst_TLBSRCH;
    // wire inst_TLBRD, inst_TLBWR, inst_TLBFILL, inst_ERTN;
    // OPCODE.length == 17
    wire inst_ADD_W, inst_SUB_W, inst_SLT, inst_SLTU;
    wire inst_NOR, inst_AND, inst_OR, inst_XOR;
    wire inst_SLL_W, inst_SRL_W, inst_SRA_W, inst_MUL_W;
    // wire inst_MULH_W, inst_MULH_WU, inst_DIV_W, inst_MOD_W;
    // wire inst_DIV_WU, inst_MOD_WU, inst_BREAK, inst_SYSCALL;
    wire inst_SLLI_W, inst_SRLI_W, inst_SRAI_W;
    // wire inst_IDLE, inst_INVTLB, inst_DBAR, inst_IBAR;
    // OPCODE.length == 10
    wire inst_SLTI, inst_SLTUI, inst_ADDI_W, inst_ANDI;
    wire inst_ORI, inst_XORI, inst_LD_B;
    wire inst_LD_H, inst_LD_W, inst_ST_B, inst_ST_H;
    wire inst_ST_W, inst_LD_BU, inst_LD_HU;
    // wire inst_CACOP, inst_PRELD;
    // OPCODE.length == 8
    // wire inst_CSR, inst_LL_W, inst_SC_W;
    // OPCODE.length == 7
    wire inst_LU12I_W, inst_PCADDU12I;
    // OPCODE.length == 6
    wire inst_JIRL, inst_B, inst_BL, inst_BEQ;
    wire inst_BNE, inst_BLT, inst_BGE, inst_BLTU, inst_BGEU;

    /******* 临时若干个 *******/
    /* 
        st.w            [x]
        ld.w            [x]
        pcaddu12i       [x]
        addi.w          [x]
        add.w           [x]
        SLT             [x]
        SRL_W           [x]
        or(move)        [x]    
        b               
        bne             
        bl              
        BLTU            
        jirl            
     */

    assign inst_ADD_W   = (_3r_op == `INST_ADD_W);
    assign inst_SUB_W   = (_3r_op == `INST_SUB_W);
    assign inst_SLT     = (_3r_op == `INST_SLT);
    assign inst_SLTU    = (_3r_op == `INST_SLTU);
    assign inst_NOR     = (_3r_op == `INST_NOR);
    assign inst_AND     = (_3r_op == `INST_AND);
    assign inst_OR      = (_3r_op == `INST_OR);
    assign inst_XOR     = (_3r_op == `INST_XOR);
    assign inst_SLL_W   = (_3r_op == `INST_SLL_W);
    assign inst_SRL_W   = (_3r_op == `INST_SRL_W);
    assign inst_SRA_W   = (_3r_op == `INST_SRA_W);
    assign inst_MUL_W   = (_3r_op == `INST_MUL_W);
    assign inst_SLLI_W  = (_3r_op == `INST_SLLI_W);
    assign inst_SRLI_W  = (_3r_op == `INST_SRLI_W);
    assign inst_SRAI_W  = (_3r_op == `INST_SRAI_W);

    assign inst_SLTI    = (_2ri12_op == `INST_SLTI);
    assign inst_SLTUI   = (_2ri12_op == `INST_SLTUI);
    assign inst_ADDI_W  = (_2ri12_op == `INST_ADDI_W);
    assign inst_ANDI    = (_2ri12_op == `INST_ANDI);
    assign inst_ORI     = (_2ri12_op == `INST_ORI);
    assign inst_XORI    = (_2ri12_op == `INST_XORI);
    assign inst_LD_B    = (_2ri12_op == `INST_LD_B);
    assign inst_LD_H    = (_2ri12_op == `INST_LD_H);
    assign inst_LD_W    = (_2ri12_op == `INST_LD_W);
    assign inst_ST_B    = (_2ri12_op == `INST_ST_B);
    assign inst_ST_H    = (_2ri12_op == `INST_ST_H);
    assign inst_ST_W    = (_2ri12_op == `INST_ST_W);
    assign inst_LD_BU   = (_2ri12_op == `INST_LD_BU);
    assign inst_LD_HU   = (_2ri12_op == `INST_LD_HU);

    assign inst_LU12I_W   = (_1rsi20_op == `INST_LU12I_W);
    assign inst_PCADDU12I = (_1rsi20_op == `INST_PCADDU12I);

    assign inst_JIRL    = (_i26_op == `INST_JIRL);
    assign inst_B       = (_i26_op == `INST_B);
    assign inst_BL      = (_i26_op == `INST_BL);
    assign inst_BEQ     = (_i26_op == `INST_BEQ);
    assign inst_BNE     = (_i26_op == `INST_BNE);
    assign inst_BLT     = (_i26_op == `INST_BLT);
    assign inst_BGE     = (_i26_op == `INST_BGE);
    assign inst_BLTU    = (_i26_op == `INST_BLTU);
    assign inst_BGEU    = (_i26_op == `INST_BGEU);


    /*==================================================*/
    //                    译码装配
    /*==================================================*/
    //跳转分支指令
    wire inst_jr;    // 跳转不用+PC
    wire inst_j_link;// 需要写回 PC + 4
    wire inst_jbr;   // 所有分支跳转指令
    assign inst_jr     = inst_JIRL;
    assign inst_j_link = inst_BL | inst_JIRL;
    assign inst_jbr = inst_JIRL | inst_B    | inst_BL 
                    | inst_BEQ  | inst_BNE  | inst_BLT
                    | inst_BGE  | inst_BLTU | inst_BGEU;
                    
        
    //load store
    wire inst_load;
    wire inst_store;
    // load指令
    assign inst_load = inst_LD_B | inst_LD_H | inst_LD_W | inst_LD_BU | inst_LD_HU;
    // store指令
    assign inst_store = inst_ST_B | inst_ST_H | inst_ST_W;             
    
    // alu操作分类
    wire inst_add, inst_sub, inst_slt,inst_sltu;
    wire inst_and, inst_nor, inst_or, inst_xor;
    wire inst_sll, inst_srl, inst_sra,inst_lui;
    assign inst_add = inst_ADD_W | inst_ADDI_W | inst_load
                    | inst_store | inst_j_link | inst_PCADDU12I;    // 加法
    assign inst_sub = inst_SUB_W;                                   // 减法
    assign inst_slt = inst_SLT | inst_SLTI;                         // 有符号小于置位
    assign inst_sltu= inst_SLTU | inst_SLTUI;                       // 无符号小于置位
    assign inst_and = inst_AND | inst_ANDI;                         // 逻辑与
    assign inst_nor = inst_NOR;                                     // 逻辑或非
    assign inst_or  = inst_OR  | inst_ORI;                          // 逻辑或
    assign inst_xor = inst_XOR | inst_XORI;                         // 逻辑异或
    assign inst_sll = inst_SLL_W | inst_SLLI_W;                     // 逻辑左移
    assign inst_srl = inst_SRL_W | inst_SRLI_W;                     // 逻辑右移
    assign inst_sra = inst_SRA_W | inst_SRAI_W;                     // 算术右移
    assign inst_lui = inst_LU12I_W;                                 // 立即数装载高位

    // 立即数移位
    wire inst_shf_imm;
    assign inst_shf_imm =  inst_SLLI_W | inst_SRLI_W | inst_SRAI_W;
    
    // 依据立即数扩展方式分类
    wire inst_imm_zero;   //立即数0扩展
    wire inst_imm_sign12; //12位立即数符号扩展
    wire inst_imm_sign20; //20位立即数符号扩展
    assign inst_imm_zero = inst_ANDI | inst_ORI | inst_XORI;
    assign inst_imm_sign12 = inst_ADDI_W | inst_SLTI | inst_SLTUI
                        | inst_load | inst_store;
    assign inst_imm_sign20 = inst_PCADDU12I | inst_LU12I_W;
    
    // 依据目的寄存器号分类
    wire inst_wdest_r1;     // 寄存器堆写入地址为 1的指令
    wire inst_wdest_none;   // 不写寄存器堆的指令
    assign inst_wdest_r1 = inst_BL;
    assign inst_wdest_none = inst_B | inst_BEQ | inst_BNE 
                    | inst_BLT | inst_BGE | inst_BLTU | inst_BGEU | inst_store;

    // 依据源寄存器号分类
    wire inst_no_rj;  // rj 域非0，且不是从寄存器堆读 rj的指令
    wire inst_no_rk;  // rk 域非0，且不是从寄存器堆读 rk 的指令 ( store 指令依赖 rd, 但之后取到 rk )
    assign inst_no_rj = inst_LU12I_W | inst_PCADDU12I | inst_B | inst_BL;
    assign inst_no_rk = inst_SLLI_W | inst_SRLI_W | inst_SRAI_W
                        | inst_SLTI | inst_SLTUI | inst_ADDI_W
                        | inst_ANDI | inst_ORI  | inst_XOR
                        | inst_B | inst_BL | inst_load  /*| inst_store */
                        | inst_LU12I_W | inst_PCADDU12I;

    /*==================================================*/
    //                    取寄存器值
    /*==================================================*/

    // rk: [14:10]   rj: [9:5]    rd: [4:0]
    // 如果是 inst_BEQ | inst_BNE | inst_BLT | inst_BGE | inst_BLTU | inst_BGEU
    //      | inst_store
    // 1. [rj] 和 [rd] 比较
    // 2. 取 [rd] 数存入 [rj] + offset
    // 这里直接用 [rd] 取代 [rk]
    wire inst_rk2rd = inst_BEQ | inst_BNE | inst_BLT | inst_BGE | inst_BLTU | inst_BGEU | inst_store;
    assign rj_addr_o = inst[9:5];
    assign rk_addr_o = inst_rk2rd ? inst[4:0] : inst[14:10];

    /*==================================================*/
    //                控制信号与冒险处理
    /*==================================================*/

    `NO_TOUCH wire rj_hazard;
    `NO_TOUCH wire rk_hazard;
    wire ex_pc_not_same, mem_pc_not_same, wb_pc_not_same;
    wire ex_rj_same, mem_rj_same, wb_rj_same;
    wire ex_rk_same, mem_rk_same, wb_rk_same;
    wire rj_zero, rk_zero; 
    wire [`RegW - 1:0] rj_data;
    wire [`RegW - 1:0] rk_data;

    assign ex_pc_not_same   = !(pc[21:0] == ctl_ex_pc_i[21:0] );
    assign mem_pc_not_same  = !(pc[21:0] == ctl_mem_pc_i[21:0]);

    assign wb_pc_not_same   = !(pc[21:0] == ctl_wb_pc_i[21:0] );

    assign ex_rj_same   = ex_pc_not_same    & (ctl_ex_dest_i == rj_addr_o);
    assign mem_rj_same = mem_pc_not_same  & (ctl_mem_dest_i == rj_addr_o);

    assign wb_rj_same   = wb_pc_not_same    & (ctl_wb_dest_i == rj_addr_o);

    assign ex_rk_same   = ex_pc_not_same    & (ctl_ex_dest_i == rk_addr_o);
    assign mem_rk_same = mem_pc_not_same  & (ctl_mem_dest_i == rk_addr_o);
    assign wb_rk_same   = wb_pc_not_same    & (ctl_wb_dest_i == rk_addr_o);
    
    assign rj_zero = (rj_addr_o == 5'd0);
    assign rk_zero = (rk_addr_o == 5'd0);


    assign rj_hazard = ~inst_no_rj 
                    & ~rj_zero
                    & ((~forward_ex2id_valid_i & ex_rj_same) /*| mem2_rj_same | wb_rj_same*/);
    assign rk_hazard = ~inst_no_rk 
                    & ~rk_zero
                    & ((~forward_ex2id_valid_i & ex_rk_same) /*| mem2_rk_same | wb_rk_same*/);
    
    // ID 级有效 & rj 无数据冒险 & rk 无数据冒险 & （不是跳转指令 | (是跳转指令 & IF 已执行完毕可以取下一条)）
    assign ctl_id_over_o = ctl_id_valid_i & ~rj_hazard & ~rk_hazard & (~inst_jbr | ctl_if_over_i);

    // 数据多路选择
    assign rj_data = rj_zero ? 32'd0 
                        : forward_ex2id_valid_i & ex_rj_same ? forward_ex2id_data_i
                        : mem_rj_same ? forward_mem2id_data_i
                        : wb_rj_same ? forward_wb2id_data_i : rj_data_i;

    assign rk_data = rk_zero ? 32'd0 
                        : forward_ex2id_valid_i & ex_rk_same ? forward_ex2id_data_i
                        : mem_rk_same ? forward_mem2id_data_i
                        : wb_rk_same ? forward_wb2id_data_i : rk_data_i;


    /*==================================================*/
    //                     跳转处理
    /*==================================================*/

    // 无条件跳转
    wire        j_taken;
    wire [31:0] j_target;
    assign j_taken = inst_JIRL | inst_B | inst_BL ;
    // inst_JIRL 跳转地址为 {{14{_2ri16_i16[15]}}, _2ri16_i16, 2'b00}
    // inst_B | inst_BL 跳转为 { {4{_i26_i26_hi[9]}} , {_i26_i26_hi, _i26_i26_lo} ,2'b00}
    assign j_target = inst_jr ? {{14{_2ri16_i16[15]}}, _2ri16_i16, 2'b00} + rj_data
                                : pc + { {4{_i26_i26_hi[9]}} , {_i26_i26_hi, _i26_i26_lo} ,2'b00};


    // 有条件跳转
    wire rj_eq_rk;
    wire rj_sl_rk, rj_l_rk;
    assign rj_eq_rk = (rj_data == rk_data);     // GPR[rs]==GPR[rt]

    assign rj_sl_rk = ($signed(rj_data) < $signed(rk_data));  // 有符号比较大小
    assign rj_l_rk  = (rj_data < rk_data);       // 无符号比较大小
    wire br_taken;
    wire [31:0] br_target;
    assign br_taken = inst_BEQ  & rj_eq_rk          // 相等跳转
                    | inst_BNE  & ~rj_eq_rk         // 不等跳转
                    | inst_BLT  & rj_sl_rk          // s[rj] < s[rk]
                    | inst_BGE  & ~rj_sl_rk         // s[rj] >= s[rk]
                    | inst_BLTU & rj_l_rk           // 小于等于0跳转
                    | inst_BGEU & ~rj_l_rk;         // 小于0跳转
    // 分支跳转目标地址：PC=PC+offset<<2
    assign br_target = pc + {{14{_2ri16_i16[15]}}, _2ri16_i16, 2'b00};
    
    // jump and branch指令
    `NO_TOUCH wire jbr_taken;
    `NO_TOUCH wire [31:0] jbr_target;
    assign jbr_taken  = (j_taken | br_taken) & ctl_id_over_o; // 要求应当计算完毕，若出现数据竞争，则会回退
    assign jbr_target = j_taken ? j_target : br_target;
    
    // ID到IF的跳转总线
    assign jbr_bus_o = {jbr_taken, jbr_target};

    /*==================================================*/
    //              下级所需数据/总线生成
    /*==================================================*/
    wire id_multiply;
    wire [`AluOpW - 1:0] id_aluop;
    `NO_TOUCH wire [`RegW - 1:0] id_rj;
    `NO_TOUCH wire [`RegW - 1:0] id_rk;
    wire [5:0] id_mem_ctl;
    wire [`RegW - 1:0] id_mem_st_data;
    wire [`RegAddrBusW-1:0] id_wb_rd_addr;
    wire id_wb_rd_we;
    
    // EXE 需要的数据
    // 是否进行乘法
    assign id_multiply = inst_MUL_W;
    
    // alu 操作类型
    assign id_aluop = {
        inst_add,
        inst_sub,
        inst_slt,
        inst_sltu,
        inst_and,
        inst_nor,
        inst_or,
        inst_xor,
        inst_sll,
        inst_srl,
        inst_sra,
        inst_lui
    };
    // 操作数 1
    assign id_rj = inst_j_link ? pc : 
                    /* inst_LU12I_W ? 32'd0 : */
                    inst_PCADDU12I ? pc : rj_data;
    // 操作数 2
    assign id_rk = inst_j_link ? 32'd4 :
                    inst_imm_zero? {20'd0, _2ri12_i12} :
                    inst_imm_sign12? {{20{_2ri12_i12[11]}}, _2ri12_i12} :
                    inst_imm_sign20? {_1rsi20_si20, 12'b0} :
                    inst_shf_imm? {27'd0, _3r_rk} : rk_data; // 对于 LU12i 之后直接取 rk 作为输出， 
                                                                        // 对于 PCADDU12I 则需 将 rj(pc) + rk 作为输出

    // MEM 需要的数据
    wire ld_bh_sign;        // load一字节为有符号load
    wire [2:0] ld_st_size;  // load/store为 4:byte;2:halfword;4:word
    assign ld_bh_sign = inst_LD_B | inst_LD_H;
    assign ld_st_size = {
        inst_LD_B | inst_LD_BU | inst_ST_B,
        inst_LD_H | inst_LD_HU | inst_ST_H,
        inst_LD_W | inst_ST_W
    }; 
    assign id_mem_ctl = {
        inst_load,
        inst_store,
        ld_bh_sign,
        ld_st_size
    };
    assign id_mem_st_data = rk_data;

    // WB 需要的数据
    // 写回的寄存器写使能
    assign id_wb_rd_we = ~(|inst_wdest_none);
    // 写回的目的寄存器
    assign id_wb_rd_addr = inst_wdest_none ? 5'd0 :
                        inst_wdest_r1 ? 5'd1 : rd_addr;

    assign id2ex_bus_o = {id_multiply, id_aluop, id_rj, id_rk, id_mem_ctl, id_mem_st_data, id_wb_rd_addr, id_wb_rd_we, pc};


    /**
      *            Wait for implementing
      * 
        
        INST_MUL_W     17'b111000                   [*]
        INST_MULH_W    17'b111001                   [*]
        INST_MULH_WU   17'b111010                   [*]
        INST_DIV_W     17'b1000000                  [*]
        INST_MOD_W     17'b1000001                  [*]
        INST_DIV_WU    17'b1000010                  [*]
        INST_MOD_WU    17'b1000011                  [*]

        INST_BREAK     17'b1010100
        INST_SYSCALL   17'b1010110
        INST_IDLE      17'b110010010001
        INST_INVTLB    17'b110010010011
        INST_DBAR      17'b111000011100100
        INST_IBAR      17'b111000011100101

        INST_CACOP     10'b11000                    [*]
        INST_PRELD     10'b10101011                 [?]

        INST_CSR       8'b100
        INST_LL_W      8'b100000
        INST_SC_W      8'b100001
    */


endmodule
