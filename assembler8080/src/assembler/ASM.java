package assembler;

import java.awt.Color;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.EventQueue;
import java.awt.Font;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.Point;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.AdjustmentEvent;
import java.awt.event.AdjustmentListener;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.awt.print.PrinterException;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.LinkedList;
import java.util.List;
import java.util.Scanner;
import java.util.prefs.Preferences;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import javax.swing.JButton;
import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;
import javax.swing.JPanel;
import javax.swing.JRadioButton;
import javax.swing.JScrollBar;
import javax.swing.JScrollPane;
import javax.swing.JSeparator;
import javax.swing.JSplitPane;
import javax.swing.JTextPane;
import javax.swing.SwingConstants;
import javax.swing.border.BevelBorder;
import javax.swing.text.BadLocationException;
import javax.swing.text.SimpleAttributeSet;
import javax.swing.text.StyleConstants;
import javax.swing.text.StyledDocument;

import parser.EvaluationException;
import parser.ExpressionNode;
import parser.Parser;
import parser.ParserException;
import parser.SetVariable;
import parser.Token;
import parser.Tokenizer;
import stuff.MyFileChooser;

public class ASM {

	private AdapterForASM adapterForASM = new AdapterForASM();
	private InstructionCounter instructionCounter = new InstructionCounter();
	private SymbolTable symbolTable = new SymbolTable(instructionCounter);
	private Parser parser = new Parser();
	private Tokenizer tokenizer = new Tokenizer();

	private String defaultDirectory;
	private File asmSourceFile = null;
	private StyledDocument docSource;
	private StyledDocument docListing;
	private JScrollBar sbarSource;
	private JScrollBar sbarListing;

	private SimpleAttributeSet attrBlue = new SimpleAttributeSet();
	private SimpleAttributeSet attrGreen = new SimpleAttributeSet();
	private SimpleAttributeSet attrOrange = new SimpleAttributeSet();
	private SimpleAttributeSet attrBlack = new SimpleAttributeSet();
	private SimpleAttributeSet attrGray = new SimpleAttributeSet();

	private boolean isEmptyLine;
	private String symbol;
	private Directive directive;
	private Instruction instruction;
	private String arguments;
	private String comment;

	// private int currentPC;

	/* ---------------------------------------------------------------------------------- */
	private void openFile() {
		JFileChooser chooserOpen = MyFileChooser.getFilePicker(defaultDirectory, "Assembler Source Code",
				SUFFIX_ASSEMBLER);
		if (chooserOpen.showOpenDialog(null) != JFileChooser.APPROVE_OPTION) {
			System.out.printf("You cancelled the file open%n", "");
		} else {
			// txtSource.setText("");
			// txtListing.setText("");
			asmSourceFile = chooserOpen.getSelectedFile();
			String[] nameParts = (asmSourceFile.getName()).split("\\.");
			String sourceFileBase = nameParts[0];
			lblSourceFilePath.setText(asmSourceFile.getAbsolutePath());
			lblSourceFileName.setText(asmSourceFile.getName());
			lblListingFileName.setText(sourceFileBase + "." + SUFFIX_LISTING);
			defaultDirectory = asmSourceFile.getParent();
			// lblSource.setText(sourceFileName);
			// lblListing.setText(replaceWithListingFileName(sourceFileName));
			clearDoc(docSource);
			clearDoc(docListing);
			loadSourceFile(asmSourceFile, 1, null);
			tpSource.setCaretPosition(0);
			btnStart.setEnabled(true);
		} // if
	}//

	private void start() {
		instructionCounter.reset();
		symbolTable.reset();
		if (asmSourceFile != null) {
			clearDoc(docSource);
			clearDoc(docListing);

			loadSourceFile(asmSourceFile, 1, null);
			passOne();

			showSymbolTable();
			// passTwo(asmSourceFile);
			// // passOne(asmSourceFile);
			// // passTwo(asmSourceFile);
		} // if

	}// start

	private void showSymbolTable() {
		List<String> symbols = symbolTable.getAllSymbols();
		for (String symbol : symbols) {
			System.out.printf("[showSymbolTable]   %-10s %04d %X\t %s%n", symbol,
					symbolTable.getEntry(symbol).getDefinedLineNumber(), symbolTable.getValue(symbol),
					symbolTable.getTypeName(symbol));
		} // for
	}//

