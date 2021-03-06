#!/usr/bin/perl


    
sub convertGBtoBytes {
    #function to convert from GB to bytes
    $sizeLimit =@_[0]; #in GB

    $constant = 1073741824; #1GB equals this
    $newSize = $sizeLimit * $constant;

    return $newSize;
}


sub runAraSim{

    my $resultPath = @_[0];
    my $araSimPath = @_[1]; # where araSim is installed
    my $date = @_[2];
    my $numberOfSection = @_[3];

    `tar -zcf archive.tar.gz -C $araSimPath .`;
    

    my $clusteID;
    ($clusterID) = SubmitCondorJobAraSim($numberOfSection, $resultPath, 0, 0);

    return $clusterID;

}
#

sub doMerge{
  #function to merge files by levels
    my $resultPath =@_[0];
    my $date =@_[1];
    my $sizeLimit= @_[2];
      

    my $level = 0; #initial level of merging
    my $countMerge = 0; #to keep count of the merging level   
    my $flag = 0; #flag to tell apart mergeOutput* and AraOut.setup.txt.run*

    sub convertGBtoBytes;
      
    my $fileList;
    my $totalFiles;
    
    printStartMerge();

    ($fileList, $totFiles) = getFileList(0, $resultPath);
    
    if (($totFiles % 2) != 0 ) {
        $totFiles = $totFiles - 1;
    } else {

	$totFiles = $totFiles;
    }



    my $mergeAgain;
my $flag;
# chech if file size is exceeded before merging
    ($mergeAgain) = checkFileSize($sizeLimit, $countMerge, $flag, $resultPath); 


#Merge files until this criteria is met
    while(($totFiles > 1) && ($mergeAgain > 0)){
	
	printMergeStep($countMerge);
	
	$flag =1;
	$totJob = $totFiles;
    #to make sure the number of jobs is even                                                                                            
	if($countMerge == 0){
	    $totJob = $totJob/2;
	}else {
	    if($totJob % 2 != 0){
		$totJob = $totJob - 1;
	    }
	    $totJob = $totJob/2;
	}
	($val) = start($countMerge, $resultPath);

	my $clusterID;
	($clusterID) = SubmitCondorJobMerge($totJob, $resultPath, $countMerge, 1);

	print "Cluster ID : $clusterID \t For merge # $countMerge \n";
	($numberOfRemovedJob) = GetReadyOrRemove($clusterID);

	$countMerge = $countMerge + 1;
	($fileList, $totFiles) = getFileList($countMerge, $resultPath);

	($mergeAgain) = checkFileSize($sizeLimit, ($countMerge - 1), $flag, $resultPath);

	
     }
    
    printMergeDone();
return $countMerge;
    
}


sub writeAraSimReport {
    #Write stats info collected during job run 
    $resultPath = @_[0];
    $numberOfJobs = @_[1];
    $dataSize =@_[2];
    $numberOfFiles =@_[3];
    $numberOfEvents =@_[4];
    $commandLine = @_[5];
    $timeStart = @_[6];
    $timeEnd = @_[7];
    $status = @_[8];

    $report = $resultPath . "/Logs/report.txt";
    $result = $resultPath . "/Results/";

    open(FILE, ">$report") or die "Cannot open $report";

    print (FILE "ARA offline processing system \n");
    print (FILE "BEGIN OF REPORT: \n \n \n");

    print (FILE "MODE: ARASIM \n");
    print (FILE "\t Status: $status \n \n");
    print (FILE "Processing summary: \n");
    print (FILE "\t Results path: \t $result \n");
    print (FILE "\t Total number of Root files: \t $numberOfFiles \n");
#    print (FILE "\t Total number of events generated: \t $numberOfEvents \n");
    print (FILE "\t Data size : $dataSize \n \n");


    print (FILE "Global stat/info: \n");
    print (FILE "\t Initial command line: $commandLine \n");
    print (FILE "\t processing start: $timeStart \n");
    print (FILE "\t processing end: $timeEnd \n \n \n");


    print (FILE "------------- END OF REPORT -------------------------- \n");
    

    close(FILE);

    return $report;

}


sub isEmptyDir {
    #this function checks if a given directory is empty or not
    # returns 1 if empty and 0 if not empty
    $resultPath = @_[0];

    $resultPath = "$resultPath/Temp/";
    
    ($fileList, $totFiles) = getFileList(0, $resultPath);

    if ($totFiles == 0){
	return 1;
    }else{
	return 0;
    }

}
      
sub organizeAraSimOutput {
    #clean the output path and get statistics of processing
    $resultPath = @_[0];
    $level =@_[1];

    my $fileName;
    my $fileTemplate;
   

    if ($level == -1) {	
	$fileTemplate = $resultPath . "/Temp/AraOut.*";
    }
    else {
	$fileTemplate = $resultPath . "/Temp/mergeOutput_" . $level . "*";
    }

    $destinationPath = $resultPath . "/Results/";
    
    `mv $fileTemplate $destinationPath`;
    
    ($nFiles) = renameFinalOutputFiles($resultPath, $level);

    $outputPath = $resultPath . "/Results/";
    $dirSize = `du -sh $resultPath | cut -f 1`;
    
    return ($nFiles, $dirSize);
}
      
    
sub renameFinalOutputFiles {
    $resultPath = @_[0];
    $level =@_[1];
    
     $prefix ="AraSimOut.run";
    $postfix =".root";

    $template = $resultPath . "/Results/*.root";
    my @fileList = glob $template;
    
    $counter = 0;

    foreach(@fileList) {
	next if -d;
	$fileName = $_;
	$newFileName = $prefix . $counter . $postfix;
	$newFileName = $resultPath ."/Results/" . $newFileName;
	rename $fileName, $newFileName;
	$counter = $counter + 1;
    }

    return $counter;
}


sub araSimDirExist {
    #checking if arasim exists and some important files
    $path =@_[0];

    $araSimBinary = $path . "/AraSim";
    $araSimSetupFile = $path . "/setup.txt";

    if(-d $path) {
	if(-e $araSimBinary) {
	    
	}else {
	    printAraSimFileNotFound($araSimBinary);
	    printNothingToDo();
	    exit(0);
	}

	if(-e $araSimSetupFile){
	    
	}else{
	    printAraSimFileNotFound($araSimSetupFile);
	    printNothingToDo();
	    exit(0);
	}
    }else {
	#arasim path does not exist
	printAraSimPathError($path);
	printNothingToDo();
	exit(0);
    }

    #everything is fine
    return 1;
}
