#!/usr/bin/env perl

use strict;
use warnings;

# in  : a code file
# out : an analysis of this code

# produced output : a tabulated table
# column 1 : # : line number of the source file
# column 2 : type of the column : comment / log (echo)  / code / internal function call / external function

# 
# blank : /^\s*$/
# comment : /^\s*#/
# log : /^\s*echo/

# column 3 : function : context | code
# column 4 : bloc : this is an id that define a logical group of the script
# column 5 : value

my $program = "hulk_prepactuel";
my $module = "hulk_actuelReplaceThema";

my $inputFileName = "$program/in/$module";
my $outputFileName = "$program/out/analysis_table.txt";

print "Lecture du fichier : $inputFileName\n";
open (my $inputFile, '<', $inputFileName) or die "Could not open file $inputFileName";
print "Ecriture du fichier : $outputFileName\n";
open (my $outputFile, '>', $outputFileName) or die "Could not open file $outputFileName";

# my %analyzedLine = {} ;
my $lineNumber = 1;
my $type = "";
my $function = "context";
my $bloc = "TBD";
my $line = "";

while ($line = <$inputFile>) {	
	$type = "code";
	
	if ($line =~ /^\s*$/) {
		$type = "blank";
	}	
	if ($line =~ /^\s*#/) {
		$type = "comment";
	} elsif ($line =~ /^\s*echo/) {
		$type = "log";
	}

	if ($lineNumber == 88) {
		$function = "code";
	}
	
	print $outputFile $lineNumber . "\t" . $type . "\t" . $function . "\t" . $bloc . "\t" . $line;	
	$lineNumber++;
}

close ($inputFile);
close ($outputFile);