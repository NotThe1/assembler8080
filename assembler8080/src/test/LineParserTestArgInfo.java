package test;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.junit.Assert.assertThat;

import org.junit.Test;

import assembler.LineParser;

public class LineParserTestArgInfo {
	@Test
	public void testArgumentInfo() {
		LineParser lp = new LineParser();
		String sourceLine = "Label:    ";
//		lp.parse(sourceLine);
//		assertThat("just a label", null, equalTo(lp.getArgument()));
//		
//		sourceLine = "STAX";
//		lp.parse(sourceLine);
//		assertThat("just a instruction", null, equalTo(lp.getArgument()));
//
//		sourceLine = "ORG";
//		lp.parse(sourceLine);
//		assertThat("just a directive", null, equalTo(lp.getArgument()));
//
//		sourceLine = "MVI			; Number of 128 byte sectors";
//		lp.parse(sourceLine);
//		assertThat("just a instruction and comment", null, equalTo(lp.getArgument()));
//
//		sourceLine = "MVI	A,AllocationBlockSize/ 128";
//		lp.parse(sourceLine);
//		assertThat("an instruction and Arg", "A,AllocationBlockSize/ 128", equalTo(lp.getArgument()));
//
//		sourceLine = "CALL	A,AllocationBlockSize/ 128	; Number of 128 byte sectors";
//		lp.parse(sourceLine);
//		assertThat("an instruction, comment and Arg", "A,AllocationBlockSize/ 128", equalTo(lp.getArgument()));

		sourceLine = "DW	A,AllocationBlockSize/ 128	; Number of 128 byte sectors";
		lp.parse(sourceLine);
		assertThat("an directive 0, comment and Arg", "DW", equalTo(lp.getDirective()));
		assertThat("an directive 00, comment and Arg", null, equalTo(lp.getInstruction()));
		assertThat("an directive 1, comment and Arg", "A,AllocationBlockSize/ 128", equalTo(lp.getArgument()));


//		String[] opCodes = { " STC", "INR ", " STAX ", " PUSH", "MOV ", " MVI", "LXI", "ADI", "STA" };
//		byte[] baseCodes = { (byte) 0X37, (byte) 0X04, (byte) 0X02, (byte) 0XC5, (byte) 0X40, (byte) 0X06, (byte) 0X01,
//				(byte) 0XC6, (byte) 0X32 };
//		int[] operand1Shifts = { 0, 3, 4, 4, 3, 3, 4, 0, 0 };
//		int[] operandTypes = { Instruction.ARGUMENT_NONE, Instruction.ARGUMENT_R8, Instruction.ARGUMENT_R16D,
//				Instruction.ARGUMENT_R16Q, Instruction.ARGUMENT_R8_R8, Instruction.ARGUMENT_R8_D8,
//				Instruction.ARGUMENT_R16D_D16, Instruction.ARGUMENT_D8, Instruction.ARGUMENT_D16 };
//		
//		for (int i = 0; i < opCodes.length; i++) {
//			lp.parse(opCodes[i]);
//			assertThat(opCodes[i] + "- baseCode", baseCodes[i], equalTo(lp.getBaseCode()));
//			assertThat(opCodes[i] + "- operand1Shift", operand1Shifts[i], equalTo(lp.getOperand1Shift()));
//			assertThat(opCodes[i] + "- operand2Shift", 0, equalTo(lp.getOperand2Shift()));
//			assertThat(opCodes[i] + "- operandTypes", operandTypes[i], equalTo(lp.getOperandType()));
//		} // if
	}// testArgumentInfo

}//LineParserTestArgInfo
