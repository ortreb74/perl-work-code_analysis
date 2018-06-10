#!/usr/bin/env perl

use strict;
use warnings;

# egrep "^\w+:" bin/hulkliv

my $inputFileName = "in/hulkliv";

my $defaultOutputFileName = "out/aside";
my $commentsOutputFileName = "out/comments";
my $loaderOutputFileName = "out/loader";

open (my $inputFile, '<', $inputFileName) or die "Could not open file $inputFileName";
open (my $outputAsideFile, '>', $defaultOutputFileName) or die "Could not open file $defaultOutputFileName";
open (my $outputCommentsFile, '>', $commentsOutputFileName) or die "Could not open file $defaultOutputFileName";
open (my $outputLoaderFile, '>', $loaderOutputFileName) or die "Could not open file $loaderOutputFileName";

my $outputFile = $outputLoaderFile;

# il y a un premier bloc, jusqu'au premier mot clef "set"
# puis il y a un deuxième bloc jusqu'au premier arg et qui se termine à end 

my $step = 1;
my @words;

while (my $line = <$inputFile>) {	
	if ($line =~ /^\s*#/) {
		print $outputCommentsFile $line;
		next;
	} 
	
	@words = split (" ", $line);
	
	if ($step == 1 && grep( /^set$/, @words)) {		
		$step = 2;
		$outputFile = $outputAsideFile;
	}
	
	if ($step == 2 && grep( /^\$arg$/, @words)) {
		$step ++;
		$outputFile = $outputAsideFile;
	}	
	
	if ($step == 3 && $line =~  /^end$/) {
		$step ++;
		$outputFile = $outputAsideFile;
	}	
	
	print $outputFile $line;	
}

close ($inputFile);
close ($outputFile);
close ($outputCommentsFile);
close ($outputAsideFile);
close ($outputLoaderFile);