	private void clearDoc(StyledDocument doc) {
		try {
			doc.remove(0, doc.getLength());
		} catch (BadLocationException e) {
			// Auto-generated catch block
			e.printStackTrace();
		} // try
	}// clearDoc

	public int loadSourceFile(File sourceFile, int lineNumber, SimpleAttributeSet attr) {
		try {
			FileReader source = new FileReader(sourceFile);
			BufferedReader reader = new BufferedReader(source);
			String line = null;
			String rawLine = null;
			String outputLine;
			Matcher matcherInclude;
			Pattern patternForInclude = Pattern.compile("\\$INCLUDE ", Pattern.CASE_INSENSITIVE);
			while ((rawLine = reader.readLine()) != null) {
				// // line = rawLine.toUpperCase();
				line = rawLine;
				outputLine = String.format("%04d %s%n", lineNumber++, line);

				insertSource(outputLine, attr);
				// txtSource.append(outputLine);
				matcherInclude = patternForInclude.matcher(line);

				if (matcherInclude.find()) {
					String fileReference = line.substring(matcherInclude.end(), line.length());
					lineNumber = doInclude(fileReference, sourceFile.getParentFile().getAbsolutePath(), lineNumber);
				} // if
			} // while
			reader.close();
		} catch (IOException e) {
			e.printStackTrace();
		} // TRY
		return lineNumber;
	}// passZero

	public int doInclude(String fileReference, String parentDirectory, int lineNumber) {
		if (!fileReference.contains("\\")) {
			fileReference = parentDirectory + System.getProperty("file.separator") + fileReference;
		} //

		if (!(fileReference.toUpperCase().endsWith(SUFFIX_ASSEMBLER.toUpperCase()))) {
			fileReference += "." + SUFFIX_ASSEMBLER;
		} //

		String includeMarker = ";<<<<<<<<<<<<<<<<<<<<<<< Include >>>>>>>>>>>>>>>>";
		insertSource(String.format("%04d %s%n", lineNumber++, includeMarker), attrBlue);

		File includedFile = new File(fileReference);
		lineNumber = loadSourceFile(includedFile, lineNumber, attrBlue);

		insertSource(String.format("%04d %s%n", lineNumber++, includeMarker), attrBlue);
		//
		return lineNumber;
	}// doInclude

	private void insertSource(String str, SimpleAttributeSet attr) {
		try {
			docSource.insertString(docSource.getLength(), str, attr);
		} catch (BadLocationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} // try
	}// insertSource

	private void insertListing(String str, SimpleAttributeSet attr) {
		try {
			// docListing.
			docListing.insertString(docListing.getLength(), str, attr);
		} catch (BadLocationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} // try
	}// insertSource

	/* .................................................................................. */

	/**
	 * passOne sets up the symbol table with initial value for Labels & symbols
	 */
	public void passOne() {
		boolean emptyLine = true;
		int lineNumber;
		String sourceLine;
		LineParser lineParser = new LineParser();
		Scanner scannerPassOne = new Scanner(tpSource.getText());

		while (scannerPassOne.hasNextLine()) {
			sourceLine = scannerPassOne.nextLine();
			if (sourceLine.equals(EMPTY_STRING)) {
				continue;
			} // if skip textbox's empty lines

			if (!lineParser.parse(sourceLine)) {
				continue;
			} // if skip textbox's empty lines

			lineNumber = lineParser.getLineNumber();

			// ***** parseLine(lineNumber, line.substring(matcher.end(), line.length()));
			// insertListing(lineParser.getLineNumberStr() + "\t" + lineNumber + LINE_SEPARATOR);
			if (lineParser.hasLabel()) {
				processLabel(lineParser, lineNumber);
			} // if - has label
			if (lineParser.hasInstruction()) {
				instructionCounter.incrementCurrentLocation(lineParser.getOpCodeSize());
			} // if instruction
			if (lineParser.hasDirective()) {
				processDirective(lineParser, lineNumber);
			}
			if (lineParser.hasSymbol()) {
				processSymbol(lineParser, lineNumber);
			} // if has symbol
			displayStuff(lineParser);
		} // while

		SymbolTable.passOneDone();
		instructionCounter.reset();
		tpListing.setCaretPosition(0);
		scannerPassOne.close();
	}// passOne

