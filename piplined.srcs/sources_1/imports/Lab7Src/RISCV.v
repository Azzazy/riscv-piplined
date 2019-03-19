// file: RISCV.v
// author: @cherifsalama

`timescale 1ns/1ns

module RISCV (
    input clk, 
    input rst, 
    input [1:0] ledSel, 
    input [3:0] ssdSel,
    output reg [15:0] leds, 
    output reg [12:0] ssd
);

    wire [31:0] PC_out, PCAdder_out, BranchAdder_out, PC_in, 
        RegR1, RegR2, RegW, ImmGen_out, Shift_out, ALUSrcMux_out, 
        ALU_out, Mem_out, Inst, forwardA_out, forwardB_out;
    wire Branch, MemRead, MemToReg, MemWrite, ALUSrc, RegWrite, Zero;
    wire [1:0] ALUOp, forwardA, forwardB;
    wire [3:0] ALUSel;
    wire PCSrc;
    
    wire [31:0] IF_ID_PC, IF_ID_Inst, 
        ID_EX_PC, ID_EX_RegR1, ID_EX_RegR2, ID_EX_Imm, 
        EX_MEM_BranchAddOut, EX_MEM_ALU_out, EX_MEM_RegR2, 
        MEM_WB_Mem_out, MEM_WB_ALU_out;
    wire [7:0] ID_EX_Ctrl;
    wire [4:0] EX_MEM_Ctrl;
    wire [1:0] MEM_WB_Ctrl;
    wire [3:0] ID_EX_Func;
    wire [4:0] ID_EX_Rs1, ID_EX_Rs2, ID_EX_Rd, EX_MEM_Rd, MEM_WB_Rd;
    wire EX_MEM_Zero;

    RegWLoad PC(clk,rst,1'b1,PC_in,PC_out);
    RegWLoad #(64) IF_ID (clk,rst,1'b1,
                            {PC_out,Inst},
                            {IF_ID_PC,IF_ID_Inst}
                            );
    RegWLoad #(155) ID_EX (clk,rst,1'b1,
                            {RegWrite,MemToReg,Branch,MemRead,MemWrite,ALUOp,ALUSrc,
                                IF_ID_PC,RegR1,RegR2,ImmGen_out,
                                IF_ID_Inst[30],IF_ID_Inst[14:12],
                                IF_ID_Inst[19:15],IF_ID_Inst[24:20],IF_ID_Inst[11:7]},
                            {ID_EX_Ctrl,ID_EX_PC,ID_EX_RegR1,ID_EX_RegR2,ID_EX_Imm,
                                ID_EX_Func,ID_EX_Rs1,ID_EX_Rs2,ID_EX_Rd}
                            );
    RegWLoad #(107) EX_MEM (clk,rst,1'b1,
                            {ID_EX_Ctrl[7:3],
                                BranchAdder_out,Zero,ALU_out,
                                ID_EX_RegR2,ID_EX_Rd},
                            {EX_MEM_Ctrl,EX_MEM_BranchAddOut,EX_MEM_Zero,EX_MEM_ALU_out,
                                EX_MEM_RegR2, EX_MEM_Rd}
                            );
    RegWLoad #(71) MEM_WB (clk,rst,1'b1,
                            {EX_MEM_Ctrl[4:3],
                                Mem_out,EX_MEM_ALU_out,EX_MEM_Rd},
                            {MEM_WB_Ctrl,MEM_WB_Mem_out, MEM_WB_ALU_out, MEM_WB_Rd}
                            );

    InstMem imem(rst,PC_out[7:2],Inst);
    RippleAdder IncPC(PC_out,4,1'b0,PCAdder_out,);
    RegFile rf(~clk,rst,MEM_WB_Ctrl[1],IF_ID_Inst[19:15],IF_ID_Inst[24:20],MEM_WB_Rd,RegW,RegR1,RegR2);
    ImmGen ig(IF_ID_Inst,ImmGen_out);
    Mux2_1 #(32) aluSrcBMux(ID_EX_Ctrl[0],forwardB_out,ID_EX_Imm,ALUSrcMux_out);
    ALU a1(ALUSel,forwardA_out,ALUSrcMux_out,ALU_out,Zero);
    ShiftLeft1 sh(ID_EX_Imm,Shift_out);
    RippleAdder OffsetPC(ID_EX_PC,Shift_out,1'b0,BranchAdder_out,);
    Mux2_1 #(32) pcSrcMux(PCSrc,PCAdder_out,EX_MEM_BranchAddOut,PC_in);
    assign PCSrc = EX_MEM_Zero && EX_MEM_Ctrl[2];
    DataMem dmem(clk,rst,EX_MEM_Ctrl[1],EX_MEM_Ctrl[0],EX_MEM_ALU_out[7:2],EX_MEM_RegR2,Mem_out);
    Mux2_1 #(32) regWSrcMux(MEM_WB_Ctrl[0],MEM_WB_ALU_out,MEM_WB_Mem_out,RegW);
    ControlUnit cu(IF_ID_Inst[6:4],Branch,MemRead,MemToReg,ALUOp,MemWrite,ALUSrc,RegWrite);
    ALUControl acu(ID_EX_Ctrl[2:1],ID_EX_Func[2:0],ID_EX_Func[3],ALUSel);

    Mux4_1 #(32) forwardAMux(forwardA, ID_EX_RegR1, EX_MEM_ALU_out, RegW, 0, forwardA_out);
    Mux4_1 #(32) forwardBMux(forwardB, ID_EX_RegR2, EX_MEM_ALU_out, RegW, 0, forwardB_out);
    
    ForwardUnit forwardUnit(ID_EX_Rs1, ID_EX_Rs2, EX_MEM_Rd, MEM_WB_Rd, EX_MEM_Ctrl[4], MEM_WB_Ctrl[1], forwardA, forwardB);
    always @(*) begin
        case(ledSel)
            0: leds <= Inst[15:0];
            1: leds <= Inst[31:16];
            2: leds <= {Branch, MemRead, MemToReg, ALUOp, MemWrite, 
                        ALUSrc, RegWrite, Zero, PCSrc, ALUSel};
            default: leds <= 0;            
        endcase
        
        case(ssdSel)
            0: ssd <= PC_out[12:0];
            1: ssd <= PCAdder_out[12:0]; 
            2: ssd <= BranchAdder_out[12:0]; 
            3: ssd <= PC_in[12:0];
            4: ssd <= RegR1[12:0]; 
            5: ssd <= RegR2[12:0]; 
            6: ssd <= RegW[12:0]; 
            7: ssd <= ImmGen_out[12:0]; 
            8: ssd <= Shift_out[12:0]; 
            9: ssd <= ALUSrcMux_out[12:0]; 
            10: ssd <= ALU_out[12:0]; 
            11: ssd <= Mem_out[12:0];
            default: ssd <= 0;
        endcase
    end
endmodule

