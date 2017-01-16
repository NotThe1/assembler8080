package assembler;

public class InstructionCounter {

	int currentSegment;
	String[] segmentNames = { "ASEG", "CSEG", "DSEG" };
	String[] allocationType = { NONE, null, null }; // ASEG,CSEG,DSEG
	int[] location = { 0, 0, 0 }; // ASEG,CSEG,DSEG
	int[] priorLocation = { 0, 0, 0 }; // ASEG,CSEG,DSEG - last value before change
	
	int lowestLocationSet = 0XFFFF;

	public InstructionCounter() {
		makeCurrent(ASEG, NONE);
	}// Constructor - InstuctionCounter()

	public void makeCurrent(int segment) {
		makeCurrent(segment, NONE); // Default setting
	}// makeCurrent(String segment)

	public void makeCurrent(int segment, String allocationType) {
		currentSegment = segment;
		if (currentSegment == ASEG) {
			return;
		}// ASEG
		if (this.allocationType[currentSegment] == null) { /* only set for the first declaration */
			this.allocationType[currentSegment] = allocationType;
		}// if - first declaration

		if (this.allocationType[currentSegment] == PAGE) { // adjust for PAGE
			location[currentSegment] = (location[currentSegment] + 100) & 0XFF00;
		}// if - Page start boundary
	}// makeCurrent(String segment)
	
	public void reset(){
		this.makeCurrent(ASEG,NONE);
		for (int i = 0; i < location.length;i++){
			location[i] = 0;
			priorLocation[i] = 0;
		}//for - clear each segment location
	}
	public void setCurrentLocation(int loc) {
		 location[currentSegment] = loc;
		 lowestLocationSet = Math.min(loc, lowestLocationSet);
//		 if (lowestLocationSet < 0XE800){
//			 int a = 9;
//		 }
	}// getCurrentLocation
	public void setPriorLocation(){
		priorLocation[currentSegment] = location[currentSegment];
	}//
	public int getCurrentLocation() {
		return location[currentSegment];
	}// getCurrentLocation
	public int getPriorLocation() {
		return priorLocation[currentSegment];
	}// getCurrentLocation
	public int getLowestLocationSet() {
		return lowestLocationSet;
	}// getLowestLocationSet

	
	public int getCurrentSegment() {
		return currentSegment;
	}// getCurrentSegment

	public void incrementCurrentLocation(int amount) {
		setPriorLocation();
		int currentLocation = location[currentSegment];
		if (allocationType[currentSegment] == INPAGE) {
			int currentPage = currentLocation & 0xFF00;
			int newPage = (currentLocation + amount) & 0XFF00;
			if (currentPage != newPage) {
				String errMessage = String.format(
						"error in segemnt %s at location %04X",
						segmentNames[currentSegment], currentLocation);
				System.err.println(errMessage);
			}// if error!
		}// if INPAGE
		lowestLocationSet = Math.min(location[currentSegment], lowestLocationSet);
		location[currentSegment] += amount;

	}// incrementCurrentLocation(amount)

	public void incrementCurrentLocation() {
		incrementCurrentLocation(1);
	}// incrementCurrentLocation()

	public static final int ASEG = 0;
	public static final int CSEG = 1;
	public static final int DSEG = 2;

	public static final String NONE = "NONE";
	public static final String PAGE = "PAGE";
	public static final String INPAGE = "INPAGE";

}// class InstuctionCounter

