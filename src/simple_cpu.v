// simple_cpu.v
// a pipelined RISC-V microarchitecture (RV32I)

///////////////////////////////////////////////////////////////////////////////////////////
//// [*] In simple_cpu.v you should connect the correct wires to the correct ports
////     - All modules are given so there is no need to make new modules
////       (it does not mean you do not need to instantiate new modules)
////     - However, you may have to fix or add in / out ports for some modules
////     - In addition, you are still free to instantiate simple modules like multiplexers,
////       adders, etc.
///////////////////////////////////////////////////////////////////////////////////////////

module simple_cpu
#(parameter DATA_WIDTH = 32)(
  input clk,
  input rstn
);

///////////////////////////////////////////////////////////////////////////////
// TODO:  Declare all wires / registers that are needed
///////////////////////////////////////////////////////////////////////////////
wire [DATA_WIDTH-1:0] if_pc_plus_4, if_instruction, id_pc, id_pc_plus_4, id_instruction, id_sextimm;
wire flush, stall;


///////////////////////////////////////////////////////////////////////////////
// Instruction Fetch (IF)
///////////////////////////////////////////////////////////////////////////////

reg [DATA_WIDTH-1:0] PC;    // program counter (32 bits)

wire [DATA_WIDTH-1:0] NEXT_PC;

