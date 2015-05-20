package assembler;

import java.util.HashMap;

//import machineParts.Reg;

public class Instruction {

	private String opCode;
	private int opCodeSize; // for locationCounter advancement advancement
	private Byte baseCode;
	private Integer operandType;
	private int operand1Shift; // shift amount for this operand
	private int operand2Shift; // shift amount for this operand

	public Instruction(String opCode, int opCodeSize, byte baseCode, Integer operandType) {
		this.opCode = opCode;
		this.opCodeSize = opCodeSize;
		this.baseCode = baseCode;
		this.operandType = operandType;
	}// Constructor - Instruction(opCode, opCodesize, baseCode, operandType)

	public Instruction(String opCode, int opCodeSize, byte baseCode, Integer operandType, int operand1Shift) {
		this.opCode = opCode;
		this.opCodeSize = opCodeSize;
		this.baseCode = baseCode;
		this.operandType = operandType;
		this.operand1Shift = operand1Shift;
	}// Constructor - Instruction(opCode, opCodesize, baseCode,
		// operandType,operand1Shift)

	public Instruction(String opCode, int opCodeSize, byte baseCode, Integer operandType, int operand1Shift,
			int operand2Shift) {
		this.opCode = opCode;
		this.opCodeSize = opCodeSize;
		this.baseCode = baseCode;
		this.operandType = operandType;
		this.operand1Shift = operand1Shift;
		this.operand2Shift = operand2Shift;
	}// Constructor - Instruction(opCode, opCodesize, baseCode,
		// operandType,operand1Shift,operand2Shift)

	public Instruction() {
		// TODO Auto-generated constructor stub
	}// Constructor - Instruction()

	public String getOpCode() {
		return opCode;
	}// getOpCode

	public int getOpCodeSize() {
		return opCodeSize;
	}// getOpCodeSize

	public int getOperandType() {
		return operandType;
	}// getOperandType

	public Byte getBaseCode() {
		return baseCode;
	}// getBaseCode

	public int getOperand1Shift() {
		return operand1Shift;
	}// getOperand1Position

	public int getOperand2Shift() {
		return operand2Shift;
	}// getOperand2Position

	public static Byte getR8Value(String r) {
		if (r.matches("A|B|C|D|E|H|L|M|A")) {
			return decodeR8.get(r);
		} else {
			throw new AssemblerException("bad R8 value: " + r);
		}
	}// getR8Value

	public static Byte getR16DValue(String r) {
		if (r.matches("BC|B|DE|D|HL|H|SP")) {
			return decodeR16D.get(r);
		} else{
			throw new AssemblerException("bad R16D value: " + r);
	}// if
	}// getR16DValue
	
	public static Byte getR16QValue(String r) {
		if (r.matches("BC|B|DE|D|HL|H|AF|PSW")) {
			return decodeR16Q.get(r);
		} else{
			throw new AssemblerException("bad R16Q value: " + r);
	}// if
	}// getR16DValue

	public static final int ARGUMENT_NONE = 0;

	public static final int ARGUMENT_R8 = 1; // RRR = B,C,D,E,H,L,M,A
	public static final int ARGUMENT_R16D = 2; // DD = BC,DE,HL,SP
	public static final int ARGUMENT_R16Q = 3; // QQ = BC,DE,HL,AF (PSW)

	public static final int ARGUMENT_R8_R8 = 4; // RRR = B,C,D,E,H,L,M,A
	public static final int ARGUMENT_R8_D8 = 5; // RRR = B,C,D,E,H,L,M,A

	public static final int ARGUMENT_R16D_D16 = 6; // DD = BC,DE,HL,SP

	public static final int ARGUMENT_D8 = 7; // BYTE
	public static final int ARGUMENT_D16 = 8; // WORD / Address

	public static final int ARGUMENT_P8 = 9; // used by the rst instruction
	/*
	 * used by directives
	 */
	public static final int ARGUMENT_STRING = 10; // used by the rst instruction
	public static final int ARGUMENT_SPECIAL = 11; // used by the rst
													// instruction
	public static final int ARGUMENT_BOOLEAN = 12; // used by the rst
													// instruction

	private static final HashMap<String, Byte> decodeR8;
	static {
		decodeR8 = new HashMap<String, Byte>();
		decodeR8.put("B", (byte) 0X00);
		decodeR8.put("C", (byte) 0X01);
		decodeR8.put("D", (byte) 0X02);
		decodeR8.put("E", (byte) 0X03);
		decodeR8.put("H", (byte) 0X04);
		decodeR8.put("L", (byte) 0X05);
		decodeR8.put("M", (byte) 0X06);
		decodeR8.put("A", (byte) 0X07);
	};
	private static final HashMap<String, Byte> decodeR16D;
	static {
		decodeR16D = new HashMap<String, Byte>();
		decodeR16D.put("BC", (byte) 0X00);
		decodeR16D.put("B", (byte) 0X00);
		decodeR16D.put("DE", (byte) 0X01);
		decodeR16D.put("D", (byte) 0X01);
		decodeR16D.put("HL", (byte) 0X02);
		decodeR16D.put("H", (byte) 0X02);
		decodeR16D.put("SP", (byte) 0X03);
	};
	private static final HashMap<String, Byte> decodeR16Q;
	static {
		decodeR16Q = new HashMap<String, Byte>();
		decodeR16Q.put("BC", (byte) 0X00);
		decodeR16Q.put("B", (byte) 0X00);
		decodeR16Q.put("DE", (byte) 0X01);
		decodeR16Q.put("D", (byte) 0X01);
		decodeR16Q.put("HL", (byte) 0X02);
		decodeR16Q.put("H", (byte) 0X02);
		decodeR16Q.put("AF", (byte) 0X03);
		decodeR16Q.put("PSW", (byte) 0X03);
	};

	// private Reg[] registerDecode = { Reg.B, Reg.C, Reg.D, Reg.E, Reg.H,
	// Reg.L, Reg.M, Reg.A };
	// private Reg[] registerPairDecodeSetD = { Reg.BC, Reg.DE, Reg.HL, Reg.SP
	// };
	// private Reg[] registerPairDecodeSetQ = { Reg.BC, Reg.DE, Reg.HL, Reg.AF
	// };

}// class Instruction
