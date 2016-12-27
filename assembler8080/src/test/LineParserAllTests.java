package test;

import org.junit.runner.RunWith;
import org.junit.runners.Suite;
import org.junit.runners.Suite.SuiteClasses;

@RunWith(Suite.class)
@SuiteClasses({ LineParserTestArgInfo.class, LineParsertestCommentsAndMT.class,
		LineParserTestInstructionsAndDirectives.class, LineParserTestSimpleStuff.class })
public class LineParserAllTests {

}
