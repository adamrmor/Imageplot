// Image Montage v.2
// January 26, 2014
// Developed by Lev Manovich, Matias Giachino, and Jay Chow / softwarestudies.com

// this version:
// 1) user defines width and height of the montage
// 2) scales images vertically to the same size defined by the user - n_width (like in TiffViewer)
// 3) uses the full width of every image (after scaling), aligning them next to each other
// 4) error checking
// 5) 3 levels of label
// 6) color customization

// input; either a folder full of images or a data file containing rows of filenames or filepaths
// for the latter two options, the order of images in the file determines ther position in the montage (left to right, top to bottom)


// if 1, opens gui to edit options in
use_gui = 1;

// if 0, takes files from a folder
// if 1, takes files from a folder and its subfolders
// if 2, takes files from a data file
// if 3, takes files from a data file as full filepaths
input_flag = 3;
input_list = newArray("Folder", "Folder and Subfolders", "Data File", "Data File as Filepaths");

// if 0, make 8-bit grey scale montage
// if 1, make RGB montage
montage_RGB = 1;
montage_RGB_list = newArray("Grayscale","RGB");

// sets the width of the montage canvas
montage_width = 8000;

// sets the height of the montage canvas
montage_height = 8000;

// the height to resize each image to
height_row = 100;

// sets the horizontal space between the images - in pixels
h_interval = 10;

// sets the vertical space between the images - in pixels
v_interval = 10;

// if 1, saves each frame of the montage process into a user-specified directory
save_files_flag = 0;

// the column from which to load the filename/filepath in a data file
input_data_column = 0;

cat_list_flag = 1;
cat_list = newArray("None", "1 Level", "2 Level", "3 Level");

top_cat_data_column = 1;
sec_cat_data_column = 2;
third_cat_data_column = 3;

// Background color
var fill_bg_color = newArray(255,255,255);
var text_color = newArray(110,110,110); 

// Category Text Config
top_cat_text_size = 32;

call("java.lang.System.gc");