	private void processDirective(LineParser lp, int lineNumber) {
		String directive = lp.getDirective();
		String arguments = lp.getArgument();
		String errorMsg = String.format("Directive %s on line: %04d not yet implemented", directive, lineNumber);
		Scanner scannerComma;
		switch (directive.toUpperCase()) {
		case "DB":
			if (arguments != null) {
				String arg;
				scannerComma = new Scanner(arguments);
				scannerComma.useDelimiter(COMMA);
				while (scannerComma.hasNext()) {
					arg = scannerComma.next();
					if (arg.matches(stringValuePattern)) {
						arg.replace("'", "");
						instructionCounter.incrementCurrentLocation(arg.length());
					} else {
						instructionCounter.incrementCurrentLocation();
					} // if
				} // while
			} else {
				throw new AssemblerException("Directive DB on line: " + lineNumber + " needs an argument");
			} // if
			break;
		case "DW":
			if (arguments != null) {
				scannerComma = new Scanner(arguments);
				scannerComma.useDelimiter(COMMA);
				while (scannerComma.hasNext()) {
					instructionCounter.incrementCurrentLocation(2);
				} // while
			} else {
				throw new AssemblerException("Directive DW on line: " + lineNumber + " needs an argument");
			} // if
			break;
		case "DS":
			int storage = resolveSimpleArgument(arguments, lineNumber);
			instructionCounter.incrementCurrentLocation(storage);
			break;
		case "ORG":
			Integer loc = resolveSimpleArgument(arguments, lineNumber);
			if (loc != null) {
				instructionCounter.setCurrentLocation(loc);
				instructionCounter.setPriorLocation();
			} // if
			break;
		case "ASEG":
			if (arguments == null) {
				instructionCounter.makeCurrent(InstructionCounter.ASEG);
			} else {
				instructionCounter.makeCurrent(InstructionCounter.ASEG, arguments);
			} // if
			break;
		case "DSEG":
			if (arguments == null) {
				instructionCounter.makeCurrent(InstructionCounter.DSEG);
			} else {
				instructionCounter.makeCurrent(InstructionCounter.DSEG, arguments);
			} // if
			break;
		case "CSEG":
			if (arguments == null) {
				instructionCounter.makeCurrent(InstructionCounter.CSEG);
			} else {
				instructionCounter.makeCurrent(InstructionCounter.CSEG, arguments);
			} // if
			break;
		case "IF":
			throw new AssemblerException(errorMsg);
		//	break;
		case "ELSE":
			throw new AssemblerException(errorMsg);
		//	break;
		case "ENDIF":
			throw new AssemblerException(errorMsg);
		//	break;
		case "END":
		//	throw new AssemblerException(errorMsg);
			
			break;
		case "PUBLIC":
			throw new AssemblerException(errorMsg);
		//	break;
		case "EXTRN":
			throw new AssemblerException(errorMsg);
		//	break;
		case "NAME":
			throw new AssemblerException(errorMsg);
		//	break;
		case "STKLN":
			throw new AssemblerException(errorMsg);
		//	break;
		case "TITLE":
			break;
		default:
			// ignore
		}// switch directive

	}// processDirective

	private void processSymbol(LineParser lp, int lineNumber) {
		if (!lp.hasDirective()) {
			return; // symbol defintion needs to be on a directive line
		} // if have a Directive?
		String symbol = lp.getSymbol();

		switch (lp.getDirective().toUpperCase()) {
		case "EQU":
			int value = resolveSimpleArgument(lp.getArgument(), lineNumber);
			symbolTable.defineSymbol(symbol, value, lineNumber, SymbolTable.NAME);
			break;
		case "SET":
		case "MACRO":
		case "$INCLUDE":
			// ok let it go
			break;
		default:
			System.out.printf("** Check line number %d directive is = %n", lineNumber, lp.getDirective());
			// look out for Include
		}// switch

	}// processSymbol

	private void processLabel(LineParser lp, int lineNumber) {
		String label = lp.getLabel().replace(":", EMPTY_STRING);
		symbolTable.defineSymbol(label, instructionCounter.getCurrentLocation(), lineNumber, SymbolTable.LABEL);
	}// processSymbol

