// hazard.v

// This module determines if pipeline stalls or flushing are required

// TODO: declare propoer input and output ports and implement the
// hazard detection unit

module hazard ( //UNDONE
    input [4:0] rs1_id, rs2_id, rd_ex,
    input is_load, is_valid, taken, //idk it requires

    output reg flush, stall
);

always @(*) begin
    //stall
    //semantic: stall = ((rs1_id == rd_ex && use_rs1_IR_ID) || (rs2_id == rd_ex && use_rs2_IR_ID)) && is_load
    if (is_valid == 1'b1) begin
        stall = is_valid ? ((rs1_id == rd_ex && rs1_id == 5'b00000) || (rs2_id == rd_ex && rs1_id == 5'b00000)) && is_load : 0;
    end
    else begin
        stall = is_valid ? (rs1_id == rd_ex && rs1_id == 5'b00000) && is_load : 0;
    end

    //flush
    flush = taken ? !stall : 0; // confict in mind
end

endmodule
