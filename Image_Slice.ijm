// Image Slice
// December 2, 2011
// Lev Manovich and Matias Giachino / softwarestudies.com

// this version:
// 1) samples image slices from image sets and composites them; slices can be larger than 1px
// 2) user defines slice widths and heights or allows macro to calculate them from image set
// 3) if the animation option is toggled then all the frames are stored in a user-specified directory

// v.4.3 - added automatic size calculations (first image or full image set min/max size)
// v.4.2 - added input file options (data/folder) and extension checking (.jpg)
// v.4.1 - added GUI, option to slice either horizontally or vertically, and options for starting offsets from which to slice
// v.4 - added the option to use images which have diffreent width - by manually setting up max width
// v.3 - added the option to select a band of lines around the middle of the frame - as opposed to only using a single line


// if 1, opens gui to edit options in
use_gui = 1;

// if 0, takes files from a folder
// if 1, takes files from a folder and its subfolders
// if 1, takes files from a data file
// if 2, takes files from a data file as full filepaths
input_flag = 0;
input_list = newArray("Folder", "Folder and Subfolders", "Data File", "Data File as Filepaths");

// if 1, slices the images horizontally
slice_horz = 1;

// if 1, slices the images vertically
slice_vert = 1;

// if 0, uses the input value for width
// if 1, uses the width of the first image in the set
// if 2, finds the minimum width from the image set
// if 3, finds the maximum width from the image set
slice_horz_mode = 0;
slice_horz_mode_list = newArray("Set Width Manually","Use Width of First Image","Use Min Width of Image Set","Use Max Width of Image Set");

// if 0, uses the input value for height
// if 1, uses the height of the first image in the set
// if 2, finds the minimum height from the image set
// if 3, finds the maximum height from the image set
slice_vert_mode = 0;
slice_vert_mode_list = newArray("Set Height Manually","Use Height of First Image","Use Min Height of Image Set","Use Max Height of Image Set");

// for variable width image sequence, set max_width  to the max width in the sequence
var max_width = 690;

// for variable height image sequence, set Max_height  to the max height in the sequence
var max_height = 1000;

// select the height of a band of lines around the middle of the frame which would be copied
slice_width = 5;

// select the width of a band of lines around the middle of the frame which would be copied
slice_height = 5;

// x offset to start from
profile_x = 50;

// y offset to start from
profile_y = 50;

// if 1, overrides x offset as a percent
profile_x_percent = 1;

// if 1, calculates y offset as a percent
profile_y_percent = 1;

// if 1, creates 8-bit (grayscale) image
_8bit = 1;

// if 1, save each slice into a separate file for animation
save_files_flag = 0;

// the column from which to load the filename/filepath in a data file
input_data_column = 0;

// offset units list
px_percent_list = newArray("Pixels","Percent");

