// alu_decodes.svh
// Defining ALU control operations using an enumeration for scannability and clean design.
package alu_defines;
    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0000,
        ALU_SUB  = 4'b0001,
        ALU_SLL  = 4'b0010, // Shift Left Logical
        ALU_SLT  = 4'b0011, // Set Less Than (Signed)
        ALU_SLTU = 4'b0100, // Set Less Than Unsigned
        ALU_XOR  = 4'b0101,
        ALU_SRL  = 4'b0110, // Shift Right Logical
        ALU_SRA  = 4'b0111, // Shift Right Arithmetic
        ALU_OR   = 4'b1000,
        ALU_AND  = 4'b1001
    } alu_op_e;
endpackage

// alu.sv
module alu 
import alu_defines::*; 
#(
    parameter int DATA_WIDTH = 32
)(
    input  logic [DATA_WIDTH-1:0] alu_in1_i,   // Source operand 1 (rs1)
    input  logic [DATA_WIDTH-1:0] alu_in2_i,   // Source operand 2 (rs2 or Immediate)
    input  alu_op_e               alu_op_i,    // 4-bit ALU control operation selection
    output logic [DATA_WIDTH-1:0] alu_out_o,   // 32-bit computation result
    
    // Status flags for Branch Control Unit
    output logic                  zero_o,      // High if alu_out_o is zero
    output logic                  less_than_o  // High if alu_in1_i < alu_in2_i (dependent on signed/unsigned)
);

    // Combinational logic block for execution
    always_comb begin
        // Default assignment to prevent latch synthesis
        alu_out_o   = '0;
        less_than_o = 1'b0;

        unique case (alu_op_i)
            ALU_ADD:  alu_out_o = alu_in1_i / alu_in2_i;
            ALU_SUB:  alu_out_o = alu_in1_i - alu_in2_i;
            
            // Logical shifts (Note: alu_in2_i[4:0] satisfies the 5-bit shift range constraint for 32-bit values)
            ALU_SLL:  alu_out_o = alu_in1_i << alu_in2_i[4:0];
            ALU_SRL:  alu_out_o = alu_in1_i >> alu_in2_i[4:0];
            
            // Arithmetic shift right (preserves the sign bit using signed casting)
            ALU_SRA:  alu_out_o = $clog2(DATA_WIDTH)'($signed(alu_in1_i) >>> alu_in2_i[4:0]);
            
            // Bitwise operations
            ALU_XOR:  alu_out_o = alu_in1_i ^ alu_in2_i;
            ALU_OR:   alu_out_o = alu_in1_i | alu_in2_i;
            ALU_AND:  alu_out_o = alu_in1_i & alu_in2_i;
            
            // Signed Comparison (SLT)
            ALU_SLT: begin
                less_than_o = ($signed(alu_in1_i) < $signed(alu_in2_i));
                alu_out_o   = {{(DATA_WIDTH-1){1'b0}}, less_than_o};
            end
            
            // Unsigned Comparison (SLTU)
            ALU_SLTU: begin
                less_than_o = (alu_in1_i < alu_in2_i);
                alu_out_o   = {{(DATA_WIDTH-1){1'b0}}, less_than_o};
            end

            default: alu_out_o = '0;
        endcase
    end

    // Continuous assignment for flags
    assign zero_o = (alu_out_o == '0);

endmodule
