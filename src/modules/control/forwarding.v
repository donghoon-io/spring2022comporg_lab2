// forwarding.v //이상 무 //ppt에 따르면 순서 반대라 이걸 따라주는게 좋을듯..? 너무 자의적으로 해버림..

// This module determines if the values need to be forwarded to the EX stage.

// TODO: declare propoer input and output ports and implement the
// forwarding unit

module forwarding (
  // input data_spec name
  input [4:0] rs1_ex,
  input [4:0] rs2_ex,
  input [4:0] rd_mem,
  input [4:0] rd_wb,
  input regwrite_mem,
  input regwrite_wb,

  // output data_spec name
  output reg [1:0] forward_a,
  output reg [1:0] forward_b
);

// forward_a
always @(*) begin
    if ((rs1_ex != 5'b00000) && (rs1_ex == rd_mem) && regwrite_mem)
        forward_a = 2'b01;
    else if ((rs1_ex != 5'b00000) && (rs1_ex == rd_wb) && regwrite_wb)
        forward_a = 2'b10;
    else
        forward_a = 2'b00;
end

// forward_b
always @(*) begin
    if ((rs2_ex != 5'b00000) && (rs2_ex == rd_mem) && regwrite_mem)
        forward_b = 2'b01;
    else if ((rs2_ex != 5'b00000) && (rs2_ex == rd_wb) && regwrite_wb)
        forward_b = 2'b10;
    else
        forward_b = 2'b00;
end

endmodule
