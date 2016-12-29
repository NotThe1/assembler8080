package test;

import org.junit.Test;

import assembler.DirectiveSet;

public class TestTest {

	@Test
	public void test() {
		DirectiveSet sd = new DirectiveSet();
		String reg = sd.getRegex();
		System.out.println(reg);
	}

}