if(use_gui == 1){
	Dialog.create("Image Slice");
	Dialog.setInsets(0,0,0);
	Dialog.addMessage("Composite image slices.\nSource images may have different sizes.");
	Dialog.addMessage(" ");
	Dialog.setInsets(0,0,0);
	Dialog.addChoice("Image Source", input_list, input_list[input_flag]);
	Dialog.addMessage(" ");
	Dialog.setInsets(0,0,0);
	Dialog.addCheckbox("Slice Horizontally",slice_horz);
	Dialog.addChoice("Slice Mode",slice_horz_mode_list,slice_horz_mode_list[slice_horz_mode]);
	Dialog.setInsets(0,0,3);
	Dialog.addNumber("Max Width  ",max_width,0,5,"px");
	Dialog.addNumber("Set Height ",slice_height,0,5,"px");
	Dialog.addNumber("Y Offset      ",profile_y,0,5,"");
	Dialog.addChoice("Offset units",px_percent_list,px_percent_list[profile_y_percent]);
	Dialog.addMessage(" ");
	Dialog.setInsets(0,0,0);
	Dialog.addCheckbox("Slice Vertically",slice_vert);
	Dialog.addChoice("Slice Mode",slice_vert_mode_list,slice_vert_mode_list[slice_vert_mode]);
	Dialog.setInsets(0,0,3);
	Dialog.addNumber("Max Height",max_height,0,5,"px");
	Dialog.addNumber("Set Width   ",slice_width,0,5,"px");
	Dialog.addNumber("X Offset      ",profile_x,0,5,"");
	Dialog.addChoice("Offset units",px_percent_list,px_percent_list[profile_x_percent]);
	Dialog.addMessage(" ");
	Dialog.setInsets(0,0,0);
	Dialog.addCheckbox("Create Grayscale Image", _8bit);
	Dialog.addMessage(" ");
	Dialog.setInsets(0,0,0);
	Dialog.addCheckbox("Save Images for Animation", save_files_flag);
	Dialog.show();
	input_flag_choice = Dialog.getChoice();
	for(i=0; i<input_list.length; i++){
		if(input_list[i] == input_flag_choice){
			input_flag = i;
			i = 999;
		}
	}
	slice_horz = Dialog.getCheckbox()&1;
	slice_horz_mode_choice = Dialog.getChoice();
	for(i=0; i<slice_horz_mode_list.length; i++){
		if(slice_horz_mode_list[i] == slice_horz_mode_choice){
			slice_horz_mode = i;
			i = 999;
		}
	}
	max_width = abs(Dialog.getNumber());
	slice_height = abs(Dialog.getNumber());
	profile_y = abs(Dialog.getNumber());
	profile_y_percent = (Dialog.getChoice() == px_percent_list[1])&1;
	slice_vert = Dialog.getCheckbox()&1;
	slice_vert_mode_choice = Dialog.getChoice();
	for(i=0; i<slice_vert_mode_list.length; i++){
		if(slice_vert_mode_list[i] == slice_vert_mode_choice){
			slice_vert_mode = i;
			i = 999;
		}
	}
	max_height = abs(Dialog.getNumber());
	slice_width = abs(Dialog.getNumber());
	profile_x = abs(Dialog.getNumber());
	profile_x_percent = (Dialog.getChoice() == px_percent_list[1])&1;
	_8bit = Dialog.getCheckbox()&1;
	save_files_flag = Dialog.getCheckbox()&1;
}

// Quit if no slice direction selected
if(slice_horz != 1 && slice_vert != 1){
	return;
}

// Cap the percents
if(profile_x_percent && profile_x > 100){
	profile_x = 100;
}
if(profile_y_percent && profile_y > 100){
	profile_y = 100;
}

// Set defaults for max values if proper modes set
if(slice_horz_mode == 2){
	max_width = 9999999;
}else if(slice_horz_mode == 3){
	max_width = 0;
}
if(slice_vert_mode == 2){
	max_height = 9999999;
}else if(slice_vert_mode == 3){
	max_height = 0;
}

setBatchMode(true);