	private void displayStuff(LineParser lp) {
		int lineNumber = lp.getLineNumber();
		String msg = String.format("%04d  ", lineNumber);
		insertListing(msg, attrGray);

		/* if the line is only a comment */
		if (lp.isOnlyComment()) {
			insertListing(lp.getComment() + LINE_SEPARATOR, attrGreen);
			return;
		} // if only comment

		String labelOrSymbol = null;
		;
		if (lp.hasLabel()) {
			labelOrSymbol = lp.getLabel() + ":";
		} else if (lp.hasSymbol()) {
			labelOrSymbol = lp.getSymbol();
		} else {
			labelOrSymbol = EMPTY_STRING;
		} // if Label Or Symbol
		msg = String.format("%-10s ", labelOrSymbol);
		insertListing(msg, attrBlack);

		String insOrDir = null;
		if (lp.hasInstruction()) {
			insOrDir = lp.getInstruction();
		} else if (lp.hasDirective()) {
			insOrDir = lp.getDirective();
		} else {
			insOrDir = EMPTY_STRING;
		} // if Label Or Symbol
		msg = String.format("%-4s ", insOrDir);
		insertListing(msg, attrBlue);

		String arguments = lp.hasArgument() ? lp.getArgument() : EMPTY_STRING;
		msg = String.format("%-15s ", arguments);
		insertListing(msg, attrBlack);

		if (lp.hasComment()) {
			insertListing(lp.getComment(), attrGreen);
		} // if comments

		insertListing(LINE_SEPARATOR, null);

	}// displayStuff

	private void parseLine(LineParser lp) {
		int currentPC = instructionCounter.getCurrentLocation();
		// comment
	}

	private void parseLine(int lineNumber, String sourceLine) {
		// int currentPC = instructionCounter.getCurrentLocation();
		// clearElements();
		// if (workingLine.length() == 0) {// do nothing on an empty line
		// isEmptyLine = true;
		// return;
		// } // if - empty source line
		//
		// workingLine = checkForComment(workingLine); // check for Comment
		//
		// // comments have been removed from the working line
		//
		// if (workingLine.length() == 0) {
		// return; // all done! the whole line was a comment
		// } // if
		/* =================================== */
		// workingLine = checkForInstruction(workingLine);
		// if (instruction == null) {
		// workingLine = checkForDirective(workingLine, lineNumber);
		// }//
		//
		// if (workingLine.length() == 0) {
		// return; // all done!
		// }// if
		//
		// // must be a label/name at begging of line
		// workingLine = checkForSymbol(workingLine, lineNumber);
		//
		// if (workingLine.length() == 0) {
		// return; // all done!
		// }// if
		//
		// workingLine = checkForDirective(workingLine, lineNumber);
		// if (directive == null) {
		// workingLine = checkForInstruction(workingLine);
		// }//

	}// parseLine

	private void clearElements() {
		isEmptyLine = false; // ?
		symbol = null;
		// isInstruction = false; // ?
		directive = null;
		instruction = null;
		arguments = null;
		comment = null;
	}// clearElements

	private String checkForComment(String lineToCheck) {
		Pattern patternForComments = Pattern.compile(";.*");

		Matcher matcher = patternForComments.matcher(lineToCheck);
		if (matcher.find()) {// looks like a comment
			comment = matcher.group();
			if (comment.contains("'")) {// is there a single quote here?
				if (lineToCheck.substring(0, matcher.start()).contains("'")) {
					comment = null;
				} // its all inside a string
			} // if single quote fund
			lineToCheck = lineToCheck.substring(0, matcher.start()).trim();
		} // if comments found
		return lineToCheck.trim();
	}// checkForComment

	/* ---------------------------------------------------------------------------------- */
	/* ---------------------------------------------------------------------------------- */

