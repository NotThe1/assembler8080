package assembler;

import java.util.HashMap;
import java.util.Set;

public class InstructionSet {
	/* --------------------------------------------------*/
	public static boolean isInstruction(String token) {
		return (instructions.containsKey(token));
	}// isInstruction
	
	public static String getOpCode(String name) {
		return instructions.get(name).getOpCode();
	}// getOpCode
	
	public static int getOpCodeSize(String name) {
		return instructions.get(name).getOpCodeSize();
	}// getOpCode
	
	public static int getOperandType(String name) {
		return instructions.get(name).getOperandType();
	}// getOpCode
	
	public static byte getBaseCode(String name) {
		return instructions.get(name).getBaseCode();
	}// getOpCode
	
	public static int getOperand1Shift(String name) {
		return instructions.get(name).getOperand1Shift();
	}// getOpCode
	
	public static int getOperand2Shift(String name) {
		return instructions.get(name).getOperand2Shift();
	}// getOpCode
	
	/* ----------------------------------------*/
	public static String getRegex() {
		StringBuilder sb = new StringBuilder("\\b(?i)(");
		Set<String> operations = getInstructionSet();
		for (String operation : operations) {
			sb.append(operation);
			sb.append("|");
		} // for
		sb.deleteCharAt(sb.length() - 1);
		sb.append(")\\b");
//		System.out.printf("[InstructionSet.getRegex] sb: %s%n%n", sb.toString());
		;
		return sb.toString();
	}//getRegex
	
	public static Set<String> getInstructionSet(){
		 return instructions.keySet();
	}//getInstructionSet
	
	/* ----------------------------------------*/
	