var count = 0;
var path = "";
if(input_flag != 3){
	dir = getDirectory("Choose source directory - images");
}
if(save_files_flag == 1){
	dir_anim = getDirectory("Directory to save files for animation"); 
}
if(slice_horz == 1 && slice_horz_mode > 1){
	print("Calculating horizontal slice width");
}
if(slice_vert == 1 && slice_vert_mode > 1){
	print("Calculating vertical slice height");
}
if(input_flag == 0 || input_flag == 1){
	list = getFileList(dir);
	countFiles(dir);
}else if(input_flag == 2 || input_flag == 3){
	input_file = File.openAsString("");
	list = split(input_file, "\n");
	labels=split(list[0],"\t");
	for(i=0;i<labels.length;i++){
		labels[i] = labels[i] + " (Column"+i+")";
	}
	if(use_gui == 1){
		Dialog.create("Data File");
		Dialog.setInsets(0,0,0);
		if(input_flag == 2){
			Dialog.addMessage  ("Choose the column that contains filenames:");
		}else if(input_flag == 3){
			Dialog.addMessage  ("Choose the column that contains filepaths:");
		}
		Dialog.addMessage(" ");
		Dialog.setInsets(0,0,0);
		if(input_flag == 2){
			Dialog.addChoice("Image Filenames",labels,labels[input_data_column]);
		}else if(input_flag == 3){
			Dialog.addChoice("Image Filepaths",labels,labels[input_data_column]);
		}
		Dialog.show();
		column_choice = Dialog.getChoice();
		for(i=0; i<labels.length; i++){
			if(labels[i] == column_choice){
				input_data_column = i;
				i = 999;
			}
		}
	}
	for (i=1; i<list.length; i++) {
		columns = split(list[i],"\t");
		list[i-1] = columns[input_data_column];
		if (endsWith(list[i-1], ".jpg")) {
			if((slice_horz == 1 && slice_horz_mode > 1) || (slice_vert == 1 && slice_vert_mode > 1)){
				if(input_flag == 2){
					open(dir+list[i]);
				}else if(input_flag == 3){
					open(list[i]);
				}
				calcMinMaxWidthHeight();
				close();
			}
			count++;
		}
	}
	if(input_flag == 2){
		path = dir+list[1];
	}else if(input_flag == 3){
		path = list[1];
	}
}

// Dimensions of first image if mode set
if((slice_horz == 1 && slice_horz_mode == 1) || (slice_vert == 1 && slice_vert_mode == 1)){
	open(path);
	if(slice_horz == 1 && slice_horz_mode == 1){
		max_width = getWidth;
	}
	if(slice_vert == 1 && slice_vert_mode == 1){
		max_height = getHeight;
	}
	close();
}

function calcMinMaxWidthHeight(){
	if(slice_horz == 1){
		if(slice_horz_mode == 2 && getWidth < max_width){
			max_width = getWidth;
		}else if(slice_horz_mode == 3 && getWidth > max_width){
			max_width = getWidth;
		}
	}
	if(slice_vert == 1){
		if(slice_vert_mode == 2 && getHeight < max_height){
			max_height = getHeight;
		}else if(slice_vert_mode == 3 && getHeight > max_height){
			max_height = getHeight;
		}
	}
}

// For input_flag 0 and 1
function countFiles(dir) {
	list = getFileList(dir);
	for (i=0; i<list.length; i++) {
		if (input_flag == 1 && endsWith(list[i], "/")){
			countFiles(""+dir+list[i]);
		}else if(endsWith(list[i], ".jpg")) {
			if(path == ""){
				path = dir+list[i];
			}
			if((slice_horz == 1 && slice_horz_mode > 1) || (slice_vert == 1 && slice_vert_mode > 1)){
				open(dir+list[i]);
				calcMinMaxWidthHeight();
				close();
			}
			count++;
		}
	}
}

// set the dimensions of the new image
if(slice_horz == 1){
	im_horz_width = max_width;
	im_horz_height = count * slice_height;

	print("Horizontal canvas_width = "+im_horz_width);
	print("Horizontal canvas_height = "+im_horz_height);
}
if(slice_vert == 1){
	im_vert_width = count * slice_height;
	im_vert_height = max_height;

	print("Vertical canvas_width = "+im_vert_width);
	print("Vertical canvas_height = "+im_vert_height);
}

setBatchMode(false);

if(slice_horz == 1){
	if(_8bit == 1){	
		newImage("8-bit horizontal slice", "8-bit Black", im_horz_width, im_horz_height, 1);
	}else{
		newImage("24-bit horizontal slice", "24-bit Black", im_horz_width, im_horz_height, 1);
	}
	horz_plot=getImageID;
}
if(slice_vert == 1){
	if(_8bit == 1){
		newImage("8-bit vertical slice", "8-bit Black", im_vert_width, im_vert_height, 1);
	}else{
		newImage("24-bit vertical slice", "24-bit Black", im_vert_width, im_vert_height, 1);
	}
	vert_plot=getImageID;
}