	private Integer resolveSimpleArgument(String argument, Integer lineNumber) {
		// Integer ans = null;
		Integer ans = 0;
		if (argument.equals("$")) {
			ans = instructionCounter.getCurrentLocation();
		} else if (symbolTable.contains(argument)) {
			ans = symbolTable.getValue(argument);
			symbolTable.referenceSymbol(argument, lineNumber);
		} else if (argument.matches(stringValuePattern)) {
			// ans = 0;
			String s = argument.replace("'", ""); // remove the 's
			byte[] ba = s.getBytes();
			for (byte b : ba) {
				ans = (ans << 8) + (b & 0XFF);
			} //

		} else if (argument.matches(hexValuePattern)) {
			ans = Integer.valueOf(argument.replace("H", ""), 16);
		} else if (argument.matches(octalValuePattern)) {
			ans = Integer.valueOf(argument.substring(0, argument.length() - 1), 8);
		} else if (argument.matches(decimalValuePattern)) {
			ans = Integer.valueOf(argument.replace("D", ""), 10);
		} else if (argument.matches(binaryValuePattern)) {
			ans = Integer.valueOf(argument.replace("D", ""), 2);

		} else {// send to expression resolver
			ans = resolveExpression(argument, lineNumber);
		}
		if (ans == null) {
			System.out.printf("Null ans from argument: %s%n", argument);
		}

		return (ans != null) ? ans & 0XFFFF : 0; // max value is 64K
	}// resolveSimpleArgument

	private Integer resolveExpression(String arguments, Integer lineNumber) {
		Integer answer = null;
		try {
			tokenizer.tokenize(arguments);
			ExpressionNode expression = parser.parse(tokenizer.getTokens());
			LinkedList<Token> tokens = tokenizer.getTokens();

			for (Token t : tokens) {
				if (t.token == Token.VARIABLE) {
					int value = symbolTable.getValue(t.sequence);
					symbolTable.referenceSymbol(t.sequence, lineNumber);

					expression.accept(new SetVariable(t.sequence, value));
				} // if - its a variable
			}
			answer = expression.getValue();
		} catch (ParserException pe) {
			System.err.println(pe.getMessage());
			throw new AssemblerException("bad Expression: " + arguments);
		} catch (EvaluationException ee) {
			System.err.println(ee.getMessage());
			throw new AssemblerException("bad Expression: " + arguments);
		} // try
		return answer;
	}// resolveExpression

	/* ---------------------------------------------------------------------------------- */
	/* ---------------------------------------------------------------------------------- */

