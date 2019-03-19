module ForwardUnit(input [4:0] ID_EX_Rs1, input [4:0] ID_EX_Rs2, input [4:0] EX_MEM_Rd, input [4:0] MEM_WB_RegRd, input EX_MEM_RegWrite, input MEM_WB_RegWrite, output reg [1:0] forwardA, output reg [1:0] forwardB);
    always @(*) begin
        forwardA = 2'b00;
        forwardB = 2'b00;
        
        //EX hazard
        if (EX_MEM_RegWrite && (EX_MEM_Rd != 0)&& (EX_MEM_Rd == ID_EX_Rs1))
            forwardA = 2'b10;
        if (EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == ID_EX_Rs2))
            forwardB = 2'b10;
            
        //MEM hazard    
        if ((MEM_WB_RegWrite && (MEM_WB_RegRd != 0) && (MEM_WB_RegRd == ID_EX_Rs1)) && !(EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == ID_EX_Rs1)))
            forwardA = 2'b01;
        if ((MEM_WB_RegWrite && (MEM_WB_RegRd != 0) && (MEM_WB_RegRd == ID_EX_Rs2)) && !(EX_MEM_RegWrite && (EX_MEM_Rd != 0) && (EX_MEM_Rd == ID_EX_Rs2)))
            forwardB = 2'b01;
    end
endmodule