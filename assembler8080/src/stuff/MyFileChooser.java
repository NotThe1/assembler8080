package stuff;

import javax.swing.JFileChooser;
import javax.swing.filechooser.FileNameExtensionFilter;

public class MyFileChooser {

	private MyFileChooser() {
		// TODO Auto-generated constructor stub
	}// Constructor
	
	public static JFileChooser getFilePicker(String directory, String filterDescription, String filterExtensions) {
		JFileChooser chooser = new JFileChooser(directory);
		chooser.setMultiSelectionEnabled(false);
		chooser.addChoosableFileFilter(new FileNameExtensionFilter(filterDescription, filterExtensions));
		chooser.setAcceptAllFileFilterUsed(false);
		return chooser;
	}//getFilePicker
}// MyFileChooser
