package test;

import static org.hamcrest.CoreMatchers.equalTo;
import static org.junit.Assert.assertThat;

import java.util.Set;

import org.junit.Test;

import assembler.DirectiveSet;
import assembler.InstructionSet;
import assembler.LineParser;

public class LineParserTestInstructionsAndDirectives {
	@Test
	public void testInstructions() {
		LineParser lp = new LineParser();
		String sourceLine, label, comment;

		sourceLine = "label:       ;comment";
		lp.parse(sourceLine);
		assertThat("only a label and comment no  instruction", null, equalTo(lp.getInstruction()));

		lp.parse(sourceLine + " ldAx ");
		assertThat("only a label and comment with instruction in it", null, equalTo(lp.getInstruction()));

		sourceLine = "label:  sTaX     ;comment";
		lp.parse(sourceLine);
		assertThat("Has instruction", true, equalTo(lp.hasInstruction()));
		assertThat("only a label and comment and  instruction", "STAX", equalTo(lp.getInstruction()));

		sourceLine = "label:  sTaXa     ;comment";
		lp.parse(sourceLine);
		assertThat("only a label and comment and  bad instruction", null, equalTo(lp.getInstruction()));

		Set<String> instructions = InstructionSet.getInstructionSet();
		label = "label: ";
		comment = " ; comment";
		for (String instruction : instructions) {
			lp.parse(label + instruction + comment);
			assertThat("Instruction set: " + instruction, instruction, equalTo(lp.getInstruction()));
		} // for

	}// testInstructions

	@Test
	public void testDirectives() {
		LineParser lp = new LineParser();
		String sourceLine, label, comment;

		sourceLine = "label:       ;comment";
		lp.parse(sourceLine);
		assertThat("only a label and comment no  directive", null, equalTo(lp.getDirective()));

		lp.parse(sourceLine + " equ ");
		assertThat("only a label and comment with directive in it", null, equalTo(lp.getDirective()));

		sourceLine = "label:  DB     ;comment";
		lp.parse(sourceLine);
		assertThat("Has directive", true, equalTo(lp.hasDirective()));
		assertThat("only a label and comment and  directive", "DB", equalTo(lp.getDirective()));

		sourceLine = "label:  DWX     ;comment";
		lp.parse(sourceLine);
		assertThat("only a label and comment and  bad Directive", null, equalTo(lp.getDirective()));

		Set<String> directives = DirectiveSet.getDirectiveSet();
		label = "label: ";
		comment = " ; comment";
		for (String directive : directives) {
			lp.parse(label + directive + comment);
			assertThat("Instruction set: " + directive, directive, equalTo(lp.getDirective()));
		} // for
	}// testDirectives

}//class LineParserTestInstructionsAndDirectives