// Open the GUI if option is active
if(use_gui == 1){
	Dialog.create("Image Montage");
	Dialog.setInsets(0,0,0);
	Dialog.addMessage("Create a montage of images.\nImage sizes can vary.");
	Dialog.addMessage(" ");
	Dialog.setInsets(0,0,0);
	Dialog.addChoice("Image Source  ", input_list, input_list[input_flag]);
	Dialog.addMessage(" ");
	Dialog.setInsets(0,0,0);
	Dialog.addMessage("Canvas");
	Dialog.setInsets(0,0,0);
	Dialog.addChoice("Color Mode",montage_RGB_list,montage_RGB_list[montage_RGB]);
	Dialog.addNumber("Set Width   ",montage_width,0,5,"px");
	Dialog.addNumber("Set Height  ",montage_height,0,5,"px");
	Dialog.addMessage(" ");
	Dialog.setInsets(0,0,0);
	Dialog.addMessage("Images");
	Dialog.addNumber("Row Height",height_row,0,5,"px");
	Dialog.addNumber("X Spacing   ",h_interval,0,5,"px");
	Dialog.addNumber("Y Spacing   ",v_interval,0,5,"px");
	Dialog.addMessage(" ");
	Dialog.setInsets(0,0,0);
	Dialog.addChoice("Number of Labels", cat_list, cat_list[cat_list_flag]);
	Dialog.addMessage(" ");
	Dialog.setInsets(0,0,0);
	Dialog.addMessage("Labels");
	Dialog.addNumber("Set Text Size",top_cat_text_size,0,5,"pt");
	Dialog.addMessage(" ");
	Dialog.setInsets(0,0,0);
	Dialog.addMessage("Text Color");
	Dialog.addSlider   ("R", 0, 255, text_color[0]);
	Dialog.addSlider   ("G", 0, 255, text_color[1]);
	Dialog.addSlider   ("B", 0, 255, text_color[2]);
	Dialog.addMessage(" ");
	Dialog.setInsets(0,0,0);
	Dialog.addMessage("Background Color");
	Dialog.addSlider   ("R", 0, 255, fill_bg_color[0]);
	Dialog.addSlider   ("G", 0, 255, fill_bg_color[1]);
	Dialog.addSlider   ("B", 0, 255, fill_bg_color[2]);
	Dialog.addMessage(" ");
	Dialog.setInsets(0,0,0);
	Dialog.addMessage("Animation");
	Dialog.setInsets(0,20,0);
	Dialog.addCheckbox("Save Images for Animation", save_files_flag);


	Dialog.show();
	// Fetch choices
	input_flag_choice = Dialog.getChoice();
	for(i=0; i<input_list.length; i++){
		if(input_list[i] == input_flag_choice){
			input_flag = i;
			i = 999;
		}
	}
	montage_RGB_choice = Dialog.getChoice();
	for(i=0; i<montage_RGB_list.length; i++){
		if(montage_RGB_list[i] == montage_RGB_choice){
			montage_RGB = i;
			i = 999;
		}
	}
	cat_label_choice = Dialog.getChoice();
	for(i=0; i<cat_list.length;i++){
		if(cat_list[i] == cat_label_choice){
			cat_list_flag = i;
			i = 999;
		}
	}
	
		
	
	
	montage_width = Dialog.getNumber();
	montage_height = Dialog.getNumber();
	height_row = Dialog.getNumber();


	h_interval = Dialog.getNumber();
	v_interval = Dialog.getNumber();

	top_cat_text_size = Dialog.getNumber();

	
	//get text color
	text_color[0]   = Dialog.getNumber();
	text_color[1]   = Dialog.getNumber();
	text_color[2]   = Dialog.getNumber();

	//get background color
	fill_bg_color[0]   = Dialog.getNumber();
	fill_bg_color[1]   = Dialog.getNumber();
	fill_bg_color[2]   = Dialog.getNumber();
	
	save_files_flag = Dialog.getCheckbox() & 1;
}

setBatchMode(false);