	private void printListing() {

		try {
			tpListing.print();

		} catch (PrinterException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}// printListing
	/* ---------------------------------------------------------------------------------- */
	/* ---------------------------------------------------------------------------------- */

	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					ASM window = new ASM();
					window.frmAsmAssembler.setVisible(true);
				} catch (Exception e) {
					e.printStackTrace();
				} // try
			}// run
		});
	}// main

	private void appClose() {
		Preferences myPrefs = Preferences.userNodeForPackage(ASM.class);
		Dimension dim = frmAsmAssembler.getSize();
		myPrefs.putInt("Height", dim.height);
		myPrefs.putInt("Width", dim.width);
		Point point = frmAsmAssembler.getLocation();
		myPrefs.putInt("LocX", point.x);
		myPrefs.putInt("LocY", point.y);
		myPrefs.putInt("Divider", splitPane.getDividerLocation());

		myPrefs.put("defaultDirectory", defaultDirectory);
		myPrefs = null;

		// cleanUp

		System.exit(0);
	}// appClose

	private void appInit() {
		Preferences myPrefs = Preferences.userNodeForPackage(ASM.class);
		frmAsmAssembler.setLocation(myPrefs.getInt("LocX", 100), myPrefs.getInt("LocY", 100));
		frmAsmAssembler.setSize(myPrefs.getInt("Width", 700), myPrefs.getInt("Height", 600));
		splitPane.setDividerLocation(myPrefs.getInt("Divider", 200));
		defaultDirectory = myPrefs.get("defaultDirectory", DEFAULT_DIRECTORY);
		myPrefs = null;

		// symbolTable = new SymbolTable(instructionCounter);
		docSource = tpSource.getStyledDocument();
		sbarSource = spSource.getVerticalScrollBar();
		sbarSource.setName(SBAR_SOURCE);
		sbarSource.addAdjustmentListener(adapterForASM);

		docListing = tpListing.getStyledDocument();
		sbarListing = spListing.getVerticalScrollBar();
		sbarListing.setName(SBAR_LISTING);
		sbarListing.addAdjustmentListener(adapterForASM);

		setAttributes();
	}// appInit

	private void setAttributes() {
		StyleConstants.setForeground(attrBlue, Color.blue);
		StyleConstants.setForeground(attrGreen, Color.GREEN);
		StyleConstants.setForeground(attrGray, Color.GRAY);
		StyleConstants.setForeground(attrOrange, Color.ORANGE);
		StyleConstants.setForeground(attrBlack, Color.BLACK);
	}// setAttributes

	/**
	 * Create the application.
	 */
	public ASM() {
		initialize();
		appInit();
	}// Constructor

	/**
	 * Initialize the contents of the frame.
	 */
	private void initialize() {
		frmAsmAssembler = new JFrame();
		frmAsmAssembler.addWindowListener(new WindowAdapter() {
			@Override
			public void windowClosing(WindowEvent arg0) {
				appClose();
			}
		});
		frmAsmAssembler.setTitle("ASM - assembler for Intel 8080");
		frmAsmAssembler.setBounds(100, 100, 662, 541);
		frmAsmAssembler.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		GridBagLayout gridBagLayout = new GridBagLayout();
		gridBagLayout.columnWidths = new int[] { 0, 0 };
		gridBagLayout.rowHeights = new int[] { 0, 30, 0 };
		gridBagLayout.columnWeights = new double[] { 1.0, Double.MIN_VALUE };
		gridBagLayout.rowWeights = new double[] { 1.0, 0.0, Double.MIN_VALUE };
		frmAsmAssembler.getContentPane().setLayout(gridBagLayout);

		JPanel panelTop = new JPanel();
		GridBagConstraints gbc_panelTop = new GridBagConstraints();
		gbc_panelTop.insets = new Insets(0, 0, 5, 0);
		gbc_panelTop.fill = GridBagConstraints.BOTH;
		gbc_panelTop.gridx = 0;
		gbc_panelTop.gridy = 0;
		frmAsmAssembler.getContentPane().add(panelTop, gbc_panelTop);
		GridBagLayout gbl_panelTop = new GridBagLayout();
		gbl_panelTop.columnWidths = new int[] { 0, 0 };
		gbl_panelTop.rowHeights = new int[] { 0, 0, 0 };
		gbl_panelTop.columnWeights = new double[] { 1.0, Double.MIN_VALUE };
		gbl_panelTop.rowWeights = new double[] { 0.0, 1.0, Double.MIN_VALUE };
		panelTop.setLayout(gbl_panelTop);

		lblSourceFilePath = new JLabel(NO_FILE);
		GridBagConstraints gbc_lblSourceFilePath = new GridBagConstraints();
		gbc_lblSourceFilePath.insets = new Insets(0, 0, 5, 0);
		gbc_lblSourceFilePath.anchor = GridBagConstraints.NORTH;
		gbc_lblSourceFilePath.gridx = 0;
		gbc_lblSourceFilePath.gridy = 0;
		panelTop.add(lblSourceFilePath, gbc_lblSourceFilePath);

		JPanel panelMain = new JPanel();
		GridBagConstraints gbc_panelMain = new GridBagConstraints();
		gbc_panelMain.fill = GridBagConstraints.BOTH;
		gbc_panelMain.gridx = 0;
		gbc_panelMain.gridy = 1;
		panelTop.add(panelMain, gbc_panelMain);
		GridBagLayout gbl_panelMain = new GridBagLayout();
		gbl_panelMain.columnWidths = new int[] { 80, 0, 0 };
		gbl_panelMain.rowHeights = new int[] { 0, 0 };
		gbl_panelMain.columnWeights = new double[] { 0.0, 1.0, Double.MIN_VALUE };
		gbl_panelMain.rowWeights = new double[] { 1.0, Double.MIN_VALUE };
		panelMain.setLayout(gbl_panelMain);

		JPanel panelLeft = new JPanel();
		GridBagConstraints gbc_panelLeft = new GridBagConstraints();
		gbc_panelLeft.insets = new Insets(0, 0, 0, 5);
		gbc_panelLeft.fill = GridBagConstraints.VERTICAL;
		gbc_panelLeft.gridx = 0;
		gbc_panelLeft.gridy = 0;
		panelMain.add(panelLeft, gbc_panelLeft);
		GridBagLayout gbl_panelLeft = new GridBagLayout();
		gbl_panelLeft.columnWidths = new int[] { 0, 0, 0 };
		gbl_panelLeft.rowHeights = new int[] { 0, 0, 0, 0 };
		gbl_panelLeft.columnWeights = new double[] { 0.0, 1.0, Double.MIN_VALUE };
		gbl_panelLeft.rowWeights = new double[] { 0.0, 0.0, 0.0, Double.MIN_VALUE };
		panelLeft.setLayout(gbl_panelLeft);

		btnStart = new JButton("Start");
		btnStart.setEnabled(false);
		btnStart.setName(START_BUTTON);
		btnStart.addActionListener(adapterForASM);
		GridBagConstraints gbc_btnStart = new GridBagConstraints();
		gbc_btnStart.insets = new Insets(0, 0, 5, 5);
		gbc_btnStart.anchor = GridBagConstraints.NORTH;
		gbc_btnStart.gridx = 0;
		gbc_btnStart.gridy = 0;
		panelLeft.add(btnStart, gbc_btnStart);

		rbSave = new JRadioButton("Save");
		rbSave.setSelected(true);
		GridBagConstraints gbc_rbSave = new GridBagConstraints();
		gbc_rbSave.insets = new Insets(0, 0, 0, 5);
		gbc_rbSave.gridx = 0;
		gbc_rbSave.gridy = 2;
		panelLeft.add(rbSave, gbc_rbSave);

		splitPane = new JSplitPane();
		GridBagConstraints gbc_splitPane = new GridBagConstraints();
		gbc_splitPane.fill = GridBagConstraints.BOTH;
		gbc_splitPane.gridx = 1;
		gbc_splitPane.gridy = 0;
		panelMain.add(splitPane, gbc_splitPane);

		spSource = new JScrollPane();
		splitPane.setLeftComponent(spSource);

		lblSourceFileName = new JLabel(NO_FILE);
		lblSourceFileName.setForeground(Color.BLUE);
		lblSourceFileName.setFont(new Font("Tahoma", Font.PLAIN, 15));
		lblSourceFileName.setHorizontalAlignment(SwingConstants.CENTER);
		spSource.setColumnHeaderView(lblSourceFileName);

		tpSource = new JTextPane();
		tpSource.setFont(new Font("Courier New", Font.PLAIN, 14));
		spSource.setViewportView(tpSource);

		spListing = new JScrollPane();
		splitPane.setRightComponent(spListing);

		lblListingFileName = new JLabel(NO_FILE);
		lblListingFileName.setHorizontalAlignment(SwingConstants.CENTER);
		lblListingFileName.setForeground(Color.BLUE);
		lblListingFileName.setFont(new Font("Tahoma", Font.PLAIN, 15));
		spListing.setColumnHeaderView(lblListingFileName);

		tpListing = new JTextPane();
		tpListing.setFont(new Font("Courier New", Font.PLAIN, 14));
		spListing.setViewportView(tpListing);

		panelStatus = new JPanel();
		panelStatus.setBorder(new BevelBorder(BevelBorder.LOWERED, null, null, null, null));
		GridBagConstraints gbc_panelStatus = new GridBagConstraints();
		gbc_panelStatus.fill = GridBagConstraints.BOTH;
		gbc_panelStatus.gridx = 0;
		gbc_panelStatus.gridy = 1;
		frmAsmAssembler.getContentPane().add(panelStatus, gbc_panelStatus);
		GridBagLayout gbl_panelStatus = new GridBagLayout();
		gbl_panelStatus.columnWidths = new int[] { 0 };
		gbl_panelStatus.rowHeights = new int[] { 0 };
		gbl_panelStatus.columnWeights = new double[] { Double.MIN_VALUE };
		gbl_panelStatus.rowWeights = new double[] { Double.MIN_VALUE };
		panelStatus.setLayout(gbl_panelStatus);

		menuBar = new JMenuBar();
		frmAsmAssembler.setJMenuBar(menuBar);

		JMenu mnuFile = new JMenu("File");
		menuBar.add(mnuFile);

		JMenuItem mnuFileOpen = new JMenuItem("Open File");
		mnuFileOpen.setName(MNU_FILE_OPEN);
		mnuFileOpen.addActionListener(adapterForASM);
		mnuFile.add(mnuFileOpen);

		separator = new JSeparator();
		mnuFile.add(separator);

		JMenuItem mnuFilePrintSource = new JMenuItem("Print Source");
		mnuFilePrintSource.setName(MNU_FILE_PRINT_SOURCE);
		mnuFilePrintSource.addActionListener(adapterForASM);
		mnuFile.add(mnuFilePrintSource);

		JMenuItem mnuFilePrintListing = new JMenuItem("Print Listing");
		mnuFilePrintListing.setName(MNU_FILE_PRINT_LISTING);
		mnuFilePrintListing.addActionListener(adapterForASM);
		mnuFile.add(mnuFilePrintListing);

		separator_1 = new JSeparator();
		mnuFile.add(separator_1);

		JMenuItem mnuFileExit = new JMenuItem("Exit");
		mnuFileExit.setName(MNU_FILE_EXIT);
		mnuFileExit.addActionListener(adapterForASM);
		mnuFile.add(mnuFileExit);
	}// initialize
		// ---------------------------------------------------------------------

	class AdapterForASM implements ActionListener, AdjustmentListener {

		/* ActionListener */
		@Override
		public void actionPerformed(ActionEvent actionEvent) {
			String name = ((Component) actionEvent.getSource()).getName();
			switch (name) {
			// menu
			case MNU_FILE_OPEN:
				openFile();
				break;
			case MNU_FILE_PRINT_SOURCE:
				break;
			case MNU_FILE_PRINT_LISTING:
				printListing();
				break;
			case MNU_FILE_EXIT:
				appClose();
				break;

			// buttons
			case START_BUTTON:
				start();
				break;
			default:
			}// switch

		}// actionPerformed

		/* AdjustmentListener */

		@Override
		public void adjustmentValueChanged(AdjustmentEvent adjustmentEvent) {
			if (adjustmentEvent.getSource() instanceof JScrollBar) {
				int value = ((JScrollBar) adjustmentEvent.getSource()).getValue();
				sbarSource.setValue(value);
				sbarListing.setValue(value);
			} // if scroll bar

		}// adjustmentValueChanged

	}// class AdapterForASM
		// ---------------------------------------------------------------------

	private JScrollPane spSource;
	private JScrollPane spListing;
	private JSplitPane splitPane;
	private JLabel lblSourceFileName;
	private JLabel lblListingFileName;
	private JPanel panelStatus;
	private JFrame frmAsmAssembler;
	private JRadioButton rbSave;

	private JMenuBar menuBar;
	private JSeparator separator;
	private JSeparator separator_1;

	// private static final String ASSEMBLE = "Assemble";
	// private static final String RE_ASSEMBLE = "Reassemble";

	private static final String START_BUTTON = "btnStart";
	private static final String NO_FILE = "<No File Selected>";
	private static final String MNU_FILE_OPEN = "mnuFileOpen";
	private static final String MNU_FILE_PRINT_SOURCE = "mnuFilePrintSource";
	private static final String MNU_FILE_PRINT_LISTING = "mnuFilePrintListing";
	private static final String MNU_FILE_EXIT = "mnuFileExit";
	private static final String SBAR_SOURCE = "sbarSource";
	private static final String SBAR_LISTING = "sbarListing";

	private static final String LINE_SEPARATOR = System.lineSeparator();
	private static final String FILE_SEPARATOR = File.separator;
	private static final String DEFAULT_DIRECTORY = "." + FILE_SEPARATOR + "Code" + FILE_SEPARATOR + ".";
	private final static String SUFFIX_ASSEMBLER = "asm";
	private final static String SUFFIX_LISTING = "list";
	private final static String SUFFIX_MEMORY = "mem";

	private static final String EMPTY_STRING = ""; // empty string
	private static final String COMMA = ","; // Comma ,

	private static final String hexValuePattern = "[0-9][0-9A-Fa-f]{0,4}H";
	private static final String octalValuePattern = "[0-7]+[O|Q]";
	private static final String binaryValuePattern = "[01]B";
	private static final String decimalValuePattern = "[0-9]{1,4}D?+";
	private static final String stringValuePattern = "\\A'.*'\\z"; // used for

	private JLabel lblSourceFilePath;
	private JButton btnStart;
	private JTextPane tpSource;
	private JTextPane tpListing;

	// private static final String

}// class ASM