/* m_next_pc_adder */
adder m_pc_plus_4_adder(
  .in_a   (PC),
  .in_b   (32'h00000040),

  .result (if_pc_plus_4)
);

always @(posedge clk) begin
  if (rstn == 1'b0) begin
    PC <= 32'h00000000;
  end
  else PC <= NEXT_PC;
end

/* instruction: read current instruction from inst mem */
instruction_memory m_instruction_memory(
  .address    (PC),

  .instruction(if_instruction)
);

/* forward to IF/ID stage registers */
ifid_reg m_ifid_reg(
  // TODO: Add flush or stall signal if it is needed (DONE)
  .clk            (clk),
  .if_PC          (PC),
  .if_pc_plus_4   (if_pc_plus_4),
  .if_instruction (if_instruction),

  // below are added
  //.flush(flush),
  //.stall(stall),

  .id_PC          (id_pc),
  .id_pc_plus_4   (id_pc_plus_4),
  .id_instruction (id_instruction)
);


//////////////////////////////////////////////////////////////////////////////////
// Instruction Decode (ID)
//////////////////////////////////////////////////////////////////////////////////

/* m_hazard: hazard detection unit */
hazard m_hazard(
  // TODO: implement hazard detection unit & do wiring
);

// DEFINED
wire [1:0] id_jump, id_alu_op;
wire id_branch, id_alu_src, id_mem_read, id_mem_write, id_mem_to_reg, id_reg_write;

/* m_control: control unit */
control m_control(
  .opcode     (id_instruction[6:0]),

  .jump       (id_jump),
  .branch     (id_branch),
  .alu_op     (id_alu_op),
  .alu_src    (id_alu_src),
  .mem_read   (id_mem_read),
  .mem_to_reg (id_mem_to_reg),
  .mem_write  (id_mem_write),
  .reg_write  (id_reg_write)
);

/* m_imm_generator: immediate generator */
immediate_generator m_immediate_generator(
  .instruction(id_instruction),

  .sextimm    (id_sextimm)
);

//DEFINED
wire [4:0] write_reg;
wire [DATA_WIDTH-1:0] wb_to_write, id_data_1, id_data_2;
wire wb_reg_write;

/* m_register_file: register file */
register_file m_register_file(
  .clk        (clk),
  .readreg1   (id_instruction[19:15]),
  .readreg2   (id_instruction[24:20]),
  .writereg   (write_reg),
  .wen        (wb_reg_write),
  .writedata  (wb_to_write),

  .readdata1  (id_data_1),
  .readdata2  (id_data_2)
);

//DEFINED

wire [DATA_WIDTH-1:0] ex_pc_target;

wire [DATA_WIDTH-1:0] ex_pc, ex_pc_plus_4, ex_sextimm;
wire [1:0] ex_jump, ex_alu_op;
wire ex_branch, ex_alu_src, ex_mem_read, ex_mem_write, ex_mem_to_reg, ex_reg_write;

wire [6:0] ex_func7;
wire [2:0] ex_func3;

wire [DATA_WIDTH-1:0] ex_readdata1, ex_readdata2;
wire [4:0] ex_rs1, ex_rs2, ex_rd;

/* forward to ID/EX stage registers */
idex_reg m_idex_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk          (clk),
  .id_PC        (id_pc),
  .id_pc_plus_4 (id_pc_plus_4),
  .id_jump      (id_jump),
  .id_branch    (id_branch),
  .id_aluop     (id_alu_op),
  .id_alusrc    (id_alu_src),
  .id_memread   (id_mem_read),
  .id_memwrite  (id_mem_write),
  .id_memtoreg  (id_mem_to_reg),
  .id_regwrite  (id_reg_write),
  .id_sextimm   (id_sextimm),
  .id_funct7    (id_instruction[31:25]), //31 -- 25
  .id_funct3    (id_instruction[14:12]), //14 -- 12
  .id_readdata1 (id_data_1),
  .id_readdata2 (id_data_2),
  .id_rs1       (id_instruction[19:15]), //19 -- 15
  .id_rs2       (id_instruction[24:20]), //24 -- 20
  .id_rd        (id_instruction[11:7]),

  // TODO: ADD SOME HERE

  .ex_PC        (ex_pc),
  .ex_pc_plus_4 (ex_pc_plus_4),
  .ex_jump      (ex_jump),
  .ex_branch    (ex_branch),
  .ex_aluop     (ex_alu_op),
  .ex_alusrc    (ex_alu_src),
  .ex_memread   (ex_mem_read),
  .ex_memwrite  (ex_mem_write),
  .ex_memtoreg  (ex_mem_to_reg),
  .ex_regwrite  (ex_reg_write),
  .ex_sextimm   (ex_sextimm),
  .ex_funct7    (ex_func7),
  .ex_funct3    (ex_func3),
  .ex_readdata1 (ex_readdata1),
  .ex_readdata2 (ex_readdata2),
  .ex_rs1       (ex_rs1),
  .ex_rs2       (ex_rs2),
  .ex_rd        (ex_rd)
);

//////////////////////////////////////////////////////////////////////////////////
// Execute (EX) 
//////////////////////////////////////////////////////////////////////////////////

/* m_branch_target_adder: PC + imm for branch address */
adder m_branch_target_adder(
  .in_a   (jump == {2{1'b0}} ? ex_pc:{ex_readdata1[31:1], 1'b0}), //cases from my previous lab1 proj -> 00:uncond
  .in_b   (ex_sextimm),

  .result (ex_pc_target)
);

/* m_branch_control : checks T/NT */
branch_control m_branch_control(
  .branch (),
  .check  (),
  
  .taken  ()
);

/* alu control : generates alu_func signal */
alu_control m_alu_control(
  .alu_op   (),
  .funct7   (),
  .funct3   (),

  .alu_func ()
);

/* m_alu */
alu m_alu(
  .alu_func (),
  .in_a     (), 
  .in_b     (), 

  .result   (),
  .check    ()
);

forwarding m_forwarding(
  // TODO: implement forwarding unit & do wiring

  .rs1_ex(),
  .rs2_ex(),
  .rd_mem(),
  .rd_wb(),
  .regwrite_mem(),
  .regwrite_wb(),

  .forward_a(),
  .forward_b()
);

/* forward to EX/MEM stage registers */
exmem_reg m_exmem_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .ex_pc_plus_4   (ex_pc_plus_4),
  .ex_pc_target   (ex_pc_target),
  .ex_taken       (), 
  .ex_jump        (),
  .ex_memread     (),
  .ex_memwrite    (),
  .ex_memtoreg    (),
  .ex_regwrite    (),
  .ex_alu_result  (),
  .ex_writedata   (),
  .ex_funct3      (),
  .ex_rd          (),
  
  .mem_pc_plus_4  (),
  .mem_pc_target  (),
  .mem_taken      (), 
  .mem_jump       (),
  .mem_memread    (),
  .mem_memwrite   (),
  .mem_memtoreg   (),
  .mem_regwrite   (),
  .mem_alu_result (),
  .mem_writedata  (),
  .mem_funct3     (),
  .mem_rd         ()
);


//////////////////////////////////////////////////////////////////////////////////
// Memory (MEM) 
//////////////////////////////////////////////////////////////////////////////////

/* m_data_memory : main memory module */
data_memory m_data_memory(
  .clk         (clk),
  .address     (),
  .write_data  (),
  .mem_read    (),
  .mem_write   (),
  .maskmode    (),
  .sext        (),

  .read_data   ()
);

/* forward to MEM/WB stage registers */
memwb_reg m_memwb_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .mem_pc_plus_4  (),
  .mem_jump       (),
  .mem_memtoreg   (),
  .mem_regwrite   (),
  .mem_readdata   (),
  .mem_alu_result (),
  .mem_rd         (),

  .wb_pc_plus_4   (),
  .wb_jump        (),
  .wb_memtoreg    (),
  .wb_regwrite    (),
  .wb_readdata    (),
  .wb_alu_result  (),
  .wb_rd          ()
);

//////////////////////////////////////////////////////////////////////////////////
// Write Back (WB) 
//////////////////////////////////////////////////////////////////////////////////


endmodule
