package assembler;

import java.util.HashMap;
import java.util.Set;

public class DirectiveSet {

	public static boolean isDirective(String token) {
		return (directives.containsKey(token));
	}// isDirective

	public static boolean isNameRequired(String name) {
		return directives.get(name).isNameRequired();
	}// isNameRequired

	public static int getMaxNumberOfArguments(String name) {
		return directives.get(name).getMaxNumberOfArguments();
	}// getMaxNumberOfArguments

	public static boolean doPassTwo(String name) {
		return directives.get(name).doPassTwo();
	}// doPassTwo

	public static String getName(String name) {
		return directives.get(name).getName();
	}// getName
	/*----------------------------------------------------- */

	public static String getRegex() {
		StringBuilder sb = new StringBuilder("\\b(?i)(");
		Set<String> dirs = getDirectiveSet();
		for (String dir : dirs) {
			sb.append(dir);
			sb.append("|");
		} // for
		sb.deleteCharAt(sb.length() - 1);
		sb.append(")\\b");
//		System.out.printf("[DirectiveSet.getRegex] sb: %s%n%n", sb.toString());
		;
		String regexExpression = sb.toString();
		regexExpression = regexExpression.replace("$", ""); //$include
		return regexExpression;
	}//getRegex
	
	public static Set<String> getDirectiveSet(){
		 return directives.keySet();
	}//getInstructionSet

	/*----------------------------------------------------- */

	private static HashMap<String, Directive> directives;
	static {
		directives = new HashMap<String, Directive>();
		directives.put("EQU", new Directive("EQU", true, 1, false));
		directives.put("SET", new Directive("SET", true, 1, false));
		directives.put("DB", new Directive("DB", false, 8, true));
		directives.put("DW", new Directive("DW", false, 8, true));
		directives.put("DS", new Directive("DS", false, 1, false));

		directives.put("IF", new Directive("IF", false, 1, false));
		directives.put("ELSE", new Directive("ELSE", false, 0, false));
		directives.put("ENDIF", new Directive("ENDIF", false, 0, false));

		directives.put("END", new Directive("END", false, 1, false));
		directives.put("EOT", new Directive("EOT", false, 0, false)); // obsolete

		directives.put("ORG", new Directive("ORG", false, 1, false));
		directives.put("ASEG", new Directive("ASEG", false, 0, false));
		directives.put("CSEG", new Directive("CSEG", false, 1, false)); // blank,PAGE,INPAGE
		directives.put("DSEG", new Directive("DSEG", false, 1, false)); // blank,PAGE,INPAGE

		directives.put("PUBLIC", new Directive("PUBLIC", false, 1, false)); // name-List
		directives.put("EXTRN", new Directive("EXTRN", false, 1, false)); // name-List
		directives.put("NAME", new Directive("NAME", false, 1, false)); // Name for the module

		directives.put("STKLN", new Directive("STKLN", false, 1, false)); // name-List

		directives.put("MACRO", new Directive("MACRO", true, 8, false));
		directives.put("ENDM", new Directive("ENDM", true, 0, false));
		directives.put("LOCAL", new Directive("LOCAL", true, 8, false)); // label-names
		directives.put("REPT", new Directive("REPT", true, 1, false));
		directives.put("IRP", new Directive("IRP", true, 1, false)); /* list of dummy parameters */
		directives.put("IRPC", new Directive("IRPC", true, 1, false)); // list
		directives.put("EXITM", new Directive("EXITM", true, 0, false));
		
		/* special case */
		directives.put("$INCLUDE", new Directive("$INCLUDE", true, 1, false));
	
	}// static

}// class DirectiveSet
