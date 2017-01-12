package assembler;

import javax.swing.JOptionPane;

/**
 * 
 * @author Frank Martyn
 *         <p>
 *         this class will format the supplied byte arrays into the "mem" format. It takes a base address ( starting at
 *         a multiple of 16), as well as a byte array ( it must have a length that is a multiple of 16). It format the
 *         output one line at a time. It defaults to displaying the ASCII representation as well as the hex for the
 *         values in the line.
 *         <p>
 *         an example output line: 0110: 21 46 01 7E 17 C2 00 01 FF 5F 16 00 21 48 01 19 !F.~....._..!H..
 * 
 *         <p>
 *         the ASCII component of the output is controlled by the showASCII flag.
 *
 */
public class MemFormatter implements IByteArrayToStringFormat {
	private byte[] source;
	private int baseAddress;
	private int sourceIndex;
	private int sourceLength;
	private boolean showASCII;
	private int addressWidth;
	private String formatForAddress;
	private boolean lineSeparator;

	private MemFormatter() {
		this(0X000, new byte[] { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 });
	}// Constructor

	private MemFormatter(int address, byte[] source) {
		setBaseAddress(address);
		setSource(source);
		reset();
	}// Constructor

	/**
	 * factory method to return memFormatter that has address width of 4, returns lines with ASCII and ends in a
	 * LineSeparator
	 * 
	 * @return default MemFormatter
	 */
	public static MemFormatter memFormatterFactory(int address, byte[] source) {
		MemFormatter memFormatter = new MemFormatter(address, source);
		memFormatter.setShowASCII(ASCII);
		memFormatter.setLineSeparator(LINE_SEPARATOR);
		memFormatter.setAddressWidth(DEFAULT_ADDRESS_WIDTH);
		return memFormatter;
	}// memFormatterFactory - Default with address & source

	public static MemFormatter memFormatterFactory() {
		MemFormatter memFormatter = new MemFormatter();
		memFormatter.setShowASCII(ASCII);
		memFormatter.setLineSeparator(LINE_SEPARATOR);
		memFormatter.setAddressWidth(DEFAULT_ADDRESS_WIDTH);
		return memFormatter;
	}// memFormatterFactory - Default

	public static MemFormatter memFormatterFactory(boolean ascii, boolean lineSeparator) {
		MemFormatter memFormatter = new MemFormatter();
		memFormatter.setShowASCII(ascii);
		memFormatter.setLineSeparator(lineSeparator);
		memFormatter.setAddressWidth(DEFAULT_ADDRESS_WIDTH);
		return memFormatter;
	}// memFormatterFactory - default Address Width

	public static MemFormatter memFormatterFactory(int addressWidth, boolean ascii, boolean lineSeparator) {
		MemFormatter memFormatter = new MemFormatter();
		memFormatter.setShowASCII(ascii);
		memFormatter.setLineSeparator(lineSeparator);
		memFormatter.setAddressWidth(addressWidth);
		return memFormatter;
	}// memFormatterFactory - no defaults

	@Override
	public boolean hasNext() {
		return sourceIndex < sourceLength;
	}// hasNext

	@Override
	public String getNext() {
		String eol = this.isLineSeparator() ? System.lineSeparator() : EMPTY_STRING;

		if (!this.hasNext()) {
			return EMPTY_STRING;
		}// if no more

		String asciiString = this.isShowASCII()?getASCII(sourceIndex):EMPTY_STRING;
		

		int currentAddress = baseAddress + sourceIndex;
		String line = String.format(formatForAddress + FORMAT_HEX_PART, currentAddress,
				source[sourceIndex++], source[sourceIndex++], source[sourceIndex++], source[sourceIndex++],
				source[sourceIndex++], source[sourceIndex++], source[sourceIndex++], source[sourceIndex++],
				source[sourceIndex++], source[sourceIndex++], source[sourceIndex++], source[sourceIndex++],
				source[sourceIndex++], source[sourceIndex++], source[sourceIndex++], source[sourceIndex++]
				);

		return line  + asciiString + eol;
	}// getNext

	private String getASCII(int start) {
		StringBuilder sb = new StringBuilder(ASCII_SEPARATOR);
		char c;
		for (int i = 0; i < SIXTEEN; i++) {
			c = (char) source[start + i];
			sb.append((c >= 0X20) && (c <= 0X7F) ? c : NON_PRINTABLE);
		}// for
		sb.toString();
		return sb.toString();
	}// getASCII

	@Override
	public void setSource(byte[] source) {
		if ((source.length % SIXTEEN) == 0 & source.length != 0) {
			this.source = source;
		} else {
			String msg = String.format("Mem Formatter: source array needs to be a multiple of 16 (0X10).%n"
					+ "This source size is %1$d (0X%1$X)", source.length);
			JOptionPane.showMessageDialog(null, msg, "Mem Formatter", JOptionPane.WARNING_MESSAGE);
			this.source = new byte[] { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };
		}// if
	}// setSource

	@Override
	public void setBaseAddress(int address) {
		assert address >= 0 : "Mem Formatter: " + address + " is a bad address";
		if ((address % SIXTEEN) == 0) {
			this.baseAddress = address;
		} else {
			String msg = String.format("Mem Formatter: %04X is a bad address%n It needs to end in 0 (Zero)", address);
			JOptionPane.showMessageDialog(null, msg, "Mem Formatter", JOptionPane.WARNING_MESSAGE);
			this.baseAddress = 0X0000; // set address to Zero
		}// if
	}// setBaseAddress

	@Override
	public void reset() {
		this.sourceIndex = 0; // reset the pointer
		this.sourceLength = this.source.length;
		this.showASCII = true;
		setAddressWidth(4);
	}// reset

	@Override
	public void setAddressWidth(int addressWidth) {
		this.addressWidth = addressWidth;
		formatForAddress = "%0" + this.addressWidth + "X: ";
	}// setAddressWidth

	/**
	 * set flag for output to also show ASCII at end of text line
	 * 
	 * @param state
	 *            true to show ASCII, false to not show ASCII
	 */

	public void setShowASCII(boolean state) {
		this.showASCII = state;
	}// setShowASCII

	/**
	 * returns the state of the flag that controls the appending of ASCII text at the end of output line
	 * 
	 * @return True if output will append ASCII code at end of line, false if not
	 */

	public boolean isShowASCII() {
		return this.showASCII;
	}// isShowASCII

	public void setLineSeparator(boolean state) {
		this.lineSeparator = state;
	}// setLineSeparator

	/**
	 * returns the state of the flag that controls the appending of a line separator at the end of output line
	 * 
	 * @return True if output will append a line separato at end of line, false if not
	 */

	public boolean isLineSeparator() {
		return this.lineSeparator;
	}// isLineSeparator

	/*                                                         */
	private static final String FORMAT_HEX_PART = "%02X %02X %02X %02X %02X %02X %02X %02X  %02X %02X %02X %02X %02X %02X %02X %02X";
	// private static final String FORMAT_ASCII_PART;

	private static final int SIXTEEN = 16; // 0X10
	private static final String EMPTY_STRING = "";
	private static final String NON_PRINTABLE = "."; // Period
	private static final String ASCII_SEPARATOR = "  "; // Two spaces
	public static final boolean NO_ASCII = false;
	public static final boolean ASCII = true;

	public static final boolean NO_LINE_SEPARATOR = false;
	public static final boolean LINE_SEPARATOR = true;

	private static final int DEFAULT_ADDRESS_WIDTH = 4; // 0X10

}// class MemFormatter
