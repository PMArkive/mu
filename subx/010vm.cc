//: Core data structures for simulating the SubX VM (subset of an x86 processor)

//:: registers
//: assume segment registers are hard-coded to 0
//: no floating-point, MMX, etc. yet

:(before "End Types")
enum {
  EAX,
  ECX,
  EDX,
  EBX,
  ESP,
  EBP,
  ESI,
  EDI,
  NUM_INT_REGISTERS,
};
union reg {
  int32_t i;
  uint32_t u;
};
:(before "End Globals")
reg Reg[NUM_INT_REGISTERS] = { {0} };
uint32_t EIP = 1;  // preserve null pointer
:(before "End Reset")
bzero(Reg, sizeof(Reg));
EIP = 1;  // preserve null pointer

:(before "End Help Contents")
cerr << "  registers\n";
:(before "End Help Texts")
put(Help, "registers",
  "SubX currently supports 8 integer registers, numbered from 0 to 7.\n"
  "There's also a register for the address of the currently executing instruction. It is modified by jumps.\n"
  "Various instructions modify one or more of 3 flags, as a side-effect:\n"
  "- the sign flag: usually set if an arithmetic result is negative, or reset if not.\n"
  "- the zero flag: usually set if a result is zero, or reset if not.\n"
  "- the overflow flag: usually set if an arithmetic result overflows.\n"
  "We don't support non-integer (floating-point) registers yet.\n"
);

:(before "End Globals")
// the subset of x86 flag registers we care about
bool SF = false;  // sign flag
bool ZF = false;  // zero flag
bool OF = false;  // overflow flag
:(before "End Reset")
SF = ZF = OF = false;

//: how the flag registers are updated after each instruction

:(before "End Includes")
// Combine 'arg1' and 'arg2' with arithmetic operation 'op' and store the
// result in 'arg1', then update flags.
// beware: no side-effects in args
#define BINARY_ARITHMETIC_OP(op, arg1, arg2) { \
  /* arg1 and arg2 must be signed */ \
  int64_t tmp = arg1 op arg2; \
  arg1 = arg1 op arg2; \
  trace(2, "run") << "storing 0x" << HEXWORD << arg1 << end(); \
  SF = (arg1 < 0); \
  ZF = (arg1 == 0); \
  OF = (arg1 != tmp); \
}

// Combine 'arg1' and 'arg2' with bitwise operation 'op' and store the result
// in 'arg1', then update flags.
#define BINARY_BITWISE_OP(op, arg1, arg2) { \
  /* arg1 and arg2 must be unsigned */ \
  arg1 = arg1 op arg2; \
  trace(2, "run") << "storing 0x" << HEXWORD << arg1 << end(); \
  SF = (arg1 >> 31); \
  ZF = (arg1 == 0); \
  OF = false; \
}

//:: simulated RAM

:(before "End Globals")
vector<uint8_t> Mem;
uint32_t Mem_offset = 0;
uint32_t End_of_program = 0;
:(before "End Reset")
Mem.clear();
Mem.resize(1024);
Mem_offset = 0;
End_of_program = 0;
:(code)
// These helpers depend on Mem being laid out contiguously (so you can't use a
// map, etc.) and on the host also being little-endian.
inline uint8_t read_mem_u8(uint32_t addr) {
  return Mem.at(addr-Mem_offset);
}
inline int8_t read_mem_i8(uint32_t addr) {
  return static_cast<int8_t>(Mem.at(addr-Mem_offset));
}
inline uint32_t read_mem_u32(uint32_t addr) {
  return *reinterpret_cast<uint32_t*>(&Mem.at(addr-Mem_offset));
}
inline int32_t read_mem_i32(uint32_t addr) {
  return *reinterpret_cast<int32_t*>(&Mem.at(addr-Mem_offset));
}

inline uint8_t* mem_addr_u8(uint32_t addr) {
  return &Mem.at(addr-Mem_offset);
}
inline int8_t* mem_addr_i8(uint32_t addr) {
  return reinterpret_cast<int8_t*>(&Mem.at(addr-Mem_offset));
}
inline uint32_t* mem_addr_u32(uint32_t addr) {
  return reinterpret_cast<uint32_t*>(&Mem.at(addr-Mem_offset));
}
inline int32_t* mem_addr_i32(uint32_t addr) {
  return reinterpret_cast<int32_t*>(&Mem.at(addr-Mem_offset));
}

inline void write_mem_u8(uint32_t addr, uint8_t val) {
  Mem.at(addr-Mem_offset) = val;
}
inline void write_mem_i8(uint32_t addr, int8_t val) {
  Mem.at(addr-Mem_offset) = static_cast<uint8_t>(val);
}
inline void write_mem_u32(uint32_t addr, uint32_t val) {
  *reinterpret_cast<uint32_t*>(&Mem.at(addr-Mem_offset)) = val;
}
inline void write_mem_i32(uint32_t addr, int32_t val) {
  *reinterpret_cast<int32_t*>(&Mem.at(addr-Mem_offset)) = val;
}

//:: core interpreter loop

:(code)
// skeleton of how x86 instructions are decoded
void run_one_instruction() {
  uint8_t op=0, op2=0, op3=0;
  trace(2, "run") << "inst: 0x" << HEXWORD << EIP << end();
//?   cerr << "inst: 0x" << EIP << '\n';
  switch (op = next()) {
  case 0xf4:  // hlt
    EIP = End_of_program;
    break;
  // End Single-Byte Opcodes
  case 0x0f:
    switch(op2 = next()) {
    // End Two-Byte Opcodes Starting With 0f
    default:
      cerr << "unrecognized second opcode after 0f: " << HEXBYTE << NUM(op2) << '\n';
      DUMP("");
      exit(1);
    }
    break;
  case 0xf3:
    switch(op2 = next()) {
    // End Two-Byte Opcodes Starting With f3
    case 0x0f:
      switch(op3 = next()) {
      // End Three-Byte Opcodes Starting With f3 0f
      default:
        cerr << "unrecognized third opcode after f3 0f: " << HEXBYTE << NUM(op3) << '\n';
        DUMP("");
        exit(1);
      }
      break;
    default:
      cerr << "unrecognized second opcode after f3: " << HEXBYTE << NUM(op2) << '\n';
      DUMP("");
      exit(1);
    }
    break;
  default:
    cerr << "unrecognized opcode: " << HEXBYTE << NUM(op) << '\n';
    DUMP("");
    exit(1);
  }
}

inline uint8_t next() {
  return read_mem_u8(EIP++);
}

:(before "End Includes")
#include <iomanip>
#define HEXBYTE  std::hex << std::setw(2) << std::setfill('0')
#define HEXWORD  std::hex << std::setw(8) << std::setfill('0')
// ugly that iostream doesn't print uint8_t as an integer
#define NUM(X) static_cast<int>(X)
#include <stdint.h>
