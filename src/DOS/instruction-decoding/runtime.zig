const runtime_abi = @import("runtime_abi_handshake");
const bridge = @import("bridge_instruction_decoding");

fn noopContext(_: []const u8) void {}

pub fn logDecode(scope: []const u8, sequence: u64, decoded_len: u8, invalid_opcode: bool) void {
    var event = bridge.makeDecodeEvent(.dos, sequence, scope);
    event.decoded_len = decoded_len;
    event.invalid_opcode = invalid_opcode;
    runtime_abi.common.writeLine(
        "[instruction-decoding][DOS] scope={s} seq={d} len={d} invalid={}\n",
        .{ scope, sequence, decoded_len, invalid_opcode },
    );
    bridge.reportDecodeEvent(event, noopContext);
}
