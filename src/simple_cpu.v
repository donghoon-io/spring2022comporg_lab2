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
// e.g., wire [DATA_WIDTH-1:0] if_pc_plus_4;
// 1) Pipeline registers (wires to / from pipeline register modules)
// 2) In / Out ports for other modules
// 3) Additional wires for multiplexers or other mdoules you instantiate

///////////////////////////////////////////////////////////////////////////////
// Instruction Fetch (IF)
///////////////////////////////////////////////////////////////////////////////

reg [DATA_WIDTH-1:0] PC;    // program counter (32 bits)

wire [DATA_WIDTH-1:0] NEXT_PC;

/* DONGHOON'S DEFINED WIRES */
wire [DATA_WIDTH-1:0] if_pc_plus_4, if_instruction;

wire [DATA_WIDTH-1:0] id_pc, id_pc_plus_4, id_instruction, id_sextimm, id_readdata1, id_readdata2;
wire [1:0] id_jump, id_alu_op;
wire id_branch, id_alu_src, id_mem_read, id_mem_write, id_mem_to_reg, id_reg_write;
wire [4:0] id_write_reg;

wire tot_stall, tot_flush; // where should these be located? -> penetrate throughout the whole procedure, so let's go with 'tot'

wire [DATA_WIDTH-1:0] ex_pc, ex_pc_plus_4, ex_pc_target, ex_instruction, ex_sextimm, ex_readdata1, ex_readdata2, ex_writedata, ex_alu_result, ex_readdata2_after_mux, ex_feed_alu_a, ex_mem_writedata;
reg [DATA_WIDTH-1:0] ex_feed_alu_b;
wire [1:0] ex_jump, ex_alu_op, ex_forward_a, ex_forward_b;
wire ex_branch, ex_alu_src, ex_mem_read, ex_mem_write, ex_mem_to_reg, ex_reg_write, ex_check;
wire [4:0] ex_write_reg, ex_rs1, ex_rs2, ex_rd;
wire [6:0] ex_funct7;
wire [2:0] ex_funct3;
wire [3:0] ex_alu_func;
wire ex_taken;

wire mem_taken;
wire [DATA_WIDTH-1:0] mem_pc, mem_pc_plus_4, mem_pc_target, mem_instruction, mem_sextimm, mem_readdata, mem_writedata, mem_alu_result;
wire [1:0] mem_jump, mem_alu_op;
wire mem_branch, mem_alu_src, mem_mem_read, mem_mem_write, mem_mem_to_reg, mem_reg_write;
wire [4:0] mem_write_reg, mem_rd;
wire [2:0] mem_funct3;

wire [DATA_WIDTH-1:0] wb_pc_plus_4, wb_readdata, wb_alu_result, wb_writedata;
wire [1:0] wb_jump;
wire wb_mem_to_reg, wb_reg_write;
wire [4:0] wb_rd;

