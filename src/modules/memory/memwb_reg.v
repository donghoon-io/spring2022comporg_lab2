// memwb_reg.v
// This module is the MEM/WB pipeline register.


module memwb_reg #(
  parameter DATA_WIDTH = 32
)(
  // TODO: Add flush or stall signal if it is needed

  //////////////////////////////////////
  // Inputs
  //////////////////////////////////////
  input clk,

  input [DATA_WIDTH-1:0] mem_pc_plus_4,

  // wb control
  input [1:0] mem_jump,
  input mem_memtoreg,
  input mem_regwrite,
  
  input [DATA_WIDTH-1:0] mem_readdata,
  input [DATA_WIDTH-1:0] mem_alu_result,
  input [4:0] mem_rd,
  
  //////////////////////////////////////
  // Outputs
  //////////////////////////////////////
  output [DATA_WIDTH-1:0] wb_pc_plus_4,

  // wb control
  output [1:0] wb_jump,
  output wb_memtoreg,
  output wb_regwrite,
  
  output [DATA_WIDTH-1:0] wb_readdata,
  output [DATA_WIDTH-1:0] wb_alu_result,
  output [4:0] wb_rd
);

// TODO: Implement MEM/WB pipeline register module

reg [DATA_WIDTH-1:0] wb_pc_plus_4;

// wb control
reg [1:0] wb_jump;
reg wb_memtoreg;
reg wb_regwrite;

reg [DATA_WIDTH-1:0] wb_readdata;
reg [DATA_WIDTH-1:0] wb_alu_result;
reg [4:0] wb_rd;

always @(*) begin
  mem_pc_plus_4 <= wb_pc_plus_4;

  mem_jump <= wb_jump;
  mem_memtoreg <= wb_memtoreg;
  mem_regwrite <= wb_regwrite;

  mem_readdata <= wb_readdata;
  mem_alu_result <= wb_alu_result;
  mem_rd <= wb_rd;
end

endmodule
