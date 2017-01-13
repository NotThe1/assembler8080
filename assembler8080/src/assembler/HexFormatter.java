package assembler;

/**
 * 
 * @author Frank Martyn
 * 
 *         This is the Intel Hex format, the record (line) structure is :
 *         <p>
 *         1. Start code, one character, an ASCII colon ':'.
 *         <p>
 *         2. Byte count, two hex digits, indicating the number of bytes (hex digit pairs) in the data field. The
 *         maximum byte count is 255 (0xFF). 16 (0x10) and 32 (0x20) are commonly used byte counts.
 *         <p>
 *         3. Address, four hex digits, representing the 16-bit beginning memory address offset of the data. The
 *         physical address of the data is computed by adding this offset to a previously established base address, thus
 *         allowing memory addressing beyond the 64 kilobyte limit of 16-bit addresses. The base address, which defaults
 *         to zero, can be changed by various types of records. Base addresses and address offsets are always expressed
 *         as big endian values.
 *         <p>
 *         4.Record type (see record types below), two hex digits, 00 to 05, defining the meaning of the data field.
 *         <p>
 *         5.Data, a sequence of n bytes of data, represented by 2n hex digits. Some records omit this field (n equals
 *         zero). The meaning and interpretation of data bytes depends on the application.
 *         <p>
 *         6.Checksum, two hex digits, a computed value that can be used to verify the record has no errors.
 * 
 * 
 * 
 *         the data in the array does not have to be aligned on a 0XFFF0 boundary.
 * 
 */

public class HexFormatter implements IByteArrayToStringFormat {

	private byte[] source;
	private int baseAddress;
	private int sourceIndex = 0;
	private int sourceLength = 0;

	public HexFormatter(int baseAddress, byte[] source) {
		setBaseAddress(baseAddress);
		setSource(source);
		reset();
	}// Constructor

	@Override
	public void reset() {
		this.sourceIndex = 0; // reset the pointer
		this.sourceLength = this.source.length;
	}// reset
	
	@Override
	public boolean hasNext() {
		return sourceIndex < sourceLength;
	}// hasNext

	@Override
	public String getNext() {

		if (!this.hasNext()) {
			return EMPTY_STRING;
		} // if no more
		int checksum = 0;

		int byteCount = Math.min(SIXTEEN, sourceLength - sourceIndex);
		int address = baseAddress + sourceIndex;

		if ((address % SIXTEEN) != 0) {
			byteCount = Math.min(byteCount, SIXTEEN - (address % SIXTEEN));
		} // if
		StringBuilder sb = new StringBuilder(START_CODE);
		sb.append(String.format("%02X", byteCount));
		checksum += byteCount;
		sb.append(String.format("%04X", address));
		int hi = (address & 0XFF00) >> 8;
		int lo = address & 0X00FF;
		checksum += hi;
		checksum += lo;

		sb.append(String.format("%02X", RT_DATA));
		checksum += RT_DATA;

		for (int i = 0; i < byteCount; i++) {
			checksum += source[sourceIndex];
			sb.append(String.format("%02X", source[sourceIndex++]));
		} // for

		sb.append(String.format("%02X", (0 - checksum)& 0X00FF));
		return sb.toString();
		
	}// getNext

	public String getEOF() {
		return ":00000001FF";
	}// getEOF

	@Override
	public void setSource(byte[] source) {
		this.source = source;
	}// setSource

	@Override
	public void setBaseAddress(int baseAddress) {
		assert baseAddress >= 0 : "Hex Formatter: " + baseAddress + " is a bad address";
		this.baseAddress = baseAddress;

	}// setBaseAddress

	@Override
	public void setAddressWidth(int addressWidth) {
		// TODO Auto-generated method stub
	}// setAddressWidth


	private static final int SIXTEEN = 16; // 0X10

	private static final String EMPTY_STRING = "";

	private static final String START_CODE = ":"; // Colon
	private static final int RT_DATA = 0; // Record type - Data
	private static final int RT_EOF = 1; // Record type - End of File
	private static final int RT_ESA = 2; // Record type - Extended Segment Address
	private static final int RT_SSA = 3; // Record type - Start Segment Address
	private static final int RT_ELA = 4; // Record type - Extended Linear Address
	private static final int RT_SLA = 5; // Record type - Start Linear Address

}// class HexFormatter
