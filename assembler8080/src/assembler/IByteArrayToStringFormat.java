package assembler;

/**
 * 
 * @author Frank Martyn this interface is for formatting a byte array to a predetermined text representation of the
 *         array
 */

public interface IByteArrayToStringFormat {
	/**
	 * used to determine if there is any more values to be processed
	 * 
	 * @return true if there is more, false if there is no more
	 */

	public boolean hasNext();

	/**
	 * formats the next line of text
	 * 
	 * @return a String that has a text representation of the next byte values
	 */
	public String getNext();

	/**
	 * used to provide the byte array to be formatted
	 * 
	 * @param source
	 *            the array to be formatted
	 */

	public void setSource(byte[] source);

	/**
	 * use to set the base address of the array to be formatted
	 * 
	 * @param address
	 *            the base address of the array, must be a multiple of 16 (0X10)
	 */
	public void setBaseAddress(int baseAddress);

	/**
	 * resets all the internal counters. The source array and base address stay the same.
	 */

	/**
	 * determines the width, and number of characters for the address display with zero fill, it defaults to 4. the reset method will
	 * reset it to 4
	 * 
	 * @param addressWidth size of the address display
	 */
	public void setAddressWidth(int addressWidth);

	public void reset();

}// interface ByteArrayToMemFormat