scaled_height = height_row;
var count = 0;
var path = "";
var image_dir = "";
if(input_flag != 3){
	dir = getDirectory("Choose source directory - images");
	image_dir = dir;
	print(image_dir);
}
if(save_files_flag == 1){
	dir_anim = getDirectory("Directory to save files for animation"); 
}
if(input_flag == 0 || input_flag == 1){
	list = getFileList(dir);
	countFiles(dir);
}else if(input_flag == 2 || input_flag == 3){
	input_file = File.openAsString("");
	dir = getDirectory("current");
	list = split(input_file, "\n");
	top_cat_list=split(input_file, "\n");
	sec_cat_list=split(input_file, "\n");
	third_cat_list=split(input_file, "\n");
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
			if(cat_list_flag == 0){
				Dialog.addChoice("Image Filepaths",labels,labels[input_data_column]);
			}else if(cat_list_flag == 1){
				Dialog.addChoice("Image Filepaths",labels,labels[input_data_column]);
				Dialog.addChoice("Top Level Category Labels",labels,labels[top_cat_data_column]);
			}else if(cat_list_flag == 2){
				Dialog.addChoice("Image Filepaths",labels,labels[input_data_column]);
				Dialog.addChoice("Top Level Category Labels",labels,labels[top_cat_data_column]);
				Dialog.addChoice("Second Level Category Labels", labels, labels[sec_cat_data_column]);
			}else if(cat_list_flag == 3){
				Dialog.addChoice("Image Filepaths",labels,labels[input_data_column]);
				Dialog.addChoice("Top Level Category Labels",labels,labels[top_cat_data_column]);
				Dialog.addChoice("Second Level Category Labels", labels, labels[sec_cat_data_column]);
				Dialog.addChoice("Third Level Category Labels", labels, labels[third_cat_data_column]);
			}
		}else if(input_flag == 3){
			if(cat_list_flag == 0){
				Dialog.addChoice("Image Filepaths",labels,labels[input_data_column]);
			}else if(cat_list_flag == 1){
				Dialog.addChoice("Image Filepaths",labels,labels[input_data_column]);
				Dialog.addChoice("Top Level Category Labels",labels,labels[top_cat_data_column]);
			}else if(cat_list_flag == 2){
				Dialog.addChoice("Image Filepaths",labels,labels[input_data_column]);
				Dialog.addChoice("Top Level Category Labels",labels,labels[top_cat_data_column]);
				Dialog.addChoice("Second Level Category Labels", labels, labels[sec_cat_data_column]);
			}else if(cat_list_flag == 3){
				Dialog.addChoice("Image Filepaths",labels,labels[input_data_column]);
				Dialog.addChoice("Top Level Category Labels",labels,labels[top_cat_data_column]);
				Dialog.addChoice("Second Level Category Labels", labels, labels[sec_cat_data_column]);
				Dialog.addChoice("Third Level Category Labels", labels, labels[third_cat_data_column]);
			}
		}
		Dialog.show();
		print("cat_list_flag: " + cat_list_flag);
		
		if(cat_list_flag == 0){
			
			column_choice = Dialog.getChoice();
			
			for(i=0; i<labels.length; i++){
				
				if(labels[i] == column_choice){
					input_data_column = i;
				}
												
				i = 999;
			}
			
			print("column_choice: " + column_choice);
			
			for (i=1; i<list.length; i++) {
				list[i]=replace(list[i],'"','');
				columns = split(list[i],"\t");
				list[i-1] = columns[input_data_column];
				if (endsWith(list[i-1], ".jpg") || endsWith(list[i-1],".png")) {
					count++;
				}
			}
			
			
			
		}else if(cat_list_flag == 1){
			column_choice = Dialog.getChoice();
			top_cat_choice = Dialog.getChoice();

			
			print(column_choice);
			print(top_cat_choice);

			
			for(i=0; i<labels.length; i++){
				
				
				if(labels[i] == column_choice){
					input_data_column = i;
				}
		
				if(labels[i] == top_cat_choice){
					top_cat_data_column = i;
				}
				
									
				
			}
			
			print("column_choice: " + column_choice);
			print("input_column: " + input_data_column);
			print("top_cat_choice: " + top_cat_choice);
			print("top_cat_data_column: " + top_cat_data_column);

			for (i=1; i<list.length; i++) {
				list[i]=replace(list[i],'"','');
				columns = split(list[i],"\t");
				list[i-1] = columns[input_data_column];
				top_cat_list[i-1] = columns[top_cat_data_column];
				
				if (endsWith(list[i-1], ".jpg") || endsWith(list[i-1],".png")) {
					count++;
				}
			}
			
		}else if(cat_list_flag == 2){
			column_choice = Dialog.getChoice();
			top_cat_choice = Dialog.getChoice();
			sec_cat_choice = Dialog.getChoice();
			
			for(i=0; i<labels.length; i++){
				
				if(labels[i] == column_choice){
					input_data_column = i;
				}
				
				if(labels[i] == top_cat_choice){
					top_cat_data_column = i;
				}
				
				if(labels[i] == sec_cat_choice){
					sec_cat_data_column = i;
				}
					
				
			}
			print("column_choice: " + column_choice);
			print("top_cat_choice: " + top_cat_choice);
			print("sec_cat_choice: " + sec_cat_choice);

			for (i=1; i<list.length; i++) {
				list[i]=replace(list[i],'"','');
				columns = split(list[i],"\t");
				list[i-1] = columns[input_data_column];
				top_cat_list[i-1] = columns[top_cat_data_column];
				sec_cat_list[i-1] = columns[sec_cat_data_column];
				if (endsWith(list[i-1], ".jpg") || endsWith(list[i-1],".png")) {
					count++;
				}
			}
						
		}else if(cat_list_flag == 3){
			column_choice = Dialog.getChoice();
			top_cat_choice = Dialog.getChoice();
			sec_cat_choice = Dialog.getChoice();
			third_cat_choice = Dialog.getChoice();
						
			for(i=0; i<labels.length; i++){
				
				if(labels[i] == column_choice){
					input_data_column = i;
				}
				
				if(labels[i] == top_cat_choice){
					top_cat_data_column = i;
				}
				
				if(labels[i] == sec_cat_choice){
					sec_cat_data_column = i;
				}
				
				if(labels[i] == third_cat_choice){
					third_cat_data_column=i;
				}
	
				
			}
			
			print("column_choice: " + column_choice);
			print("top_cat_choice: " + top_cat_choice);
			print("sec_cat_choice: " + sec_cat_choice);
			print("third_cat_choice: " + third_cat_choice);
			
			for (i=1; i<list.length; i++) {
				list[i]=replace(list[i],'"','');
				columns = split(list[i],"\t");
				list[i-1] = columns[input_data_column];
				top_cat_list[i-1] = columns[top_cat_data_column];
				sec_cat_list[i-1] = columns[sec_cat_data_column];
				third_cat_list[i-1] = columns[third_cat_data_column];
				if (endsWith(list[i-1], ".jpg") || endsWith(list[i-1],".png")) {
					count++;
				}
			}
		}
	}


	if(input_flag == 2){
		path = image_dir+list[1];
	}else if(input_flag == 3){
		path = list[1];
	}
}