/* m_next_pc_adder */
adder m_pc_plus_4_adder(
  .in_a   (PC),
  .in_b   (32'd4), // 이거랑 32'b의 차이를 좀 공부해야 할 듯. 같긴 한데 매번 헷갈림

  .result (if_pc_plus_4)
);


/*

// DISCLAIMER: copied & pasted from my previous lab (lab1)
// 굳이 이렇게 안해도 될듯

wire [DATA_WIDTH-1:0] ex_sextimm_sum, ex_sextimm_rs1_sum;
reg [DATA_WIDTH-1:0] ex_sextimm_sum_result;

adder add_sextimm_sum(
  .in_a(ex_pc),
  .in_b(ex_sextimm),
  .result(ex_sextimm_sum)
);
adder add_sextimm_rs1_sum(
  .in_a(ex_readdata1),
  .in_b(ex_sextimm),
  .result(ex_sextimm_rs1_sum)
);
always @(*) begin
  case (ex_jump)
    {1'b0, 1'b0}: begin
      case (ex_taken)
      1'b1: begin
        ex_sextimm_sum_result = ex_sextimm_sum;
      end
      1'b0: begin
        ex_sextimm_sum_result = if_pc_plus_4;
      end
      default: begin
        ex_sextimm_sum_result = if_pc_plus_4;
      end
      endcase
    end
    {1'b1, 1'b0}: begin
      ex_sextimm_sum_result = ex_sextimm_sum;
    end
    {1'b0, 1'b1}: begin
      ex_sextimm_sum_result = (ex_sextimm_rs1_sum/2) << 1;
    end
    default: begin
      ex_sextimm_sum_result = if_pc_plus_4;
    end
  endcase
end
*/
//DONE

// ex인가 멤인가 헷갈림
// i suspect it's mem but works well as is..

// assign NEXT_PC = tot_stall ? PC : (ex_taken ? ex_pc_target : ex_pc_plus_4); -> 아님
assign NEXT_PC = tot_stall ? PC : (ex_taken ? ex_pc_target : id_pc_plus_4);
// TODO: consider flush/stall and make this adaptive to these values

/*
왜 안되는거지 -> reg wire 혼용해서 -> 위 assign 문으로 바꿈
always @(*) begin
  if (stall) begin
    NEXT_PC = PC;
  end
  else begin
    if (mem_taken) begin
      NEXT_PC = mem_pc_target;
    end
    else begin
      NEXT_PC = if_pc_plus_4;
    end
  end
end
*/

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
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .if_PC          (PC),
  .if_pc_plus_4   (if_pc_plus_4),
  .if_instruction (if_instruction),

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

    .id_instruction(id_instruction),
    .ex_mem_read(ex_mem_read),
    .taken(ex_taken),
    .ex_rd(ex_rd),

    
    .flush(tot_flush),
    .stall(tot_stall)
);

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

/* m_register_file: register file */
register_file m_register_file(
  .clk        (clk),
  .readreg1   (id_instruction[19:15]),
  .readreg2   (id_instruction[24:20]),
  .writereg   (wb_rd),
  .wen        (wb_reg_write),
  .writedata  (wb_writedata),

  .readdata1  (id_readdata1),
  .readdata2  (id_readdata2)
);

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
  .id_funct7    (id_instruction[31:25]), //이걸 하나의 변수로 저장해놔도 좋을듯 - 너무 숫자가 헷갈림
  .id_funct3    (id_instruction[14:12]),
  .id_readdata1 (id_readdata1),
  .id_readdata2 (id_readdata2),
  .id_rs1       (id_instruction[19:15]),
  .id_rs2       (id_instruction[24:20]),
  .id_rd        (id_instruction[11:7]),

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
  .ex_funct7    (ex_funct7),
  .ex_funct3    (ex_funct3),
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
  .in_a   (ex_pc), //나중에 수정
  .in_b   (ex_sextimm),

  .result (ex_pc_target)
);

/* m_branch_control : checks T/NT */
branch_control m_branch_control(
  .branch (ex_branch),
  .check  (ex_check),
  
  .taken  (ex_taken)
);

/* alu control : generates alu_func signal */
alu_control m_alu_control(
  .alu_op   (ex_alu_op),
  .funct7   (ex_funct7),
  .funct3   (ex_funct3),

  .alu_func (ex_alu_func)
);

mux_2x1 mux_alu(
  .select(ex_alu_src),
  .in1(ex_readdata2),
  .in2(ex_sextimm),
  .out(ex_readdata2_after_mux)
);

// Is there any way to elaborate this part better? random, messy, funny, raw

always @(*) begin
  if (ex_alu_src || ex_forward_b[1]) ex_feed_alu_b = ex_alu_src || ex_forward_b[0] ? ex_sextimm : wb_writedata;
  else ex_feed_alu_b = ex_alu_src || ex_forward_b[0] ? mem_alu_result : ex_readdata2;
end

/* m_alu */
alu m_alu(
  .alu_func (ex_alu_func),
  .in_a     (ex_feed_alu_a), 
  .in_b     (ex_feed_alu_b),  //change

  .result   (ex_alu_result),
  .check    (ex_check)
);

forwarding m_forwarding(
  // TODO: implement forwarding unit & do wiring
  .ex_rs1(ex_rs1),
  .ex_rs2(ex_rs2),
  .mem_rd(mem_rd),
  .wb_rd(wb_rd),
  .mem_reg_write(mem_reg_write),
  .wb_reg_write(wb_reg_write),

  // output data_spec name
  .forward_a(ex_forward_a),
  .forward_b(ex_forward_b)
);