	private static HashMap<String, Instruction> instructions;
	static {
		instructions = new HashMap<String, Instruction>();

		instructions.put("CMC", new Instruction("CMC", 1, (byte) 0X3F, Instruction.ARGUMENT_NONE));
		instructions.put("STC", new Instruction("STC", 1, (byte) 0X37, Instruction.ARGUMENT_NONE));
		instructions.put("INR", new Instruction("INR", 1, (byte) 0X04, Instruction.ARGUMENT_R8, 3)); // INC
		instructions.put("DCR", new Instruction("DCR", 1, (byte) 0X05, Instruction.ARGUMENT_R8, 3));
		instructions.put("CMA", new Instruction("CMA", 1, (byte) 0X2F, Instruction.ARGUMENT_NONE));
		instructions.put("DAA", new Instruction("DAA", 1, (byte) 0X27, Instruction.ARGUMENT_NONE));
		instructions.put("NOP", new Instruction("NOP", 1, (byte) 0X00, Instruction.ARGUMENT_NONE));
		instructions.put("HLT", new Instruction("HLT", 1, (byte) 0X76, Instruction.ARGUMENT_NONE));

		instructions.put("MOV", new Instruction("MOV", 1, (byte) 0X40, Instruction.ARGUMENT_R8_R8, 3, 0));
		instructions.put("STAX", new Instruction("STAX", 1, (byte) 0X02, Instruction.ARGUMENT_R16D, 4)); // TODO?
		instructions.put("LDAX", new Instruction("LDAX", 1, (byte) 0X0A, Instruction.ARGUMENT_R16D, 4)); // TODO?

		instructions.put("ADD", new Instruction("ADD", 1, (byte) 0X80, Instruction.ARGUMENT_R8, 0));
		instructions.put("ADC", new Instruction("ADC", 1, (byte) 0X88, Instruction.ARGUMENT_R8, 0));
		instructions.put("SUB", new Instruction("SUB", 1, (byte) 0X90, Instruction.ARGUMENT_R8, 0));
		instructions.put("SBB", new Instruction("SBB", 1, (byte) 0X98, Instruction.ARGUMENT_R8, 0));
		instructions.put("ANA", new Instruction("ANA", 1, (byte) 0XA0, Instruction.ARGUMENT_R8, 0));
		instructions.put("XRA", new Instruction("XRA", 1, (byte) 0XA8, Instruction.ARGUMENT_R8, 0));
		instructions.put("ORA", new Instruction("ORA", 1, (byte) 0XB0, Instruction.ARGUMENT_R8, 0));
		instructions.put("CMP", new Instruction("CMP", 1, (byte) 0XB8, Instruction.ARGUMENT_R8, 0));

		instructions.put("RRC", new Instruction("RRC", 1, (byte) 0X0F, Instruction.ARGUMENT_NONE));
		instructions.put("RLC", new Instruction("RLC", 1, (byte) 0X07, Instruction.ARGUMENT_NONE));
		instructions.put("RAL", new Instruction("RAL", 1, (byte) 0X17, Instruction.ARGUMENT_NONE));
		instructions.put("RAR", new Instruction("RAR", 1, (byte) 0X1F, Instruction.ARGUMENT_NONE));

		instructions.put("PUSH", new Instruction("PUSH", 1, (byte) 0XC5, Instruction.ARGUMENT_R16Q, 4));
		instructions.put("POP", new Instruction("POP", 1, (byte) 0XC1, Instruction.ARGUMENT_R16Q, 4));
		instructions.put("DAD", new Instruction("DAD", 1, (byte) 0X09, Instruction.ARGUMENT_R16D, 4));
		instructions.put("INX", new Instruction("INX", 1, (byte) 0X03, Instruction.ARGUMENT_R16D, 4));
		instructions.put("DCX", new Instruction("DCX", 1, (byte) 0X0B, Instruction.ARGUMENT_R16D, 4));

		instructions.put("XCHG", new Instruction("XCHG", 1, (byte) 0XEB, Instruction.ARGUMENT_NONE));
		instructions.put("XTHL", new Instruction("XTHL", 1, (byte) 0XE3, Instruction.ARGUMENT_NONE));
		instructions.put("SPHL", new Instruction("SPHL", 1, (byte) 0XF9, Instruction.ARGUMENT_NONE));
		instructions.put("PCHL", new Instruction("PCHL", 1, (byte) 0XE9, Instruction.ARGUMENT_NONE));

		instructions.put("LXI", new Instruction("LXI", 3, (byte) 0X01, Instruction.ARGUMENT_R16D_D16, 4));
		instructions.put("MVI", new Instruction("MVI", 2, (byte) 0X06, Instruction.ARGUMENT_R8_D8, 3));
		instructions.put("ADI", new Instruction("ADI", 2, (byte) 0XC6, Instruction.ARGUMENT_D8));
		instructions.put("ACI", new Instruction("ACI", 2, (byte) 0XCE, Instruction.ARGUMENT_D8));
		instructions.put("SUI", new Instruction("SUI", 2, (byte) 0XD6, Instruction.ARGUMENT_D8));
		instructions.put("SBI", new Instruction("SBI", 2, (byte) 0XDE, Instruction.ARGUMENT_D8));
		instructions.put("ANI", new Instruction("ANI", 2, (byte) 0XE6, Instruction.ARGUMENT_D8));
		instructions.put("XRI", new Instruction("XRI", 2, (byte) 0XEE, Instruction.ARGUMENT_D8));
		instructions.put("ORI", new Instruction("ORI", 2, (byte) 0XF6, Instruction.ARGUMENT_D8));
		instructions.put("CPI", new Instruction("CPI", 2, (byte) 0XFE, Instruction.ARGUMENT_D8));

		instructions.put("STA", new Instruction("STA", 3, (byte) 0X32, Instruction.ARGUMENT_D16));
		instructions.put("LDA", new Instruction("LDA", 3, (byte) 0X3A, Instruction.ARGUMENT_D16));
		instructions.put("SHLD", new Instruction("SHLD", 3, (byte) 0X22, Instruction.ARGUMENT_D16));
		instructions.put("LHLD", new Instruction("LHLD", 3, (byte) 0X2A, Instruction.ARGUMENT_D16));

		instructions.put("JMP", new Instruction("JMP", 3, (byte) 0XC3, Instruction.ARGUMENT_D16));
		instructions.put("JNZ", new Instruction("JNZ", 3, (byte) 0XC2, Instruction.ARGUMENT_D16));
		instructions.put("JZ", new Instruction("JZ", 3, (byte) 0XCA, Instruction.ARGUMENT_D16));
		instructions.put("JNC", new Instruction("JNC", 3, (byte) 0XD2, Instruction.ARGUMENT_D16));
		instructions.put("JC", new Instruction("JC", 3, (byte) 0XDA, Instruction.ARGUMENT_D16));
		instructions.put("JPO", new Instruction("JPO", 3, (byte) 0XE2, Instruction.ARGUMENT_D16));
		instructions.put("JPE", new Instruction("JPE", 3, (byte) 0XEA, Instruction.ARGUMENT_D16));
		instructions.put("JP", new Instruction("JP", 3, (byte) 0XF2, Instruction.ARGUMENT_D16));
		instructions.put("JM", new Instruction("JM", 3, (byte) 0XFA, Instruction.ARGUMENT_D16));

		instructions.put("CALL", new Instruction("CALL", 3, (byte) 0XCD, Instruction.ARGUMENT_D16));
		instructions.put("CNZ", new Instruction("CNZ", 3, (byte) 0XC4, Instruction.ARGUMENT_D16));
		instructions.put("CZ", new Instruction("CZ", 3, (byte) 0XCC, Instruction.ARGUMENT_D16));
		instructions.put("CNC", new Instruction("CNC", 3, (byte) 0XD4, Instruction.ARGUMENT_D16));
		instructions.put("CC", new Instruction("CC", 3, (byte) 0XDC, Instruction.ARGUMENT_D16));
		instructions.put("CPO", new Instruction("CPO", 3, (byte) 0XE4, Instruction.ARGUMENT_D16));
		instructions.put("CPE", new Instruction("CPE", 3, (byte) 0XEC, Instruction.ARGUMENT_D16));
		instructions.put("CP", new Instruction("CP", 3, (byte) 0XF4, Instruction.ARGUMENT_D16));
		instructions.put("CM", new Instruction("CM", 3, (byte) 0XFC, Instruction.ARGUMENT_D16));

		instructions.put("RET", new Instruction("RET", 1, (byte) 0XC9, Instruction.ARGUMENT_NONE));
		instructions.put("RNZ", new Instruction("RNZ", 1, (byte) 0XC0, Instruction.ARGUMENT_NONE));
		instructions.put("RZ", new Instruction("RZ", 1, (byte) 0XC8, Instruction.ARGUMENT_NONE));
		instructions.put("RNC", new Instruction("RNC", 1, (byte) 0XD0, Instruction.ARGUMENT_NONE));
		instructions.put("RC", new Instruction("RC", 1, (byte) 0XD8, Instruction.ARGUMENT_NONE));
		instructions.put("RPO", new Instruction("RPO", 1, (byte) 0XE0, Instruction.ARGUMENT_NONE));
		instructions.put("RPE", new Instruction("RPE", 1, (byte) 0XE8, Instruction.ARGUMENT_NONE));
		instructions.put("RP", new Instruction("RP", 1, (byte) 0XF0, Instruction.ARGUMENT_NONE));
		instructions.put("RM", new Instruction("RM", 1, (byte) 0XF8, Instruction.ARGUMENT_NONE));

		instructions.put("RST", new Instruction("RST", 1, (byte) 0XC7, Instruction.ARGUMENT_P8, 3));

		instructions.put("EI", new Instruction("EI", 1, (byte) 0XFB, Instruction.ARGUMENT_NONE));
		instructions.put("DI", new Instruction("DI", 1, (byte) 0XF3, Instruction.ARGUMENT_NONE));

		instructions.put("IN", new Instruction("IN", 2, (byte) 0XDB, Instruction.ARGUMENT_D8));
		instructions.put("OUT", new Instruction("OUT", 2, (byte) 0XD3, Instruction.ARGUMENT_D8));
	}// static


}//class InstructionSet