// For input_flag 0 and 1
function countFiles(dir) {
	list = getFileList(dir);
	for (i=0; i<list.length; i++) {
		if (input_flag == 1 && endsWith(list[i], "/")){
			countFiles(""+dir+list[i]);
		}else if(endsWith(list[i], ".jpg") || endsWith(list[i],".png")) {
			count++;
		}
	}
}


print("Montage width = " +  montage_width);
print("Montage height = " + montage_height);
print("Number of images = " + count);

if (montage_RGB == 1){
	newImage("montage", "RGB white", montage_width, montage_height, 1);
	setColor(fill_bg_color[0], fill_bg_color[1], fill_bg_color[2]);
	fill();
}else{
	newImage("montage", "8-bit white", montage_width, montage_height, 1);
}

id_plot=getImageID;


var img_width = 0;
var img_height =  0;
var start_x = 0;
var start_y = 0;
var row = 0;
var total_x_width = 0;
var n_width=0;
var curImg = 0;

setBatchMode(true);

var temptopcat="";
var tempseccat="";
var tempthirdcat="";


// Begin parsing files
if( input_flag == 0 || input_flag == 2 || input_flag == 3){
	for(j=0; j<list.length; j++){
		if(endsWith(list[j],".jpg") || endsWith(list[j],".png")){
			if(input_flag == 3){

				if(j<1){
					if(cat_list_flag == 0){
						if(File.exists(list[j])){
							processFile(list[j],list[j]);
						}else{
							print(list[j] + " File not found.");
						}
					}
					else if(cat_list_flag == 1){
						if(File.exists(list[j])){
							processFile1(list[j],list[j], top_cat_list[j],top_cat_list[j]);
							
						}else{
				
							print(list[j] + " File not found.");
						}
						temptopcat = top_cat_list[j];
						
					}
					else if(cat_list_flag == 2){
						if(File.exists(list[j])){
							processFile2(list[j],list[j], top_cat_list[j],top_cat_list[j], sec_cat_list[j],sec_cat_list[j]);							
						}else{
							print(list[j] + " File not found.");
						}
						
						temptopcat = top_cat_list[j];
						tempseccat = sec_cat_list[j];

					}
					else if(cat_list_flag == 3){
						if(File.exists(list[j])){
							processFile3(list[j],list[j], top_cat_list[j],top_cat_list[j], sec_cat_list[j],sec_cat_list[j],third_cat_list[j],third_cat_list[j]);
						}else{
							print(dir+list[j] + " File not found.");
						}
													
						temptopcat = top_cat_list[j];
						tempseccat = sec_cat_list[j];
						tempthirdcat = third_cat_list[j];
					}	
				}else{
					if(cat_list_flag == 0){
						if(File.exists(list[j])){
							processFile(list[j],list[j]);
						}
					}
					else if(cat_list_flag == 1){
						if(File.exists(list[j])){
							processFile1(list[j],list[j], top_cat_list[j],temptopcat);
						}else{
							
							print(list[j] + " File not found.");
						}
						
						temptopcat = top_cat_list[j];

					}
					else if(cat_list_flag == 2){
						if(File.exists(list[j])){
							processFile2(list[j],list[j], top_cat_list[j],temptopcat,sec_cat_list[j],tempseccat);
						}else{
							print(list[j] + " File not found.");
						}
						
						temptopcat = top_cat_list[j];
						tempseccat = sec_cat_list[j];

					}
					else if(cat_list_flag == 3){
						if(File.exists(list[j])){
							processFile3(list[j],list[j], top_cat_list[j],temptopcat,sec_cat_list[j],tempseccat,third_cat_list[j],tempthirdcat);
						}else{
							print(list[j] + " File not found.");
						}
						
						temptopcat = top_cat_list[j];
						tempseccat = sec_cat_list[j];
						tempthirdcat = third_cat_list[j];
					}
				}
			}
			else if(input_flag == 2){
				dir = image_dir;

				if(j<1){
					if(cat_list_flag == 0){
						if(File.exists(dir+list[j])){
							processFile(dir+list[j],dir+list[j]);
						}else{
							print(dir+list[j] + " File not found.");
						}
					}
					else if(cat_list_flag == 1){
						if(File.exists(dir+list[j])){

							path = dir+list[j];

							processFile1(path, path, top_cat_list[j],top_cat_list[j]);
						
						}else{
							print(dir+list[j] + " File not found.");
						}
						temptopcat = top_cat_list[j];
					
					}
					else if(cat_list_flag == 2){
					
						path = dir+list[j];
						
						if(File.exists(path)){
							processFile2(path,path, top_cat_list[j],top_cat_list[j], sec_cat_list[j],sec_cat_list[j]);							
						}else{
							print(path + " File not found.");
						}
					
						temptopcat = top_cat_list[j];
						tempseccat = sec_cat_list[j];

					}
					else if(cat_list_flag == 3){
						
						path = dir+list[j];
							
						if(File.exists(path)){
							processFile3(path,path, top_cat_list[j],top_cat_list[j], sec_cat_list[j],sec_cat_list[j],third_cat_list[j],third_cat_list[j]);
						}else{
							print(path + " File not found.");
						}
												
						temptopcat = top_cat_list[j];
						tempseccat = sec_cat_list[j];
						tempthirdcat = third_cat_list[j];
					}

				} else{
					if(cat_list_flag == 0){
					
						if(File.exists(dir+list[j])){
							processFile(dir+list[j],dir+list[j]);
						}
					}
					else if(cat_list_flag == 1){
						if(File.exists(dir+list[j])){
						
							path = dir+list[j];

							processFile1(path, path, top_cat_list[j],top_cat_list[j]);
						}else{
							print(dir+list[j] + " File not found.");
						}
					
						temptopcat = top_cat_list[j];

					}
					else if(cat_list_flag == 2){
						path = dir+list[j];
						
						if(File.exists(path)){
							processFile2(path,path, top_cat_list[j],temptopcat,sec_cat_list[j],tempseccat);
						}else{
							print(path + " File not found.");
						}
					
						temptopcat = top_cat_list[j];
						tempseccat = sec_cat_list[j];

					}
					else if(cat_list_flag == 3){


						path = dir+list[j];
						
						if(File.exists(path)){
							processFile3(path,path, top_cat_list[j],temptopcat,sec_cat_list[j],tempseccat,third_cat_list[j],tempthirdcat);
						}else{
							print(path + " File not found.");
						}
					
						temptopcat = top_cat_list[j];
						tempseccat = sec_cat_list[j];
						tempthirdcat = third_cat_list[j];
					}
				}
			}
			else{
				processFile(""+image_dir+list[j],list[j]);
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

var processcount=0;

function processFile(path,listi){
	
	// Check for row overflow, start new row if needed
	if ((total_x_width + n_width) > montage_width) {
		// increment row
		row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
	}

	open(path);
	id=getImageID;

	img_width = getWidth;
	img_height = getHeight;
	n_width = round((img_width * scaled_height)/img_height);

	run("Size...", "width=" + n_width + " height=" + scaled_height + " average interpolation=Bicubic");

	// get image width and height after it was scaled
	n_width = getWidth;
	n_height = getHeight;

	start_x = total_x_width;
	start_y = row * (height_row + v_interval) + v_interval;

	run("Select All");
	run("Copy");
	selectImage(id_plot);
	makeRectangle(start_x, start_y, n_width, n_height);
	run("Paste");
	selectImage(id);
	close();

	// update display
	updateDisplay();

	total_x_width = total_x_width + n_width + h_interval;

	if (save_files_flag == 1) {
		selectImage(id_plot);
		path_files = dir_anim + "frame_" + curImg;
		saveAs("PNG", path_files);

		print("image " + curImg + " saved");
	}
	
	curImg++;
	showProgress(curImg, count);
}

function processFile1(path,listi,currtopcat, oldtopcat){
	
	setColor(text_color[0], text_color[1], text_color[2]);
	
	//calculate text offset
	top_cat_text_offset = height_row*1.05;

	
	if(processcount<1){
		
		//draw First category Top Level Label
		
		// increment row
		//row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
		
		setFont("Helvetica", top_cat_text_size, "bold, antiliased");
		start_text_x = start_x;
		start_text_y = row * (height_row + v_interval) + v_interval + top_cat_text_offset;
		drawString(currtopcat+" ", start_text_x, start_text_y);
		topcatwidth = getStringWidth(currtopcat+" ");
		
		row = row + 1;
								
		processcount++;
	}
	
	if(currtopcat != oldtopcat){
		// increment row
		row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
		
		setFont("Helvetica", top_cat_text_size, "bold, antiliased");
		start_text_x = start_x;
		start_text_y = row * (height_row + v_interval) + v_interval + top_cat_text_offset;
		drawString(currtopcat+" ", start_text_x, start_text_y);
		topcatwidth = getStringWidth(currtopcat+" ");
		
		row = row + 1;		
	}

	
	// Check for row overflow, start new row if needed
	if ((total_x_width + n_width) > montage_width) {
		// increment row
		row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
	}
	
	print(path);
	open(path);
	id=getImageID;

	img_width = getWidth;
	img_height = getHeight;
	n_width = round((img_width * scaled_height)/img_height);

	run("Size...", "width=" + n_width + " height=" + scaled_height + " average interpolation=Bicubic");

	// get image width and height after it was scaled
	n_width = getWidth;
	n_height = getHeight;

	start_x = total_x_width;
	start_y = row * (height_row + v_interval) + v_interval;

	run("Select All");
	run("Copy");
	selectImage(id_plot);
	makeRectangle(start_x, start_y, n_width, n_height);
	run("Paste");
	selectImage(id);
	close();

	// update display
	updateDisplay();

	total_x_width = total_x_width + n_width + h_interval;

	if (save_files_flag == 1) {
		selectImage(id_plot);
		path_files = dir_anim + "frame_" + curImg;
		saveAs("PNG", path_files);

		print("image " + curImg + " saved");
	}
	
	curImg++;
	showProgress(curImg, count);
}

function processFile2(path,listi,currtopcat, oldtopcat, currseccat, oldseccat){

	setColor(text_color[0], text_color[1], text_color[2]);

	//calculate text size
	sec_cat_text_size = top_cat_text_size*0.5;
	
	//calculate text offset
	top_cat_text_offset = height_row *1.2;
	sec_cat_text_offset = height_row;
		
	if(processcount<1){
		
		//draw First category Top Level Label
		
		// increment row
		//row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
		
		setFont("Helvetica", top_cat_text_size, "bold, antiliased");
		start_text_x = start_x;
		start_text_y = row * (height_row + v_interval) + v_interval + top_cat_text_offset;
		drawString(currtopcat, start_text_x, start_text_y);
		
		row = row + 1;
				
		//draw First category Second Level Label
		
		// increment row
		//row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
		if(currseccat == " "){
			row = row - 1;
		}
		
		setFont("Helvetica", sec_cat_text_size, "bold, antiliased");
		start_text_x = start_x;
		start_text_y = row * (height_row + v_interval) + v_interval + sec_cat_text_offset;
		drawString(currseccat, start_text_x, start_text_y);
		
		row = row + 1;
				
		processcount++;
	}
	
	if(currtopcat != oldtopcat){
		// increment row
		row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
		
		setFont("Helvetica", top_cat_text_size, "bold, antiliased");
		start_text_x = start_x;
		start_text_y = row * (height_row + v_interval) + v_interval + top_cat_text_offset;
		drawString(currtopcat, start_text_x, start_text_y);	
	}

	if(currseccat != oldseccat || currtopcat != oldtopcat){
		if(currseccat == " "){
			row = row - 1;
		}
		// increment row
		row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
		
		setFont("Helvetica", sec_cat_text_size, "bold, antiliased");
		start_text_x = start_x;
		start_text_y = row * (height_row + v_interval) + v_interval + sec_cat_text_offset;
		drawString(currseccat, start_text_x, start_text_y);
		
		row = row + 1;		
	}
	
	
	// Check for row overflow, start new row if needed
	if ((total_x_width + n_width) > montage_width) {
		// increment row
		row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
	}

	open(path);
	id=getImageID;

	img_width = getWidth;
	img_height = getHeight;
	n_width = round((img_width * scaled_height)/img_height);

	run("Size...", "width=" + n_width + " height=" + scaled_height + " average interpolation=Bicubic");

	// get image width and height after it was scaled
	n_width = getWidth;
	n_height = getHeight;

	start_x = total_x_width;
	start_y = row * (height_row + v_interval) + v_interval;

	run("Select All");
	run("Copy");
	selectImage(id_plot);
	makeRectangle(start_x, start_y, n_width, n_height);
	run("Paste");
	selectImage(id);
	close();

	// update display
	updateDisplay();

	total_x_width = total_x_width + n_width + h_interval;

	if (save_files_flag == 1) {
		selectImage(id_plot);
		path_files = dir_anim + "frame_" + curImg;
		saveAs("PNG", path_files);

		print("image " + curImg + " saved");
	}
	
	curImg++;
	showProgress(curImg, count);
}

function processFile3(path,listi,currtopcat, oldtopcat, currseccat, oldseccat, currthirdcat, oldthirdcat){

	setColor(text_color[0], text_color[1], text_color[2]);

	//calculate text size
	sec_cat_text_size = top_cat_text_size*0.75;
	third_cat_text_size = top_cat_text_size*0.50;
	
	//calculate text offset
	top_cat_text_offset = height_row*1.3;
	sec_cat_text_offset = height_row*1.4;
	third_cat_text_offset = height_row;

	//draw First category Top Level Label
	if(currseccat == " "){
		top_cat_text_offset = height_row;
	}
	if(currthirdcat == " "){
		sec_cat_text_offset = height_row*1.05;
	}
		
	if(processcount<1){
		

		
		// increment row
		//row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
		
		setFont("Helvetica", top_cat_text_size, "bold, antiliased");
		start_text_x = start_x;
		start_text_y = row * (height_row + v_interval) + v_interval + top_cat_text_offset;
		drawString(currtopcat, start_text_x, start_text_y);
		
		row = row + 1;
				
		//draw First category Second Level Label
		
		// increment row
		//row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
					



		setFont("Helvetica", sec_cat_text_size, "bold, antiliased");
		start_text_x = start_x;
		start_text_y = row * (height_row + v_interval) + v_interval + sec_cat_text_offset - getValue("font.height");
		
		if(currseccat == " "){
			row = row - 1;
		}

		drawString(currseccat, start_text_x, start_text_y);
		
		//draw First category Third Level Label

		// increment row
		row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
		
		setFont("Helvetica", third_cat_text_size, "bold, antiliased");
		start_text_x = start_x;
		start_text_y = row * (height_row + v_interval) + v_interval + third_cat_text_offset;
		drawString(currthirdcat, start_text_x, start_text_y);
		if(currthirdcat == " "){
			row = row - 1;
		}
		row= row + 1;
		
		processcount++;
	}
	

	if(currtopcat != oldtopcat){
		// increment row
		row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
		
		setFont("Helvetica", top_cat_text_size, "bold, antiliased");
		start_text_x = start_x;
		start_text_y = row * (height_row + v_interval) + v_interval + top_cat_text_offset;
		drawString(currtopcat, start_text_x, start_text_y);	
	}

	if(currseccat != oldseccat || currtopcat != oldtopcat){
		
		if(currseccat == " "){
			row = row - 1;
		}
		// increment row
		row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
		
		setFont("Helvetica", sec_cat_text_size, "bold, antiliased");
		start_text_x = start_x;
		start_text_y = row * (height_row + v_interval) + v_interval + sec_cat_text_offset;
		drawString(currseccat, start_text_x, start_text_y);	
	}
	
	if(currthirdcat != oldthirdcat || currseccat != oldseccat || currtopcat != oldtopcat){
		if(currthirdcat == " "){
			row = row - 1;
		}
		// increment row
		row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
		
		setFont("Helvetica", third_cat_text_size, "bold, antiliased");
		start_text_x = start_x;
		start_text_y = row * (height_row + v_interval) + v_interval + third_cat_text_offset;
		drawString(currthirdcat, start_text_x, start_text_y);
		
		row = row + 1;
			
	}
	
	
	
	// Check for row overflow, start new row if needed
	if ((total_x_width + n_width) > montage_width) {
		// increment row
		row = row + 1;
		// reset column
		start_x =  0;
		// reset total row width
		total_x_width = 0;
	}

	open(path);
	id=getImageID;

	img_width = getWidth;
	img_height = getHeight;
	n_width = round((img_width * scaled_height)/img_height);

	run("Size...", "width=" + n_width + " height=" + scaled_height + " average interpolation=Bicubic");

	// get image width and height after it was scaled
	n_width = getWidth;
	n_height = getHeight;

	start_x = total_x_width;
	start_y = row * (height_row + v_interval) + v_interval;

	run("Select All");
	run("Copy");
	selectImage(id_plot);
	makeRectangle(start_x, start_y, n_width, n_height);
	run("Paste");
	selectImage(id);
	close();

	// update display
	updateDisplay();

	total_x_width = total_x_width + n_width + h_interval;

	if (save_files_flag == 1) {
		selectImage(id_plot);
		path_files = dir_anim + "frame_" + curImg;
		saveAs("PNG", path_files);

		print("image " + curImg + " saved");
	}
	
	curImg++;
	showProgress(curImg, count);
}

run("Select None");
setBatchMode(false);