setBatchMode(true);

// Begin parsing files
var curImg = 0;
if( input_flag == 0 || input_flag == 2 || input_flag == 3){
	for(j=0; j<list.length; j++){
		if(endsWith(list[j],".jpg")){
			if(input_flag == 3){
				processFile(list[j],list[j]);
			}else{
				processFile(""+dir+list[j],list[j]);
			}
		}
	}
}else if(input_flag == 1){
	processRecursiveFiles(dir);
}

function processRecursiveFiles(dir){
	list = getFileList(dir);
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "/")){
			processRecursiveFiles(""+dir+list[i]);
		}else if (endsWith(list[i], ".jpg")) {
			processFile(""+dir+list[i], list[i]);
		}
	}
}

function processFile(path,listi){
	open(path);
	id=getImageID;

	im_width = getWidth;
	im_height = getHeight;
	if(slice_horz == 1){
		ic = curImg*slice_height;
		if(profile_y_percent == 1){
			profile_y_px = round((im_height-slice_height)*(profile_y/100));
		}else{
			profile_y_px = profile_y;
		}
		profile_loop = profile_y_px;
		// read pixel value from a image(id) and write it to "slice" image
		for (k=0; k < slice_height; k++) {
	     		for (i=0; i<im_horz_width; i++) {
				selectImage(id);
				pv = getPixel(i, profile_loop);
				// Correct for different bitDepths
				if(_8bit == 1 && bitDepth == 24){
					pv = floor(((pv >> 16) & 0xFF) * 0.11) + floor(((pv >> 8) & 0xFF) * 0.59) + floor((pv & 0xFF) * 0.3);
				}else if(_8bit != 1 && bitDepth == 8){
					pv = (pv << 16) | (pv << 8) | pv;
				}

		        		selectImage(horz_plot);
				setPixel(i, ic + k, pv);
			 }
			profile_loop = profile_loop + 1;
		}
		updateDisplay();
		if (save_files_flag == 1) {
			selectImage(horz_plot); // select canvas
			path_files = dir_anim + "frame_horz_" + curImg;
			saveAs("PNG", path_files);

			print("horz frame " + curImg + " saved");
		}
	}
	if(slice_vert == 1){
		selectImage(id);
		ic = curImg*slice_width;
		im_width = getWidth; // for variable width images
		im_height = getHeight;
			if(profile_x_percent == 1){
			profile_x_px = round((im_width-slice_width)*(profile_x/100));
		}else{
			profile_x_px = profile_x;
		}
		profile_loop = profile_x_px;
		// read pixel value from a image(id) and write it to "slice" image
		for (k=0; k < im_vert_height; k++) {
			profile_loop = profile_x;
	     		for (i=0; i<slice_width; i++) {
				selectImage(id);
				pv = getPixel(profile_loop, k);
				// Correct for different bitDepths
				if(_8bit == 1 && bitDepth == 24){
					pv = floor(((pv >> 16) & 0xFF) * 0.11) + floor(((pv >> 8) & 0xFF) * 0.59) + floor((pv & 0xFF) * 0.3);
				}else if(_8bit != 1 && bitDepth == 8){
					pv = (pv << 16) | (pv << 8) | pv;
				}

		        		selectImage(vert_plot);
				setPixel(ic + i, k, pv);
				profile_loop = profile_loop + 1;
			 }
		}
		updateDisplay();
		if (save_files_flag == 1) {
			selectImage(vert_plot); // select canvas
			path_files = dir_anim + "frame_vert_" + curImg;
			saveAs("PNG", path_files);

			print("vert frame " + curImg + " saved");
		}
	}

	selectImage(id);
	close();
	// print("completed line = "+curImg);
	curImg++;
	showProgress(curImg, count);
}

setBatchMode(false);