// %1 implement forwarding a part first % change case statement to mux

mux_3x1 forwarding_a_mux(
  .select(ex_forward_a),
  .in1(ex_readdata1),
  .in2(wb_writedata),
  .in3(mem_alu_result),
  
  .out(ex_feed_alu_a)
);

// %1 implement forwarding b part first % change case statement to mux

mux_3x1 forwarding_b_to_ex_mem_mux(
  .select(ex_forward_b),
  .in1(ex_readdata2), // ppt 대신 책 그림 보고 이해하기
  .in2(wb_writedata),
  .in3(mem_alu_result),
  
  .out(ex_mem_writedata)
);

// CAVEAT: I haven't checked if the ordering matters. Let's revisit here

/* forward to EX/MEM stage registers */
exmem_reg m_exmem_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .ex_pc_plus_4   (ex_pc_plus_4),
  .ex_pc_target   (ex_pc_target),
  .ex_taken       (ex_taken), 
  .ex_jump        (ex_jump),
  .ex_memread     (ex_mem_read),
  .ex_memwrite    (ex_mem_write),
  .ex_memtoreg    (ex_mem_to_reg),
  .ex_regwrite    (ex_reg_write),
  .ex_alu_result  (ex_alu_result),
  .ex_writedata   (ex_mem_writedata), // readdata1 안됨 -> 위에 로직 넣어서 수정함
  .ex_funct3      (ex_funct3),
  .ex_rd          (ex_rd),
  
  .mem_pc_plus_4  (mem_pc_plus_4),
  .mem_pc_target  (mem_pc_target),
  .mem_taken      (mem_taken), 
  .mem_jump       (mem_jump),
  .mem_memread    (mem_mem_read),
  .mem_memwrite   (mem_mem_write),
  .mem_memtoreg   (mem_mem_to_reg),
  .mem_regwrite   (mem_reg_write),
  .mem_alu_result (mem_alu_result),
  .mem_writedata  (mem_writedata),
  .mem_funct3     (mem_funct3),
  .mem_rd         (mem_rd)
);


//////////////////////////////////////////////////////////////////////////////////
// Memory (MEM) 
//////////////////////////////////////////////////////////////////////////////////

/* m_data_memory : main memory module */
data_memory m_data_memory(
  .clk         (clk),
  .address     (mem_alu_result),
  .write_data  (mem_writedata),
  .mem_read    (mem_mem_read),
  .mem_write   (mem_mem_write),
  .maskmode    (mem_funct3[1:0]),
  .sext        (mem_funct3[2]),

  .read_data   (mem_readdata)
);

/* forward to MEM/WB stage registers */
memwb_reg m_memwb_reg(
  // TODO: Add flush or stall signal if it is needed
  .clk            (clk),
  .mem_pc_plus_4  (mem_pc_plus_4),
  .mem_jump       (mem_jump),
  .mem_memtoreg   (mem_mem_to_reg),
  .mem_regwrite   (mem_reg_write),
  .mem_readdata   (mem_readdata),
  .mem_alu_result (mem_alu_result),
  .mem_rd         (mem_rd),

  .wb_pc_plus_4   (wb_pc_plus_4),
  .wb_jump        (wb_jump),
  .wb_memtoreg    (wb_mem_to_reg),
  .wb_regwrite    (wb_reg_write),
  .wb_readdata    (wb_readdata),
  .wb_alu_result  (wb_alu_result),
  .wb_rd          (wb_rd)
);

//////////////////////////////////////////////////////////////////////////////////
// Write Back (WB) 
//////////////////////////////////////////////////////////////////////////////////

// implement mux wb
// DISCLAIMER: copied & pasted from my prev lab (lab1)

mux_2x1 mux_wb(
  .select(wb_jump == {2{1'b0}} ? 1'b0:1'b1),
  .in1(wb_mem_to_reg == 1'b0 ? wb_alu_result:wb_readdata),
  .in2(wb_pc_plus_4),
  .out(wb_writedata)
);


endmodule
