// ifid_reg.v
// This module is the IF/ID pipeline register.


module ifid_reg #(
  parameter DATA_WIDTH = 32
)(
  // TODO: Add flush or stall signal if it is needed

  //////////////////////////////////////
  // Inputs
  //////////////////////////////////////
  input clk,

  input [DATA_WIDTH-1:0] if_PC,
  input [DATA_WIDTH-1:0] if_pc_plus_4,
  input [DATA_WIDTH-1:0] if_instruction,

  //////////////////////////////////////
  // Outputs
  //////////////////////////////////////
  output [DATA_WIDTH-1:0] id_PC,
  output [DATA_WIDTH-1:0] id_pc_plus_4,
  output [DATA_WIDTH-1:0] id_instruction
);

// TODO: Implement IF/ID pipeline register module

reg [DATA_WIDTH-1:0] id_PC;
reg [DATA_WIDTH-1:0] id_pc_plus_4;
reg [DATA_WIDTH-1:0] id_instruction;

always @(posedge clk) begin
  id_PC <= if_PC;
  id_pc_plus_4 <= if_pc_plus_4;
  id_instruction <= if_instruction;
end

endmodule
